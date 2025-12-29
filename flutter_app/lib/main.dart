import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:firebase_core/firebase_core.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart' as auth_provider;
import 'core/providers/auth_provider.dart';
import 'core/widgets/loading_screen.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (if using)
  // await Firebase.initializeApp();
  
  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
    
    // Listen for auth state changes (including OAuth callbacks)
    // Note: We can't access providers here, so we'll handle this in the app widget
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      debugPrint('Auth state changed: $event');
      if (event == AuthChangeEvent.signedIn && session != null) {
        debugPrint('User signed in - OAuth or email verification completed');
        debugPrint('Session user ID: ${session.user.id}');
        debugPrint('Session user email: ${session.user.email}');
        // The auth provider will pick up the session on next check
        // We don't need to manually update it here as the provider checks Supabase directly
      } else if (event == AuthChangeEvent.userUpdated) {
        debugPrint('User updated - email verification may have completed');
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('User signed out');
      }
    });
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
    debugPrint('Please configure your Supabase URL and anon key in lib/core/config/supabase_config.dart');
  }
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  auth_provider.setGlobalPrefs(prefs);
  
  runApp(
    const ProviderScope(
      child: PitchPointApp(),
    ),
  );
}

class PitchPointApp extends ConsumerStatefulWidget {
  const PitchPointApp({super.key});

  @override
  ConsumerState<PitchPointApp> createState() => _PitchPointAppState();
}

class _PitchPointAppState extends ConsumerState<PitchPointApp> {
  @override
  void initState() {
    super.initState();
    // Listen for auth state changes and refresh provider
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        // Refresh auth state provider when user signs in
        // This ensures the provider picks up the new session
        Future.microtask(() {
          ref.read(authStateProvider.notifier).refreshAuth();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'PITCH POINT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

