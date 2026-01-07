import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/mux_service.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

/// Go Live Screen
/// Allows user to start live streaming from their camera
class GoLiveScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String matchTitle;
  final bool isDraft; // If true, match hasn't been created yet
  
  const GoLiveScreen({
    super.key,
    required this.matchId,
    required this.matchTitle,
    this.isDraft = false,
  });

  @override
  ConsumerState<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends ConsumerState<GoLiveScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isStreaming = false;
  bool _isLoading = false;
  String _userPlan = 'loading';
  String? _errorMessage;
  String? _muxStreamId;
  String? _rtmpUrl;
  String? _hlsPlaybackUrl;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _fetchUserPlan();
  }

  Future<void> _fetchUserPlan() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        final profile = await ref.read(profileRepositoryProvider).getProfileById(userId);
        if (mounted) {
          setState(() {
            _userPlan = profile?.subscriptionPlan ?? 'basic';
          });
        }
      } else {
         setState(() {
            _userPlan = 'basic';
          });
      }
    } catch (e) {
      print('Error fetching plan: $e');
      if (mounted) {
        setState(() {
          _userPlan = 'basic'; // Default
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        setState(() {
          _errorMessage = 'Camera permission is required to go live';
        });
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
        });
        return;
      }

      // Initialize camera (use back camera by default)
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing camera: $e';
      });
    }
  }

  Future<void> _startStreaming() async {
    if (!_isInitialized || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not initialized')),
      );
      return;
    }

    // Check Plan Logic
    bool shouldRecord = false;
    
    // Refresh plan just in case
    await _fetchUserPlan();

    if (_userPlan != 'pro') {
         // Show Upgrade Dialog for Basic users
         final continueBasic = await _showUpgradeDialog();
         
         // If continueBasic is null, user cancelled (tapped outside or back)
         if (continueBasic == null) return;
         
         // If continueBasic is false, user chose "Upgrade to Pro"
         if (!continueBasic) {
           if (mounted) {
             final upgraded = await context.push<bool>('/subscription');
             if (upgraded == true) {
                await _fetchUserPlan(); // Refresh after upgrade
                await ref.read(authStateProvider.notifier).refreshAuth(); // Refresh global user state
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are now Pro! Tap Go Live again.')),
                  );
                }
             }
           }
           return;
         }
         
         // User chose "Continue as Basic" - Disable recording
         shouldRecord = false;
      } else {
        // Pro User - Enable recording
        shouldRecord = true;
      }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get YouTube stream key from backend (secure) - optional
      String? youtubeStreamKey;
      try {
        youtubeStreamKey = await _getYouTubeStreamKey();
      } catch (e) {
        print('YouTube stream key not available (function not deployed): $e');
        // Continue without YouTube restreaming
      }
      
      // Create Mux live stream
      final muxResponse = await MuxService.createLiveStream(
        matchId: widget.matchId,
        matchTitle: widget.matchTitle,
        youtubeStreamKey: youtubeStreamKey,
        shouldRecord: shouldRecord,
      );

      setState(() {
        _muxStreamId = muxResponse.id;
        _rtmpUrl = muxResponse.rtmpUrl;
        _hlsPlaybackUrl = muxResponse.hlsPlaybackUrl;
      });

      // Save stream info to database
      await _saveStreamInfo(muxResponse);

      // Start RTMP streaming (using flutter_rtmp_publisher)
      // Note: This is a placeholder - actual RTMP streaming implementation
      // would use the flutter_rtmp_publisher package
      if (_rtmpUrl != null) {
        // TODO: Implement actual RTMP streaming using flutter_rtmp_publisher
        // For now, we'll simulate it
        await _startRTMPStream(_rtmpUrl!);
      }

      // Signal Mux that stream is active
      await MuxService.signalStreamActive(muxResponse.id);

      setState(() {
        _isStreaming = true;
        _isLoading = false;
      });

      // Start periodic status check
      _startStatusCheck();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live stream started! Broadcasting to YouTube...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error starting stream: $e';
      
      // Handle specific Mux errors
      if (e.toString().contains('unavailable on the free plan')) {
        errorMessage = 'System Config Error: The DEVELOPER Mux account is on a free tier which does not support live streaming. This is not related to your App Subscription.';
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage = 'Mux authentication failed. Please check your Mux credentials in mux_config.dart';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Invalid Mux request. Please check your Mux account settings.';
      }
      
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _stopStreaming() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Stop RTMP stream
      // TODO: Stop actual RTMP streaming
      
      // Delete Mux live stream
      if (_muxStreamId != null) {
        await MuxService.deleteLiveStream(_muxStreamId!);
      }

      // Update database
      await _updateStreamStatus('ended');

      _statusCheckTimer?.cancel();

      setState(() {
        _isStreaming = false;
        _isLoading = false;
        _muxStreamId = null;
        _rtmpUrl = null;
        _hlsPlaybackUrl = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live stream ended'),
            backgroundColor: Colors.orange,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error stopping stream: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _getYouTubeStreamKey() async {
    // Call backend API to get YouTube stream key securely
    // This should be a Supabase Edge Function or your backend API
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'get-youtube-stream-key',
        body: {'match_id': widget.matchId},
      );
      
      if (response.status == 200 && response.data != null) {
        return response.data['stream_key'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting YouTube stream key: $e');
      // Continue without YouTube restreaming if key is not available
      return null;
    }
  }

  Future<void> _saveStreamInfo(MuxLiveStreamResponse muxResponse) async {
    try {
      await SupabaseConfig.client.from('match_live_streams').upsert({
        'match_id': widget.matchId,
        'mux_stream_id': muxResponse.id,
        'rtmp_url': muxResponse.rtmpUrl,
        'hls_playback_url': muxResponse.hlsPlaybackUrl,
        'status': 'active',
        'started_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving stream info: $e');
    }
  }

  Future<void> _updateStreamStatus(String status) async {
    try {
      await SupabaseConfig.client
          .from('match_live_streams')
          .update({'status': status, 'ended_at': DateTime.now().toIso8601String()})
          .eq('match_id', widget.matchId);
    } catch (e) {
      print('Error updating stream status: $e');
    }
  }

  Future<void> _startRTMPStream(String rtmpUrl) async {
    // TODO: Implement actual RTMP streaming via platform channels
    // RTMP streaming requires native implementation:
    // - Android: Use MediaRecorder or ExoPlayer with RTMP library
    // - iOS: Use AVFoundation with RTMP library
    // 
    // For now, this is a placeholder. The Mux stream is created and ready,
    // but actual camera-to-RTMP streaming needs native code implementation.
    // 
    // You can use libraries like:
    // - Android: https://github.com/pedroSG94/rtmp-rtsp-stream-client-java
    // - iOS: https://github.com/pedroSG94/rtmp-rtsp-stream-client-ios
    // 
    // Then create Flutter platform channels to bridge to native code.
    
    // For now, just simulate stream creation
    await Future.delayed(const Duration(seconds: 2));
    
    // Note: In production, you would:
    // 1. Initialize native RTMP streamer
    // 2. Connect camera feed to RTMP encoder
    // 3. Start streaming to rtmpUrl
    // 4. Handle errors and reconnection
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_muxStreamId != null) {
        try {
          final stream = await MuxService.getLiveStream(_muxStreamId!);
          if (stream.status == 'disconnected' && _isStreaming) {
            // Stream disconnected, stop streaming
            _stopStreaming();
          }
        } catch (e) {
          print('Error checking stream status: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
             const Text('Go Live'),
             const SizedBox(width: 12),
             if (_userPlan != 'loading')
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                 decoration: BoxDecoration(
                   color: _userPlan == 'pro' ? AppColors.primary : Colors.grey,
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text(
                   _userPlan.toUpperCase(),
                   style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                 ),
               ),
          ],
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Debug: Reset Plan Button
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.orange),
            tooltip: 'Debug: Reset to Basic Plan',
            onPressed: () async {
              final userId = SupabaseConfig.client.auth.currentUser?.id;
              if (userId != null) {
                await ref.read(profileRepositoryProvider).updateSubscriptionPlan(userId, 'basic');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debug: Reset to Basic Plan')),
                  );
                }
                await _fetchUserPlan();
              }
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_isStreaming) {
              _showStopStreamDialog();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _errorMessage!.contains('free plan') 
                          ? Icons.info_outline 
                          : Icons.error_outline,
                      size: 64,
                      color: _errorMessage!.contains('free plan') 
                          ? Colors.orange 
                          : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!.contains('free plan')
                          ? 'Mux Plan Upgrade Required'
                          : 'Error',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage!.contains('free plan')) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          // Open Mux upgrade page
                          // You can use url_launcher here if needed
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Upgrade Mux Plan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                        if (!_errorMessage!.contains('free plan')) {
                          _initializeCamera();
                        }
                      },
                      child: Text(_errorMessage!.contains('free plan') 
                          ? 'Go Back' 
                          : 'Retry'),
                    ),
                  ],
                ),
              ),
            )
          : !_isInitialized
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _errorMessage != null && _errorMessage!.contains('free plan')
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 64,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Mux Plan Upgrade Required',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                // Open Mux upgrade page
                                // You can use url_launcher to open browser
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Upgrade Mux Plan'),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _errorMessage = null;
                                });
                              },
                              child: const Text(
                                'Dismiss',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                  children: [
                    // Camera Preview
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _cameraController != null
                          ? CameraPreview(_cameraController!)
                          : const Center(
                              child: Text(
                                'Camera not available',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                    ),
                    
                    // Overlay Controls
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Streaming Status
                            if (_isStreaming)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fiber_manual_record, size: 12, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            
                            // Start/Stop Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : (_isStreaming ? _stopStreaming : _startStreaming),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isStreaming ? Colors.red : AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        _isStreaming ? 'STOP STREAMING' : 'GO LIVE',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<bool?> _showUpgradeDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Upgrade to Pro?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pro Plan Features:',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('Run Live Stream Recording (VOD)'),
            _buildFeatureItem('Scorecard Overlays'),
            _buildFeatureItem('PDF/CSV Export'),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            const Text(
              'Basic Plan: Live Only (No Recording)',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Continue as Basic
            child: const Text('Continue as Basic', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false), // Upgrade
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _showStopStreamDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Streaming?'),
        content: const Text('Are you sure you want to stop the live stream?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _stopStreaming();
            },
            child: const Text('Stop', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

