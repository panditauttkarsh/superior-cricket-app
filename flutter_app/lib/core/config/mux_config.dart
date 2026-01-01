import 'dart:convert';
import 'dart:typed_data';

/// Mux Configuration
/// Store your Mux credentials securely
class MuxConfig {
  // Get these from Mux Dashboard: https://dashboard.mux.com/settings/access-tokens
  static const String accessTokenId = '2e65ecdd-4b29-4662-acb7-1583ec4cb6d7';
  static const String secretKey = 'ElEnu3SsniFqgH5l+Snbe9pqCCO0/tOqe3asgYwmXGu6LX53la4EPUOsQZ1cLNDAVr+N+kevpyS';
  
  // Mux API Base URL
  static const String apiBaseUrl = 'https://api.mux.com';
  
  // YouTube Stream Key (stored securely on backend, never exposed to app)
  // This will be retrieved from backend API
  static const String youtubeStreamKeyEndpoint = '/api/mux/youtube-stream-key';
  
  /// Get Mux API headers for authentication
  static Map<String, String> getApiHeaders() {
    return {
      'Authorization': 'Basic ${_getBasicAuth()}',
      'Content-Type': 'application/json',
    };
  }
  
  /// Generate Basic Auth string for Mux API
  static String _getBasicAuth() {
    final credentials = '$accessTokenId:$secretKey';
    final bytes = utf8.encode(credentials);
    return base64Encode(bytes);
  }
}

