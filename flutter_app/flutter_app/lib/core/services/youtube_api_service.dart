import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/youtube_config.dart';

/// YouTube Data API v3 Service
/// Used to check if a channel is currently live streaming
class YouTubeApiService {
  static const String _baseUrl = YouTubeConfig.apiBaseUrl;

  /// Get the channel ID from a channel handle (e.g., @PITCH-POINT)
  /// Returns channel ID or null if not found
  static Future<String?> getChannelIdFromHandle(String handle) async {
    try {
      // Remove @ if present
      final cleanHandle = handle.replaceFirst('@', '');
      
      final url = Uri.parse(
        '$_baseUrl/search?part=snippet&q=$cleanHandle&type=channel&key=${YouTubeConfig.apiKey}&maxResults=1'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final channelId = data['items'][0]['snippet']['channelId'] as String;
          print('✅ Found channel ID: $channelId for handle: $handle');
          return channelId;
        } else {
          print('⚠️ No channel found for handle: $handle');
        }
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('❌ Error getting channel ID: $e');
      return null;
    }
  }

  /// Check if a channel is currently live streaming
  /// Returns the live video ID if live, null otherwise
  /// Uses exact API format: GET /search?part=id&channelId=CHANNEL_ID&eventType=live&type=video&key=API_KEY
  static Future<String?> getActiveLiveVideoId(String channelId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/search?part=id&channelId=$channelId&eventType=live&type=video&key=${YouTubeConfig.apiKey}&maxResults=1'
      );
      
      print('🔍 Checking for live stream on channel: $channelId');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          // Extract items[0].id.videoId as LIVE_VIDEO_ID
          final videoId = data['items'][0]['id']['videoId'] as String;
          print('✅ Found live stream! Video ID: $videoId');
          return videoId;
        } else {
          print('⚠️ No live stream found for channel: $channelId');
        }
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e) {
      print('❌ Error checking live status: $e');
      return null;
    }
  }

  /// Get live video ID directly from channel handle
  /// This is a convenience method that combines getChannelIdFromHandle and getActiveLiveVideoId
  static Future<String?> getLiveVideoIdFromChannelHandle(String handle) async {
    final channelId = await getChannelIdFromHandle(handle);
    if (channelId == null) return null;
    return await getActiveLiveVideoId(channelId);
  }

  /// Get live video ID from channel ID
  /// Use this if you already have the channel ID
  static Future<String?> getLiveVideoIdFromChannelId(String channelId) async {
    return await getActiveLiveVideoId(channelId);
  }
}

