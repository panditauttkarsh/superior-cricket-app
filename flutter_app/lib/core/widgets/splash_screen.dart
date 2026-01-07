import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ballController;
  late AnimationController _batController;
  late AnimationController _stumpsController;
  late AnimationController _glowController;
  late AnimationController _fadeController;
  late AnimationController _progressController;

  late Animation<double> _ballAnimation;
  late Animation<double> _batAnimation;
  late Animation<double> _stumpsAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  int _loadingPercent = 0;

  @override
  void initState() {
    super.initState();

    // Ball animation (bouncing)
    _ballController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _ballAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ballController,
        curve: Curves.easeInOut,
      ),
    );

    // Bat animation (swinging)
    _batController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _batAnimation = Tween<double>(begin: -0.3, end: 0.3).animate(
      CurvedAnimation(
        parent: _batController,
        curve: Curves.easeInOut,
      ),
    );

    // Stumps animation (subtle shake)
    _stumpsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _stumpsAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _stumpsController,
        curve: Curves.easeInOut,
      ),
    );

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    // Progress animation - 5 seconds
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    _progressController.addListener(() {
      setState(() {
        _loadingPercent = (_progressAnimation.value * 100).round();
      });
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _ballController.dispose();
    _batController.dispose();
    _stumpsController.dispose();
    _glowController.dispose();
    _fadeController.dispose();
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
              AppColors.primary, // #2563EB - Deep blue
              AppColors.primary.withOpacity(0.95),
              AppColors.accent.withOpacity(0.85), // #38BDF8 - Sky blue
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background pattern
              _buildAnimatedBackground(),

              // Subtle cricket elements in background
              _buildFloatingCricketElements(),

              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),
                        
                        // Logo with elegant presentation
                        _buildLogoWithAnimations(),

                        const SizedBox(height: 48),

                        // App name with better styling
                        _buildAppName(),

                        const SizedBox(height: 12),

                        // Tagline
                        _buildTagline(),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading indicator at bottom
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: _buildLoadingIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: BlueBackgroundPainter(
            glowIntensity: _glowAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildLogoWithAnimations() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Outer glow - blue accent
              BoxShadow(
                color: AppColors.accent.withOpacity(_glowAnimation.value * 0.6),
                blurRadius: 50,
                spreadRadius: 15,
              ),
              // Primary glow
              BoxShadow(
                color: AppColors.primary.withOpacity(_glowAnimation.value * 0.4),
                blurRadius: 70,
                spreadRadius: 25,
              ),
              // White glow
              BoxShadow(
                color: Colors.white.withOpacity(_glowAnimation.value * 0.3),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary, // Blue background matching logo
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/Untitled design-2.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback: Show white "P" text if image fails
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Center(
                          child: Text(
                            'P',
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0,
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

  Widget _buildAppName() {
    return const Text(
      'PITCH POINT',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2,
        shadows: [
          Shadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return Text(
      'LIVE THE GAME',
      style: TextStyle(
        fontSize: 18,
        color: Colors.grey[400],
        letterSpacing: 4,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
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
                  color: AppColors.accent, // Sky blue
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent, // Sky blue
                          Colors.white,
                          AppColors.accent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
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

  Widget _buildFloatingCricketElements() {
    return Stack(
      children: [
        // Subtle floating cricket balls in background
        for (int i = 0; i < 5; i++)
          Positioned(
            left: (i * 80.0) + 30,
            top: 80 + (i % 3 * 150.0),
            child: AnimatedBuilder(
              animation: _ballController,
              builder: (context, child) {
                final offset = (i % 2 == 0 ? 1 : -1) *
                    math.sin(_ballController.value * 2 * math.pi + i) *
                    25;
                final verticalOffset = math.cos(_ballController.value * 2 * math.pi + i) * 15;
                return Transform.translate(
                  offset: Offset(offset, verticalOffset),
                  child: Opacity(
                    opacity: 0.15 + (math.sin(_ballController.value * 2 * math.pi + i) * 0.1),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        // Subtle cricket stumps in corners
        Positioned(
          top: 50,
          right: 40,
          child: Opacity(
            opacity: 0.1,
            child: CustomPaint(
              painter: CricketStumpsPainter(),
              size: const Size(30, 40),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: 40,
          child: Opacity(
            opacity: 0.1,
            child: CustomPaint(
              painter: CricketStumpsPainter(),
              size: const Size(30, 40),
            ),
          ),
        ),
      ],
    );
  }
}

// Background Painter with blue theme
class BlueBackgroundPainter extends CustomPainter {
  final double glowIntensity;

  BlueBackgroundPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle radial gradient overlays for depth
    final glowPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withOpacity(0.15 * glowIntensity),
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
          Colors.white.withOpacity(0.1 * glowIntensity),
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

    // Subtle grid pattern (very faint)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03 * glowIntensity)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        gridPaint,
      );
    }
    for (double i = 0; i < size.height; i += 60) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! BlueBackgroundPainter ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

// Cricket Bat Painter
class CricketBatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final strokePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Bat handle
    final handlePath = Path()
      ..moveTo(centerX - 3, centerY - 20)
      ..lineTo(centerX + 3, centerY - 20)
      ..lineTo(centerX + 3, centerY + 15)
      ..lineTo(centerX - 3, centerY + 15)
      ..close();

    canvas.drawPath(handlePath, paint);
    canvas.drawPath(handlePath, strokePaint);

    // Bat blade
    final bladePath = Path()
      ..moveTo(centerX - 8, centerY + 15)
      ..lineTo(centerX - 15, centerY + 35)
      ..lineTo(centerX + 15, centerY + 35)
      ..lineTo(centerX + 8, centerY + 15)
      ..close();

    canvas.drawPath(bladePath, paint);
    canvas.drawPath(bladePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Cricket Ball Painter
class CricketBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw ball
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius, strokePaint);

    // Draw seam lines
    final seamPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(center.dx - radius * 0.6, center.dy),
      Offset(center.dx + radius * 0.6, center.dy),
      seamPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.8),
      -math.pi / 4,
      math.pi / 2,
      false,
      seamPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Cricket Stumps Painter
class CricketStumpsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final strokePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final centerX = size.width / 2;
    final stumpWidth = 3.0;
    final stumpHeight = size.height - 10;

    // Draw three stumps
    for (int i = 0; i < 3; i++) {
      final x = centerX + (i - 1) * 8;
      final stumpRect = Rect.fromLTWH(
        x - stumpWidth / 2,
        5,
        stumpWidth,
        stumpHeight,
      );

      canvas.drawRect(stumpRect, paint);
      canvas.drawRect(stumpRect, strokePaint);
    }

    // Draw bails (top)
    final bailPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        centerX - 12,
        5,
        24,
        4,
      ),
      bailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

