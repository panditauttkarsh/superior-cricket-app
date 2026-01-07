import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/auth_provider.dart';

class EmailVerificationCallbackPage extends ConsumerStatefulWidget {
  final String? code;
  final String? type;

  const EmailVerificationCallbackPage({
    super.key,
    this.code,
    this.type,
  });

  @override
  ConsumerState<EmailVerificationCallbackPage> createState() =>
      _EmailVerificationCallbackPageState();
}

class _EmailVerificationCallbackPageState
    extends ConsumerState<EmailVerificationCallbackPage> {
  bool _isProcessing = true;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    debugPrint('Callback page: initState called');
    debugPrint('Callback page: code = ${widget.code}, type = ${widget.type}');
    _processVerification();
    
    // Also listen to auth state changes in case session is already available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session != null && session.user != null) {
        debugPrint('Callback page: Session already available in initState');
        _processVerification();
      }
    });
  }

  Future<void> _processVerification() async {
    try {
      final supabase = Supabase.instance.client;
      final authNotifier = ref.read(authStateProvider.notifier);
      
      // Check for error parameters in the URL first
      final error = widget.code; // This might contain error info
      if (error != null && error.contains('error')) {
        // Parse error from URL
        final uri = Uri.tryParse('cricplay://login-callback?$error');
        if (uri != null) {
          final errorCode = uri.queryParameters['error_code'];
          final errorDesc = uri.queryParameters['error_description'];
          
          if (errorCode == 'unexpected_failure' && errorDesc?.contains('Database error') == true) {
            // Database error - trigger function might be missing
            if (mounted) {
              setState(() {
                _error = 'Database configuration error. Please contact support. Error: $errorDesc';
                _isProcessing = false;
              });
            }
            return;
          }
        }
      }
      
      debugPrint('Callback page: Starting verification process');
      
      // Supabase Flutter automatically handles the deep link and creates a session
      // Wait a moment for Supabase to process the callback
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Check if we have a session now
      var session = supabase.auth.currentSession;
      debugPrint('Callback page: Initial session check: ${session != null ? "found" : "not found"}');
      
      // If no session yet, wait a bit more and check again (OAuth might take longer)
      int retries = 0;
      while (session == null && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        session = supabase.auth.currentSession;
        retries++;
        debugPrint('Callback page: Retry $retries, session: ${session != null ? "found" : "not found"}');
      }
      
      if (session != null && session.user != null) {
        debugPrint('Callback page: Session found, user ID: ${session.user.id}, email: ${session.user.email}');
        // Session exists - handle OAuth callback (Google login)
        try {
          debugPrint('Callback page: Calling handleGoogleAuthCallback');
          final success = await authNotifier.handleGoogleAuthCallback();
          debugPrint('Callback page: handleGoogleAuthCallback returned: $success');
          
          if (success && mounted) {
            // Refresh auth state to ensure it's updated
            await authNotifier.refreshAuth();
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Verify auth state is actually updated
            final authState = ref.read(authStateProvider);
            debugPrint('Callback page: Auth state - authenticated: ${authState.isAuthenticated}, loading: ${authState.isLoading}');
            
            if (authState.isAuthenticated && mounted) {
              debugPrint('Callback page: User authenticated, navigating to dashboard');
              // Navigate immediately - GoRouter redirect will handle it
              if (mounted) {
                context.go('/');
              }
              return;
            }
            
            // If still not authenticated, try one more refresh
            debugPrint('Callback page: Auth state not updated, trying refresh');
            await authNotifier.refreshAuth();
            await Future.delayed(const Duration(milliseconds: 500));
            final retryAuthState = ref.read(authStateProvider);
            if (retryAuthState.isAuthenticated && mounted) {
              debugPrint('Callback page: Auth state updated after refresh, navigating');
              context.go('/');
              return;
            }
            
            // If auth state not updated yet, try invalidating to force refresh
            ref.invalidate(authStateProvider);
            await Future.delayed(const Duration(milliseconds: 500));
            final finalAuthState = ref.read(authStateProvider);
            if (finalAuthState.isAuthenticated && mounted) {
              context.go('/');
              return;
            }
            
            setState(() {
              _error = 'Authentication succeeded but state update failed. Please try again.';
              _isProcessing = false;
            });
            return;
          }
          
          // If handleGoogleAuthCallback didn't work, try refreshing auth state
          ref.invalidate(authStateProvider);
          await Future.delayed(const Duration(milliseconds: 1000));
          
          final authState = ref.read(authStateProvider);
          if (authState.isAuthenticated && mounted) {
            // Auth state updated - navigate to trigger redirect
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              context.go('/');
            }
            return;
          } else if (mounted) {
            setState(() {
              _error = authState.error ?? 'Authentication completed but state update failed. Please try logging in again.';
              _isProcessing = false;
            });
          }
        } catch (e) {
          // If handleGoogleAuthCallback fails, invalidate and let auth state refresh
          // The session exists, so auth state should pick it up
          debugPrint('Callback handler error: $e');
          ref.invalidate(authStateProvider);
          await Future.delayed(const Duration(milliseconds: 1500));
          
          // Check if auth state is now authenticated
          final authState = ref.read(authStateProvider);
          if (authState.isAuthenticated && mounted) {
            // Auth state updated - navigate to trigger redirect
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              context.go('/');
            }
            return;
          } else if (mounted) {
            setState(() {
              _error = 'Failed to complete authentication. Session exists but state update failed.';
              _isProcessing = false;
            });
          }
        }
      } else {
        // No session yet - might still be processing
        // Try one more time after a longer wait
        await Future.delayed(const Duration(milliseconds: 2000));
        final finalSession = supabase.auth.currentSession;
        
        if (finalSession != null && finalSession.user != null) {
          // Session found on retry - handle as OAuth
          final success = await authNotifier.handleGoogleAuthCallback();
          if (success && mounted) {
            // Auth state updated - navigate to trigger redirect
            await Future.delayed(const Duration(milliseconds: 300));
            final authState = ref.read(authStateProvider);
            if (authState.isAuthenticated && mounted) {
              context.go('/');
            }
            return;
          }
        }
        
        // Still no session
        if (mounted) {
          setState(() {
            _error = 'Authentication failed. The link may have expired. Please try again.';
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to process authentication: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing) ...[
                  const CircularProgressIndicator(
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Verifying your email...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else if (_error != null) ...[
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                    ),
                    child: const Text('Go to Login'),
                  ),
                ] else if (_message != null) ...[
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _message!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

