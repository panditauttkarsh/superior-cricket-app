import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../../../core/services/youtube_api_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:io';

class LiveScreen extends ConsumerStatefulWidget {
  final String? channelHandle; // e.g., '@PITCH-POINT' or channel ID
  final String? videoId; // Optional: if video ID is already known
  
  const LiveScreen({
    super.key,
    this.channelHandle,
    this.videoId,
  });

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _isLive = false;
  String? _liveVideoId;
  String? _errorMessage;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _checkLiveStatus();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      ..setBackgroundColor(Colors.black);
    
    // Configure Android WebView for media playback
    if (Platform.isAndroid) {
      (_controller.platform as AndroidWebViewController)
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setOnShowFileSelector((params) async {
          // Handle file selection if needed
          return [];
        });
    }
    
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          setState(() {
            _isLoading = true;
          });
        },
        onPageFinished: (String url) {
          setState(() {
            _isLoading = false;
          });
          // Inject JavaScript to ensure autoplay works
          _controller.runJavaScript('''
            (function() {
              var iframe = document.querySelector('iframe');
              if (iframe && iframe.src) {
                if (!iframe.src.includes('autoplay=1')) {
                  var separator = iframe.src.includes('?') ? '&' : '?';
                  iframe.src = iframe.src + separator + 'autoplay=1';
                }
              }
            })();
          ''');
        },
        onNavigationRequest: (NavigationRequest request) {
          // STRICT navigation blocking - prevent ALL external navigation
          final url = request.url.toLowerCase();
          
          // ONLY allow YouTube embed URLs (exact match)
          final isEmbedUrl = url.contains('youtube.com/embed/') ||
                            url.contains('youtube-nocookie.com/embed/');
          
          if (isEmbedUrl) {
            return NavigationDecision.navigate;
          }
          
          // BLOCK everything else:
          // - youtube.com/watch (regular YouTube pages)
          // - youtu.be (short URLs)
          // - intent:// (Android intents)
          // - Any external app schemes
          // - Any other URLs
          return NavigationDecision.prevent;
        },
        onWebResourceError: (WebResourceError error) {
          print('❌ WebView Error: ${error.errorCode} - ${error.description}');
          setState(() {
            // Provide more helpful error messages based on error codes
            if (error.errorCode == 152 || error.description.contains('152')) {
              _errorMessage = 'Video unavailable (Error 152). The video may be private, deleted, or embedding may be disabled. Try a different video ID.';
            } else if (error.errorCode == 153 || error.description.contains('153')) {
              _errorMessage = 'Video player configuration error (Error 153). Please try again.';
            } else {
              _errorMessage = 'Failed to load video: ${error.description}';
            }
            _isLoading = false;
          });
        },
      ),
    );
    
    _webViewController = _controller;
  }

  Future<void> _checkLiveStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? videoId;

      // If video ID is provided directly, use it
      if (widget.videoId != null && widget.videoId!.isNotEmpty) {
        videoId = widget.videoId;
      }
      // Otherwise, check channel for live stream
      else if (widget.channelHandle != null && widget.channelHandle!.isNotEmpty) {
        videoId = await YouTubeApiService.getLiveVideoIdFromChannelHandle(
          widget.channelHandle!,
        );
      }
      // Default to PITCH POINT channel if nothing provided
      else {
        videoId = await YouTubeApiService.getLiveVideoIdFromChannelHandle(
          '@PITCH-POINT',
        );
      }

      if (videoId != null && videoId.isNotEmpty) {
        setState(() {
          _liveVideoId = videoId;
          _isLive = true;
        });
        _loadLiveStream(videoId);
      } else {
        setState(() {
          _isLive = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking live status: $e';
        _isLive = false;
        _isLoading = false;
      });
    }
  }

  void _loadLiveStream(String videoId) {
    // Clean the video ID (remove any extra characters)
    final cleanVideoId = videoId.trim();
    
    // Construct embed URL with essential parameters
    // Using simpler parameters to avoid restrictions
    const origin = 'https://www.youtube.com';
    final embedUrl = '$origin/embed/$cleanVideoId?'
        'autoplay=1&'
        'playsinline=1&'
        'rel=0&'
        'modestbranding=1&'
        'enablejsapi=1';
    
    print('📺 Loading YouTube embed URL: $embedUrl');
    print('📺 Video ID: $cleanVideoId');
    
    // Load HTML with iframe instead of direct URL for better compatibility
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Security-Policy" content="frame-src https://www.youtube.com https://www.youtube-nocookie.com;">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        html, body {
            width: 100%;
            height: 100%;
            background-color: #000;
            overflow: hidden;
        }
        .video-container {
            position: relative;
            width: 100%;
            height: 100%;
        }
        iframe {
            width: 100%;
            height: 100%;
            border: none;
            display: block;
        }
    </style>
</head>
<body>
    <div class="video-container">
        <iframe
            id="youtube-player"
            src="$embedUrl"
            frameborder="0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
            allowfullscreen>
        </iframe>
    </div>
    <script>
        // Handle iframe load errors
        window.addEventListener('error', function(e) {
            console.error('Page error:', e);
        });
        
        // Log iframe load events
        document.getElementById('youtube-player').addEventListener('load', function() {
            console.log('YouTube iframe loaded');
        });
    </script>
</body>
</html>
''';
    
    _webViewController?.loadHtmlString(htmlContent, baseUrl: origin);
  }

  void _retry() {
    _checkLiveStatus();
  }

  void _showTestVideoIdDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Test with Video ID',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a YouTube video ID to test the player.\n\nYou can find the video ID in the URL:\nyoutube.com/watch?v=VIDEO_ID_HERE',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Video ID',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final videoId = textController.text.trim();
              if (videoId.isNotEmpty) {
                Navigator.pop(context);
                setState(() {
                  _liveVideoId = videoId;
                  _isLive = true;
                  _isLoading = true;
                });
                _loadLiveStream(videoId);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Load Video'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Live Stream',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _retry,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && !_isLive) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Checking for live stream...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isLive || _liveVideoId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.tv_off,
                color: Colors.grey,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Live Not Started',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The live stream has not started yet.\nPlease check back later.',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Show which channel/video was checked
              if (widget.channelHandle != null || widget.videoId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    widget.videoId != null
                        ? 'Checking video ID: ${widget.videoId}'
                        : 'Checking channel: ${widget.channelHandle ?? "@PITCH-POINT"}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Check Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Test mode: Allow entering a video ID manually
              TextButton(
                onPressed: () => _showTestVideoIdDialog(),
                child: const Text(
                  'Test with Video ID',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Live stream is active - show WebView
    return Stack(
      children: [
        // WebView with YouTube IFrame Player
        SizedBox.expand(
          child: WebViewWidget(controller: _controller),
        ),
        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Loading live stream...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        // Live indicator badge
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
                Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

