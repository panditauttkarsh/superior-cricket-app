import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Widget to navigate to Live Screen
/// Can be used anywhere in the app to open live streaming
class LiveStreamButton extends StatelessWidget {
  final String? channelHandle;
  final String? videoId;
  final Widget? child;
  final String? label;
  
  const LiveStreamButton({
    super.key,
    this.channelHandle,
    this.videoId,
    this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final uri = Uri(
          path: '/live',
          queryParameters: {
            if (channelHandle != null) 'channel': channelHandle!,
            if (videoId != null) 'videoId': videoId!,
          },
        );
        context.push(uri.toString());
      },
      child: child ?? 
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC72B32), Color(0xFF8B1A1F)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.live_tv, color: Colors.white, size: 20),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
    );
  }
}

