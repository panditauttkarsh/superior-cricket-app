import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

/// Watch Live Screen
/// Displays live stream for viewers
class WatchLiveScreen extends ConsumerStatefulWidget {
  final String matchId;
  
  const WatchLiveScreen({
    super.key,
    required this.matchId,
  });

  @override
  ConsumerState<WatchLiveScreen> createState() => _WatchLiveScreenState();
}

class _WatchLiveScreenState extends ConsumerState<WatchLiveScreen> {
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  String? _errorMessage;
  String? _hlsUrl;
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _loadLiveStream();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadLiveStream() async {
    try {
      // Fetch live stream info from database
      final response = await SupabaseConfig.client
          .from('match_live_streams')
          .select()
          .eq('match_id', widget.matchId)
          .eq('status', 'active')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        setState(() {
          _errorMessage = 'No live stream available for this match';
          _isLoading = false;
        });
        return;
      }

      final hlsUrl = response['hls_playback_url'] as String?;
      if (hlsUrl == null || hlsUrl.isEmpty) {
        setState(() {
          _errorMessage = 'Live stream URL not available';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _hlsUrl = hlsUrl;
        _isLive = true;
      });

      // Initialize video player with HLS URL
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(hlsUrl),
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
        ),
      );

      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading live stream: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Live Stream'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadLiveStream,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _videoController != null && _videoController!.value.isInitialized
                  ? Stack(
                      children: [
                        // Video Player
                        Center(
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                        
                        // Live Badge
                        if (_isLive)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
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
                          ),
                        
                        // Play/Pause Controls
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _videoController!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_videoController!.value.isPlaying) {
                                        _videoController!.pause();
                                      } else {
                                        _videoController!.play();
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Text(
                        'Video not available',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
    );
  }
}

