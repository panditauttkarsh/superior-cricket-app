import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://nhiyuosjiiabxxwpkpdi.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oaXl1b3NqaWlhYnh4d3BrcGRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYyNDcwNzQsImV4cCI6MjA4MTgyMzA3NH0.UmvfnWn27EPJkes8e30H6Wqa16I_Oh231X1lXU4r0SU';
  static const String deepLinkScheme = 'cricplay';
  static const String deepLinkHost = 'login-callback';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Set to false in production
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  
  static String get redirectUrl => '$deepLinkScheme://$deepLinkHost';
}

