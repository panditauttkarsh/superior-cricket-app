import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

// Global SharedPreferences instance - initialized in main.dart
SharedPreferences? _globalPrefs;

void setGlobalPrefs(SharedPreferences prefs) {
  _globalPrefs = prefs;
}

SharedPreferences getGlobalPrefs() {
  if (_globalPrefs == null) {
    throw Exception('SharedPreferences not initialized. Call setGlobalPrefs() first.');
  }
  return _globalPrefs!;
}

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final SharedPreferences _prefs;

  AuthNotifier(this._authRepository, this._prefs) : super(AuthState(isLoading: true)) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Add timeout to prevent infinite loading
      final user = await _authRepository.getCurrentUser()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Auth check timeout');
            },
          );
      // If we get here, user is authenticated
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
    } catch (e) {
      // No valid session - user is not logged in
      // This is expected if user hasn't logged in yet
      // Clear any stored tokens (they might be stale)
      try {
        await _prefs.remove('auth_token');
        await _prefs.remove('auth_refresh_token');
        await _prefs.remove('auth_user');
      } catch (_) {
        // Ignore pref errors
      }
      // Always set loading to false, even on error
      state = state.copyWith(
        isAuthenticated: false,
        user: null,
        isLoading: false,
      );
    }
  }

  // Public method to refresh auth state (called when OAuth completes)
  Future<void> refreshAuth() async {
    await _checkAuth();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authRepository.login(email, password);
      
      // Store tokens
      await _prefs.setString('auth_token', result.token);
      await _prefs.setString('auth_refresh_token', result.refreshToken);
      
      // Update state immediately
      state = state.copyWith(
        isAuthenticated: true,
        user: result.user,
        isLoading: false,
        error: null,
      );
      
      // Small delay to ensure state propagates
      await Future.delayed(const Duration(milliseconds: 100));
      
      return true;
    } catch (e) {
      // Extract error message
      String errorMessage = 'Login failed';
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Invalid email or password. Please check your credentials.';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Please verify your email address before logging in.';
      } else if (e.toString().contains('User not found')) {
        errorMessage = 'No account found with this email. Please sign up first.';
      } else {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        isAuthenticated: false,
        user: null,
      );
      
      print('Login error: $errorMessage');
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Initiate Google OAuth flow
      // This will open browser and return immediately
      // The actual authentication happens in the browser
      // Session will be set when deep link callback is received
      await _authRepository.loginWithGoogle();
      // OAuth flow initiated - keep loading state
      // The callback handler will update the state when OAuth completes
      // If callback doesn't happen within 60 seconds, loading will timeout in loading screen
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      // If it's the OAuth flow initiated message, that's expected
      if (errorMsg.contains('OAuth flow initiated')) {
        // Keep loading state - callback will handle completion
        // Don't set loading to false here - let the callback or timeout handle it
        return true;
      }
      // Other errors - reset loading state
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      return false;
    }
  }

  // Handle Google OAuth callback after redirect
  Future<bool> handleGoogleAuthCallback() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authRepository.handleGoogleAuthCallback();
      await _prefs.setString('auth_token', result.token);
      await _prefs.setString('auth_refresh_token', result.refreshToken);
      state = state.copyWith(
        isAuthenticated: true,
        user: result.user,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authRepository.register(email, password, name);
      await _prefs.setString('auth_token', result.token);
      await _prefs.setString('auth_refresh_token', result.refreshToken);
      await _prefs.setString('auth_user', result.user.toJson().toString());
      state = state.copyWith(
        isAuthenticated: true,
        user: result.user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      // Extract error message
      String errorMessage = 'Registration failed';
      if (e.toString().contains('Google login')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else if (e.toString().contains('already registered') || e.toString().contains('already exists')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    await _prefs.remove('auth_token');
    await _prefs.remove('auth_refresh_token');
    await _prefs.remove('auth_user');
    // Reset to initial loading state, then check auth (will find no user)
    state = AuthState(isLoading: true);
    await _checkAuth(); // This will set isLoading to false and isAuthenticated to false
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, getGlobalPrefs());
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

