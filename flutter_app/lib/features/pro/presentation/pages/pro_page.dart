import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/providers/auth_provider.dart';

class ProPage extends ConsumerStatefulWidget {
  const ProPage({super.key});

  @override
  ConsumerState<ProPage> createState() => _ProPageState();
}

class _ProPageState extends ConsumerState<ProPage> {
  late Razorpay _razorpay;
  bool _isLoading = false;
  String _selectedPlan = 'pro'; // Default selection

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final user = ref.read(authStateProvider).user;
      if (user != null) {
        // Update subscription in backend
        await ref.read(profileRepositoryProvider).updateSubscriptionPlan(user.id, 'pro');
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('PRO Membership Activated! Payment ID: ${response.paymentId}'),
               backgroundColor: Colors.green,
             ),
           );
           // Refresh auth state to reflect new subscription
           ref.invalidate(authStateProvider);
        }
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Activation failed: $e'), backgroundColor: Colors.red),
         );
       }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handlePayment() async {
    setState(() {
      _isLoading = true;
    });

    final user = ref.read(authStateProvider).user;
    final email = user?.email ?? 'cricketer@pitchpoint.com';

    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Test Key
      'amount': 99900, // ₹999 in paise
      'name': 'PitchPoint Pro',
      'description': 'Annual Pro Membership Subscription',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': '', 
        'email': email
      },
      'theme': {
        'color': '#007AFF'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isPro = authState.user?.subscriptionPlan == 'pro';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'MEMBERSHIP',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF0F9FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => GoRouter.of(context).go('/'),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // Hero Section
            _buildEnhancedHero(isPro),
            
            _buildInteractivePlans(isPro),
            
            const SizedBox(height: 32),
            
            _buildSectionHeader('EXCLUSIVE BENEFITS'),
            
            _buildEnhancedBenefitsList(),
            
            const SizedBox(height: 60), // Balanced padding for bottom visibility
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHero(bool isPro) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0F9FF),
            Color(0xFFE0F2FE),
            Color(0xFFBAE6FD),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
      child: Column(
        children: [
          _buildBranding(),
          const SizedBox(height: 32),
          _buildHeroText(),
          const SizedBox(height: 40),
          if (isPro) _buildActiveBadge() else _buildHeroOffer(),
        ],
      ),
    );
  }

  Widget _buildActiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'PRO MEMBER',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroOffer() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white),
          ),
          child: const Text(
            'SPECIAL APP LAUNCH OFFER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Empower your game with professional data\nand live broadcasting tools.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractivePlans(bool isPro) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 20),
            child: Text(
              'Select Your Path',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedPlanCard(
                  title: 'BASIC',
                  price: '₹0',
                  isSelected: _selectedPlan == 'basic',
                  onTap: () => setState(() => _selectedPlan = 'basic'),
                  features: ['Scoring', 'Profile'],
                  isProCard: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEnhancedPlanCard(
                  title: 'PRO',
                  price: '₹999',
                  period: '/yr',
                  isSelected: _selectedPlan == 'pro',
                  onTap: () => setState(() => _selectedPlan = 'pro'),
                  features: ['Live Streaming', 'Analytics', 'MVP Data'],
                  isProCard: true,
                  badge: 'BEST VALUE',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (!isPro) _buildModernSubscribeButton(),
        ],
      ),
    );
  }

  Widget _buildEnhancedPlanCard({
    required String title,
    required String price,
    String period = '',
    required bool isSelected,
    required VoidCallback onTap,
    required List<String> features,
    required bool isProCard,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isSelected 
                ? (isProCard ? AppColors.primary : Colors.black87)
                : Colors.grey[200]!,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: (isProCard ? AppColors.primary : Colors.black).withOpacity(0.12),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isProCard ? AppColors.primary : Colors.black54,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: const TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.black,
                    ),
                  ),
                  if (period.isNotEmpty)
                    TextSpan(
                      text: period,
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey[600], 
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded, 
                    size: 16, 
                    color: isProCard ? AppColors.primary : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        fontSize: 11, 
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSubscribeButton() {
    final isProSelected = _selectedPlan == 'pro';
    
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isProSelected 
            ? const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF0051FF)],
              )
            : null,
        color: !isProSelected ? Colors.grey[200] : null,
        boxShadow: [
          if (isProSelected)
            BoxShadow(
              color: const Color(0xFF007AFF).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : (isProSelected ? _handlePayment : null),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isProSelected) const Icon(Icons.bolt, color: Colors.white),
                  if (isProSelected) const SizedBox(width: 8),
                  Text(
                    isProSelected ? 'Get Unlimited Access' : 'Selected Basic Plan',
                    style: TextStyle(
                      fontSize: 17, 
                      fontWeight: FontWeight.w900,
                      color: isProSelected ? Colors.white : Colors.black45,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEnhancedBenefitsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildModernBenefitItem(
            icon: Icons.auto_graph_rounded,
            title: 'Advanced Analytics',
            description: 'Get deep insights into your batting & bowling metrics.',
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          _buildModernBenefitItem(
            icon: Icons.videocam_rounded,
            title: 'Live Streaming',
            description: 'Broadcast your local matches with pro scoreboard overlays.',
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          _buildModernBenefitItem(
            icon: Icons.card_membership_rounded,
            title: 'Tourney Discounts',
            description: 'Enjoy exclusive entry fee discounts on major tournaments.',
            color: Colors.orange,
          ),
          const SizedBox(height: 20),
          _buildModernBenefitItem(
            icon: Icons.stars_rounded,
            title: 'MVP Spotlight',
            description: 'Enhanced visibility in regional leaderboards & MVP lists.',
            color: Colors.purple,
            isNew: true,
          ),
        ],
      ),
    );
  }

  Widget _buildModernBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    bool isNew = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 12, color: Colors.black54),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.star, size: 12, color: Colors.black54),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 24),
          height: 1,
          width: 40,
          color: Colors.black12,
        ),
      ],
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        const Text(
          'PitchPoint',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'MEMBER',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 4,
            color: Colors.black.withOpacity(0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroText() {
    return Column(
      children: [
        Text(
          'PLAY LIKE',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            height: 0.9,
            letterSpacing: -1.5,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'A PRO',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            height: 0.9,
            letterSpacing: -1.5,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 24, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SunburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(center, size.width * 0.3, paint);
    canvas.drawCircle(center, size.width * 0.6, paint..color = Colors.white.withOpacity(0.1));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
