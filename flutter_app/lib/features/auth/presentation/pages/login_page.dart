import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _showPassword = false;
  bool _isLoading = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'test@cricplay.com';
    _passwordController.text = 'test123';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _error = null;
      _message = null;
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      
      if (_isLogin) {
        final success = await authNotifier.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          if (success) {
            // Wait a moment for auth state to fully update in the provider
            await Future.delayed(const Duration(milliseconds: 300));
            
            // Verify auth state is set
            final currentAuthState = ref.read(authStateProvider);
            
            if (currentAuthState.isAuthenticated && mounted) {
              // Navigate directly to home - router will allow it since we're authenticated
              context.go('/');
            } else if (mounted) {
              setState(() {
                _error = currentAuthState.error ?? 'Login failed. Please try again.';
              });
            }
          } else {
            // Login failed - show error from auth state
            final authState = ref.read(authStateProvider);
            setState(() {
              _error = authState.error ?? 'Invalid email or password. Please check your credentials.';
            });
          }
        }
      } else {
        // Sign up
        final success = await authNotifier.register(
          _emailController.text.trim(),
          _passwordController.text,
          _emailController.text.split('@')[0], // Use email prefix as name
        );
        
        if (success && mounted) {
          setState(() {
            _message = 'Account created successfully! Please log in.';
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() {
            _error = 'Registration failed. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (err) {
      setState(() {
        _error = err.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _error = 'Please enter your email address';
      });
      return;
    }

    setState(() {
      _error = null;
      _message = null;
      _isLoading = true;
    });

    // Simulate password reset
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _message = 'Password reset link sent to your email';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF022C22), // emerald-950
              const Color(0xFF064E3B), // emerald-900
              const Color(0xFF022C22), // emerald-950
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    
                    // Logo Section
                    _buildLogo(),
                    
                    const SizedBox(height: 48),
                    
                    // Title
                    const Text(
                      'PITCH POINT',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'LIVE THE GAME',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[400],
                        letterSpacing: 4,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Tab Switcher
                    _buildTabSwitcher(),
                    
                    const SizedBox(height: 24),
                    
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email Field
                          _buildEmailField(),
                          
                          const SizedBox(height: 24),
                          
                          // Password Field
                          _buildPasswordField(),
                          
                          // Error/Message Display
                          if (_error != null) _buildErrorWidget(),
                          if (_message != null) _buildMessageWidget(),
                          
                          const SizedBox(height: 24),
                          
                          // Submit Button
                          _buildSubmitButton(),
                          
                          const SizedBox(height: 32),
                          
                          // Divider
                          _buildDivider(),
                          
                          const SizedBox(height: 24),
                          
                          // Social Login Buttons
                          _buildSocialButtons(),
                          
                          const SizedBox(height: 32),
                          
                          // Toggle Link
                          _buildToggleLink(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF10B981), // emerald-500
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bat (diagonal line)
          Positioned(
            bottom: 8,
            left: 8,
            child: Transform.rotate(
              angle: -0.785, // -45 degrees
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Ball (circle)
          Positioned(
            top: 0,
            right: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isLogin ? Colors.grey[800]!.withOpacity(0.5) : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: _isLogin ? const Color(0xFF10B981) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Log In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: _isLogin ? Colors.white : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: !_isLogin ? Colors.grey[800]!.withOpacity(0.5) : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: !_isLogin ? const Color(0xFF10B981) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: !_isLogin ? Colors.white : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'coach@cricplay.com',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey, size: 20),
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isLogin)
              TextButton(
                onPressed: _handleForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () {
                setState(() => _showPassword = !_showPassword);
              },
            ),
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _error!,
        style: TextStyle(color: Colors.red[300], fontSize: 14),
      ),
    );
  }

  Widget _buildMessageWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _message!,
        style: const TextStyle(color: Color(0xFF10B981), fontSize: 14),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981), // emerald-500
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const Text(
                'Please wait...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? 'Log In' : 'Sign Up',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[700],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[700],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _error = null;
      _message = null;
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final success = await authNotifier.loginWithGoogle();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (!success) {
          final authState = ref.read(authStateProvider);
          setState(() {
            _error = authState.error ?? 'Google login failed. Please try again.';
          });
        }
        // If successful, OAuth flow will handle redirect and navigation
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = err.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleGoogleLogin,
            icon: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            label: const Text(
              'Google',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[700]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.apple, color: Colors.white, size: 20),
            label: const Text(
              'Apple',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[700]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : 'Already have an account? ',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        TextButton(
          onPressed: () => setState(() => _isLogin = !_isLogin),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _isLogin ? 'Sign Up' : 'Log In',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
