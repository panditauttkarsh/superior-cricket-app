import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _showPassword = false;
  bool _isLoading = false;
  String? _error;
  String? _message;

  // Animation controllers
  late AnimationController _glowController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatController;

  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;
  
  // Cricket specific animations
  late AnimationController _cricketBallController;
  late Animation<double> _cricketBallAnimation;

  // Shine animation for main title
  late AnimationController _shineController;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'test@cricplay.com';
    _passwordController.text = 'test123';

    // Glow animation for logo
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Slide up animation for form
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    // Floating animation for background elements
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 10000), // Slower for smoother movement
      vsync: this,
    )..repeat();
    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.linear),
    );
    
    // Cricket ball zip animation
    _cricketBallController = AnimationController(
      duration: const Duration(milliseconds: 20000), // Even slower speed (20 seconds)
      vsync: this,
    )..repeat();
    _cricketBallAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _cricketBallController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOutQuart),
      ),
    );
    
    // Shine animation for text tagline - faster and continuous
    _shineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _shineAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _floatController.dispose();
    _cricketBallController.dispose();
    _shineController.dispose();
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
        color: AppColors.primary,
        child: AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    math.cos(_floatAnimation.value * 2 * math.pi) * 0.5 - 0.5,
                    math.sin(_floatAnimation.value * 2 * math.pi) * 0.5 - 0.5,
                  ),
                  end: Alignment(
                    math.cos(_floatAnimation.value * 2 * math.pi + math.pi) * 0.5 + 0.5,
                    math.sin(_floatAnimation.value * 2 * math.pi + math.pi) * 0.5 + 0.5,
                  ),
                  colors: [
                    AppColors.primary,
                    const Color(0xFF1E40AF), // Deep blue
                    const Color(0xFF1D4ED8), // Royal blue
                    AppColors.primary.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
              child: child,
            );
          },
          child: Stack(
            children: [
              // Animated background pattern
              _buildAnimatedBackground(),

              // Floating cricket elements/particles
              _buildFloatingElements(),
              
              // Cricket specific zip animations
              _buildCricketAnimations(),

              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          
                          // Logo Section with fade animation
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildLogo(),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Title with fade and shine animation
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                const Text(
                                  'PITCH POINT',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AnimatedBuilder(
                                  animation: Listenable.merge([_glowAnimation, _shineAnimation]),
                                  builder: (context, child) {
                                    return ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        return LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0.7),
                                            Colors.white.withOpacity(0.7),
                                            Colors.white,
                                            Colors.white.withOpacity(0.7),
                                            Colors.white.withOpacity(0.7),
                                          ],
                                          stops: [
                                            0.0,
                                            (_shineAnimation.value - 0.15).clamp(0.0, 1.0),
                                            _shineAnimation.value.clamp(0.0, 1.0),
                                            (_shineAnimation.value + 0.15).clamp(0.0, 1.0),
                                            1.0,
                                          ],
                                        ).createShader(bounds);
                                      },
                                      child: Text(
                                        'LIVE THE GAME',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          letterSpacing: 3 + (_glowAnimation.value * 1.5),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Form with staggered entrance
                          Column(
                            children: [
                              _buildStaggeredItem(
                                index: 1,
                                child: _buildTabSwitcher(),
                              ),
                              const SizedBox(height: 12),
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStaggeredItem(
                                      index: 2,
                                      child: _buildEmailField(),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStaggeredItem(
                                      index: 3,
                                      child: _buildPasswordField(),
                                    ),
                                    if (_error != null) _buildErrorWidget(),
                                    if (_message != null) _buildMessageWidget(),
                                    const SizedBox(height: 12),
                                    _buildStaggeredItem(
                                      index: 4,
                                      child: _buildSubmitButton(),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildStaggeredItem(
                                      index: 5,
                                      child: _buildDivider(),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStaggeredItem(
                                      index: 6,
                                      child: _buildSocialButtons(),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildStaggeredItem(
                                      index: 7,
                                      child: _buildToggleLink(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaggeredItem({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        final double delay = index * 0.1;
        final double start = (delay).clamp(0.0, 1.0);
        final double end = (delay + 0.6).clamp(0.0, 1.0);
        
        final animation = CurvedAnimation(
          parent: _slideController,
          curve: Interval(start, end, curve: Curves.easeOutQuart),
        );

        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Pulsing white glow effect
              BoxShadow(
                color: Colors.white.withOpacity(_glowAnimation.value * 0.4),
                blurRadius: 30,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(_glowAnimation.value * 0.2),
                blurRadius: 45,
                spreadRadius: 15,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.8 + (_glowAnimation.value * 0.2)),
                width: 2,
              ),
              color: Colors.white.withOpacity(0.1),
            ),
            child: Center(
              child: Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white, // Inner background now white
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/Untitled design-2.png',
                    width: 66,
                    height: 66,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Center(
                          child: Text(
                            'P',
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundPatternPainter(
            animationValue: _floatAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildFloatingElements() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Floating cricket balls/particles
            for (int i = 0; i < 15; i++)
              Positioned(
                left: (math.sin(i * 1.5) * 200) + 200 + (math.cos(_floatAnimation.value * 2 * math.pi + i) * 100),
                top: (math.cos(i * 2.5) * 300) + 400 + (math.sin(_floatAnimation.value * 2 * math.pi + i) * 150),
                child: AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, child) {
                    final double size = 5 + (math.sin(_floatAnimation.value * math.pi + i) * 10).abs();
                    return Opacity(
                      opacity: 0.05 + (0.1 * math.sin(_floatAnimation.value * math.pi + i).abs()),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCricketAnimations() {
    return AnimatedBuilder(
      animation: _cricketBallAnimation,
      builder: (context, child) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final double screenHeight = MediaQuery.of(context).size.height;
        
        return Stack(
          children: [
            // Zipping cricket ball
            if (_cricketBallAnimation.value > -0.5 && _cricketBallAnimation.value < 1.5)
              Positioned(
                left: _cricketBallAnimation.value * screenWidth,
                top: screenHeight * 0.4 + (math.sin(_cricketBallAnimation.value * math.pi) * 100),
                child: Transform.rotate(
                  angle: _cricketBallAnimation.value * 4 * math.pi,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red[800],
                      boxShadow: [
                        // White highlight glow
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                      gradient: const RadialGradient(
                        colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
                        center: Alignment(-0.3, -0.3),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 2,
                        color: Colors.white.withOpacity(0.3), // Seam
                      ),
                    ),
                  ),
                ),
              ),
              
            // Floating Cricket Icons (Bats/Stumps)
            for (int i = 0; i < 6; i++)
              Positioned(
                left: (i * (screenWidth / 6)) + (math.sin(_floatAnimation.value * 2 * math.pi + i) * 30),
                top: (i % 2 == 0 ? 100.0 : screenHeight - 200) + (math.cos(_floatAnimation.value * 2 * math.pi + i) * 50),
                child: Opacity(
                  opacity: 0.15, // Slightly higher opacity
                  child: Transform.rotate(
                    angle: _floatAnimation.value * 1 * math.pi + (i * 0.5),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        i % 2 == 0 ? Icons.sports_cricket : Icons.sports_baseball,
                        size: 60 + (i * 10.0),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  'Log In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isLogin ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: !_isLogin ? AppColors.primary : Colors.white,
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
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'coach@cricplay.com',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white, size: 20),
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
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
                    color: Colors.white,
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
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: const Icon(Icons.lock_outlined, color: Colors.white, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                setState(() => _showPassword = !_showPassword);
              },
            ),
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
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
        color: AppColors.accent.withOpacity(0.1),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _message!,
        style: TextStyle(color: AppColors.accent, fontSize: 14),
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
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: AppColors.accent.withOpacity(0.4),
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
            color: Colors.white.withOpacity(0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR CONTINUE WITH',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withOpacity(0.3),
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
            icon: Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
              width: 20,
              height: 20,
            ),
            label: const Text(
              'Google',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide.none,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
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
            icon: const Icon(Icons.apple, color: Colors.black, size: 24),
            label: const Text(
              'Apple',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide.none,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
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
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// Background Pattern Painter
class BackgroundPatternPainter extends CustomPainter {
  final double animationValue;

  BackgroundPatternPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    // Grid pattern removed for a cleaner look

    // Radial gradient overlays for depth
    final glowPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withOpacity(0.08 * (0.5 + 0.5 * math.sin(animationValue * 2 * math.pi))),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.2, size.height * 0.2),
          radius: size.width * 0.4,
        ),
      );

    final glowPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.05 * (0.5 + 0.5 * math.cos(animationValue * 2 * math.pi))),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.8),
          radius: size.width * 0.5,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      glowPaint1,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      glowPaint2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! BackgroundPatternPainter ||
        oldDelegate.animationValue != animationValue;
  }
}
