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
    
    // Listen for auth state changes (including email verification via deep link)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      debugPrint('Auth state changed: $event');
      if (event == AuthChangeEvent.signedIn && session != null) {
        debugPrint('User signed in - email may have been verified');
      } else if (event == AuthChangeEvent.userUpdated) {
        debugPrint('User updated - email verification may have completed');
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
      child: CricPlayApp(),
    ),
  );
}

class CricPlayApp extends ConsumerWidget {
  const CricPlayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'CricPlay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

