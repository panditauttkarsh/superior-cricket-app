import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'dart:math' as math;

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _progressController;
  late Animation<double> _glowAnimation;
  late Animation<double> _progressAnimation;
  int _loadingPercent = 0;

  @override
  void initState() {
    super.initState();

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _progressController.addListener(() {
      setState(() {
        _loadingPercent = (_progressAnimation.value * 100).round();
      });
    });

    // Start progress animation
    _progressController.forward().then((_) {
      // Wait for auth state to be checked, then navigate
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _checkAuthAndNavigate();
          }
        });
      }
    });
  }

  void _checkAuthAndNavigate() {
    final authState = ref.read(authStateProvider);
    
    // Wait a bit more if still loading auth (max 3 seconds)
    if (authState.isLoading) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _checkAuthAndNavigate();
        }
      });
      return;
    }
    
    // Navigate based on auth state
    if (mounted) {
      if (authState.isAuthenticated) {
        // User is authenticated, go to home
        GoRouter.of(context).go('/');
      } else {
        // User is not authenticated, go to login
        GoRouter.of(context).go('/login');
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _progressController.dispose();
    super.dispose();
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
              const Color(0xFF0A1A2E),
              const Color(0xFF1B5E20),
              const Color(0xFF0A1A2E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Pattern
            _buildBackgroundPattern(),
            
            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Section
                  _buildLogoSection(),
                  
                  const SizedBox(height: 40),
                  
                  // Brand Name
                  _buildBrandName(),
                  
                  const SizedBox(height: 16),
                  
                  // Tagline
                  _buildTagline(),
                ],
              ),
            ),
            
            // Loading Section (Bottom)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: _buildLoadingSection(),
            ),
            
            // Version (Bottom)
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'v2.0.4 • Premium Edition',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return CustomPaint(
      painter: BackgroundPatternPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D26A).withOpacity(_glowAnimation.value * 0.6),
                blurRadius: 40,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFF00D26A).withOpacity(_glowAnimation.value * 0.3),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1B5E20).withOpacity(0.8),
                  const Color(0xFF0A1A2E),
                ],
              ),
            ),
            child: Center(
              child: CustomPaint(
                painter: CricketIconPainter(),
                size: const Size(80, 80),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandName() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
                  Text(
          'Cric',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        Text(
          'Play',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF00D26A), // Bright green
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Text(
      'LIVE THE GAME',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.8),
        letterSpacing: 4,
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Loading Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loading Assets...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                '$_loadingPercent%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00D26A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00D26A),
                          Color(0xFF00FF80),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Background Pattern Painter
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    // Draw grid pattern
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Cricket Icon Painter
class CricketIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D26A)
      ..style = PaintingStyle.fill
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final strokePaint = Paint()
      ..color = const Color(0xFF00D26A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Scale factor to fit in 80x80
    final scale = size.width / 100;

    // Cricket Bat - First part
    final path1 = Path()
      ..moveTo(30 * scale, 25 * scale)
      ..lineTo(55 * scale, 50 * scale)
      ..lineTo(50 * scale, 55 * scale)
      ..lineTo(25 * scale, 30 * scale)
      ..close();
    canvas.drawPath(path1, paint);
    canvas.drawPath(path1, strokePaint);

    // Cricket Bat - Second part
    final path2 = Path()
      ..moveTo(55 * scale, 50 * scale)
      ..lineTo(70 * scale, 65 * scale)
      ..lineTo(65 * scale, 70 * scale)
      ..lineTo(50 * scale, 55 * scale)
      ..close();
    canvas.drawPath(path2, paint);
    canvas.drawPath(path2, strokePaint);

    // Ball
    canvas.drawCircle(
      Offset(72 * scale, 72 * scale),
      8 * scale,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
