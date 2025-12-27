import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../domain/models/user_model.dart' as app_models;

class AuthRepository {
  final _supabase = SupabaseConfig.client;

  Future<app_models.AuthSession> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: User not found');
      }

      if (response.session == null) {
        throw Exception('Login failed: No session created. Please check your email for verification.');
      }

      // Get or create user profile
      final profile = await _getOrCreateProfile(response.user!);

      final roleString = profile['role'] as String? ?? 'player';
      final role = app_models.UserRole.values.firstWhere(
        (r) => r.toString().split('.').last == roleString,
        orElse: () => app_models.UserRole.player,
      );

      return app_models.AuthSession(
        token: response.session!.accessToken,
        refreshToken: response.session!.refreshToken ?? '',
        user: app_models.User(
          id: response.user!.id,
          email: response.user!.email ?? email,
          name: profile['name'] as String? ?? email.split('@')[0],
          role: role,
          avatar: profile['profile_image_url'] as String?,
          phone: profile['phone'] as String?,
          createdAt: DateTime.parse(profile['created_at'] as String),
          updatedAt: DateTime.parse(profile['updated_at'] as String),
        ),
        expiresAt: response.session!.expiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (response.session!.expiresAt as num).toInt() * 1000)
            : DateTime.now().add(const Duration(days: 7)),
      );
    } on AuthException catch (e) {
      // Supabase auth-specific errors
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      // Other errors
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<app_models.AuthSession> loginWithGoogle(String token) async {
    // Note: Google OAuth requires full OAuth flow implementation
    // This is a placeholder - implement based on your OAuth setup in Supabase
    throw UnimplementedError(
      'Google OAuth requires full OAuth flow. '
      'Set up Google OAuth in Supabase dashboard and implement the redirect flow.'
    );
  }

  Future<app_models.AuthSession> register(String email, String password, String name) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
        emailRedirectTo: SupabaseConfig.redirectUrl,
      );

      if (response.user == null) {
        throw Exception('Registration failed: User not created');
      }

      // Get or create user profile (this handles both new and existing profiles)
      final profile = await _getOrCreateProfile(response.user!);

      // Check if we have a session (email confirmation disabled)
      if (response.session == null) {
        // No session means email confirmation is required
        // But since it's disabled, this shouldn't happen
        // However, we'll still return a session-like object for the user
        throw Exception('Registration successful but email verification required. Please check your email.');
      }

      final roleString = profile['role'] as String? ?? 'player';
      final role = app_models.UserRole.values.firstWhere(
        (r) => r.toString().split('.').last == roleString,
        orElse: () => app_models.UserRole.player,
      );

      return app_models.AuthSession(
        token: response.session!.accessToken,
        refreshToken: response.session!.refreshToken ?? '',
        user: app_models.User(
          id: response.user!.id,
          email: email,
          name: profile['name'] as String? ?? name,
          role: role,
          avatar: profile['profile_image_url'] as String?,
          phone: profile['phone'] as String?,
          createdAt: DateTime.parse(profile['created_at'] as String),
          updatedAt: DateTime.parse(profile['updated_at'] as String),
        ),
        expiresAt: response.session!.expiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (response.session!.expiresAt as num).toInt() * 1000)
            : DateTime.now().add(const Duration(days: 7)),
      );
    } on AuthException catch (e) {
      // Supabase auth-specific errors
      throw Exception('Registration failed: ${e.message}');
    } catch (e) {
      // Other errors - provide more detail
      final errorMsg = e.toString();
      if (errorMsg.contains('duplicate key') || errorMsg.contains('already exists')) {
        throw Exception('An account with this email already exists. Please login instead.');
      } else if (errorMsg.contains('profiles')) {
        throw Exception('Registration successful but profile creation failed. Please try logging in.');
      }
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<app_models.User> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final profile = await _getOrCreateProfile(user);

      final roleString = profile['role'] as String? ?? 'player';
      final role = app_models.UserRole.values.firstWhere(
        (r) => r.toString().split('.').last == roleString,
        orElse: () => app_models.UserRole.player,
      );

      return app_models.User(
        id: user.id,
        email: user.email ?? '',
        name: profile['name'] as String? ?? user.email?.split('@')[0] ?? 'User',
        role: role,
        avatar: profile['profile_image_url'] as String?,
        phone: profile['phone'] as String?,
        createdAt: DateTime.parse(profile['created_at'] as String),
        updatedAt: DateTime.parse(profile['updated_at'] as String),
      );
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _getOrCreateProfile(User supabaseUser) async {
    try {
      // Try to get existing profile
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', supabaseUser.id)
          .maybeSingle();

      if (response != null) {
        return response as Map<String, dynamic>;
      }

      // Profile doesn't exist, create it
      final profileData = {
        'id': supabaseUser.id,
        'email': supabaseUser.email,
        'name': supabaseUser.userMetadata?['name'] ?? 
                supabaseUser.email?.split('@')[0] ?? 
                'User',
        'role': 'player',
      };

      await _supabase.from('profiles').insert(profileData);

      // Fetch the newly created profile
      final newResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', supabaseUser.id)
          .single();

      return newResponse as Map<String, dynamic>;
    } catch (e) {
      // If profile creation fails, try to return a minimal profile
      // This allows login to proceed even if profile creation has issues
      print('Warning: Profile creation/retrieval failed: $e');
      return {
        'id': supabaseUser.id,
        'email': supabaseUser.email,
        'name': supabaseUser.userMetadata?['name'] ?? 
                supabaseUser.email?.split('@')[0] ?? 
                'User',
        'role': 'player',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}

