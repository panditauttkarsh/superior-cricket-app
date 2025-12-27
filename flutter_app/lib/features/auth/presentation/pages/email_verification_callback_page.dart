import 'package:flutter/material.dart';
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
    _processVerification();
  }

  Future<void> _processVerification() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Get the code from URL parameters
      final code = widget.code;
      
      if (code == null || code.isEmpty) {
        setState(() {
          _error = 'No verification code found in the link';
          _isProcessing = false;
        });
        return;
      }

      // Verify the email using the code
      // Supabase automatically handles the session from the deep link
      // We just need to check if the user is now authenticated
      final session = supabase.auth.currentSession;
      
      // Supabase Flutter automatically handles the deep link and creates a session
      // We just need to wait a moment and check if the session exists
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final currentSession = supabase.auth.currentSession;
      
      if (currentSession != null) {
        // Session exists, user is verified
        // Refresh the auth state in the provider by reading it again
        // This will trigger the provider to check the session
        ref.invalidate(authStateProvider);
        await Future.delayed(const Duration(milliseconds: 500));
        
        setState(() {
          _message = 'Email verified successfully!';
          _isProcessing = false;
        });
        
        // Navigate to home after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go('/');
        }
      } else {
        // No session yet, might need to verify manually
        setState(() {
          _error = 'Verification failed. The link may have expired. Please try logging in or request a new verification email.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to verify email: ${e.toString()}';
        _isProcessing = false;
      });
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

