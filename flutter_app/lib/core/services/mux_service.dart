import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/mux_config.dart';

/// Mux Service
/// Handles live stream creation, management, and YouTube restreaming
class MuxService {
  /// Create a new live stream for a match
  /// Returns the RTMP ingest URL and HLS playback URL
  static Future<MuxLiveStreamResponse> createLiveStream({
    required String matchId,
    required String matchTitle,
    String? youtubeStreamKey, // Optional: if provided, will restream to YouTube
    bool shouldRecord = true, // Control recording/VOD creation
  }) async {
    try {
      final url = Uri.parse('${MuxConfig.apiBaseUrl}/video/v1/live-streams');
      
      final Map<String, dynamic> body = {
        'playback_policy': ['public'], // Public playback
        'reduced_latency': true, // Enable low latency
        'test': false,
      };

      // Add recording settings only if shouldRecord is true
      if (shouldRecord) {
        body['new_asset_settings'] = {
          'playback_policy': ['public'],
        };
      }
      
      // If YouTube stream key is provided, add simulcast target
      if (youtubeStreamKey != null && youtubeStreamKey.isNotEmpty) {
        body['simulcast_targets'] = [
          {
            'url': 'rtmp://a.rtmp.youtube.com/live2',
            'stream_key': youtubeStreamKey,
            'passthrough': 'youtube-restream',
          }
        ];
      }
      
      final response = await http.post(
        url,
        headers: MuxConfig.getApiHeaders(),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body)['data'];
        return MuxLiveStreamResponse.fromJson(data);
      } else {
        throw Exception('Failed to create live stream: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating Mux live stream: $e');
    }
  }
  
  /// Get live stream status
  static Future<MuxLiveStreamResponse> getLiveStream(String streamId) async {
    try {
      final url = Uri.parse('${MuxConfig.apiBaseUrl}/video/v1/live-streams/$streamId');
      
      final response = await http.get(
        url,
        headers: MuxConfig.getApiHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return MuxLiveStreamResponse.fromJson(data);
      } else {
        throw Exception('Failed to get live stream: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting Mux live stream: $e');
    }
  }
  
  /// Delete a live stream
  static Future<void> deleteLiveStream(String streamId) async {
    try {
      final url = Uri.parse('${MuxConfig.apiBaseUrl}/video/v1/live-streams/$streamId');
      
      final response = await http.delete(
        url,
        headers: MuxConfig.getApiHeaders(),
      );
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete live stream: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting Mux live stream: $e');
    }
  }
  
  /// Signal that streaming has started (stream is active)
  static Future<void> signalStreamActive(String streamId) async {
    try {
      final url = Uri.parse('${MuxConfig.apiBaseUrl}/video/v1/live-streams/$streamId/signal');
      
      final response = await http.post(
        url,
        headers: MuxConfig.getApiHeaders(),
        body: jsonEncode({'action': 'stream_started'}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to signal stream active: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error signaling stream active: $e');
    }
  }
}

/// Mux Live Stream Response Model
class MuxLiveStreamResponse {
  final String id;
  final String status; // active, idle, disconnected
  final String? streamKey;
  final String? rtmpUrl; // RTMP ingest URL
  final String? playbackId; // For HLS playback
  final String? hlsPlaybackUrl; // HLS playback URL
  final List<Map<String, dynamic>>? simulcastTargets;
  
  MuxLiveStreamResponse({
    required this.id,
    required this.status,
    this.streamKey,
    this.rtmpUrl,
    this.playbackId,
    this.hlsPlaybackUrl,
    this.simulcastTargets,
  });
  
  factory MuxLiveStreamResponse.fromJson(Map<String, dynamic> json) {
    // Extract RTMP URL from stream_key (format: rtmp://rtmp.live.mux.com/app/{stream_key})
    String? rtmpUrl;
    String? streamKey = json['stream_key'] as String?;
    if (streamKey != null) {
      rtmpUrl = 'rtmp://rtmp.live.mux.com/app/$streamKey';
    }
    
    // Extract playback ID and construct HLS URL
    String? playbackId = json['playback_ids'] != null && (json['playback_ids'] as List).isNotEmpty
        ? (json['playback_ids'] as List)[0]['id'] as String?
        : null;
    
    String? hlsPlaybackUrl;
    if (playbackId != null) {
      hlsPlaybackUrl = 'https://stream.mux.com/$playbackId.m3u8';
    }
    
    return MuxLiveStreamResponse(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'idle',
      streamKey: streamKey,
      rtmpUrl: rtmpUrl,
      playbackId: playbackId,
      hlsPlaybackUrl: hlsPlaybackUrl,
      simulcastTargets: json['simulcast_targets'] != null
          ? List<Map<String, dynamic>>.from(json['simulcast_targets'] as List)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'stream_key': streamKey,
      'rtmp_url': rtmpUrl,
      'playback_id': playbackId,
      'hls_playback_url': hlsPlaybackUrl,
    };
  }
}

