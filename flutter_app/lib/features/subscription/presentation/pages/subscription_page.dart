import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/config/supabase_config.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  late Razorpay _razorpay;
  bool _isLoading = false;

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
    // Payment Successful
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        // Update subscription in backend
        await ref.read(profileRepositoryProvider).updateSubscriptionPlan(userId, 'pro');
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Upgrade Successful! Payment ID: ${response.paymentId}'),
               backgroundColor: Colors.green,
             ),
           );
           context.pop(true); // Return true to indicate success
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
    // Payment Failed
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response.code} - ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // External Wallet Selected
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet: ${response.walletName}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePayment() async {
    setState(() {
      _isLoading = true;
    });

    final user = SupabaseConfig.client.auth.currentUser;
    final email = user?.email ?? 'test@example.com';
    // Ideally fetch phone number from profile if available, else leave blank or dummy
    // const phone = '9876543210'; 

    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // REPLACE WTH YOUR REAL RAZORPAY KEY
      'amount': 99900, // Amount in paise (999 * 100)
      'name': 'Pitch Point Pro',
      'description': 'Upgrade to Pro Plan',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': '', // Add user phone if available
        'email': email
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing payment: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme
      appBar: AppBar(
        title: const Text('Upgrade to Pro', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, size: 60, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Unleash Your Cricket Potential',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Get professional tools to broadcast and analyze your game.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Plan Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[900],
              ),
              child: Column(
                children: [
                   const Text('PRO PLAN', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: const [
                       Text('₹', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                       Text('999', style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)),
                       Text('/year', style: TextStyle(fontSize: 16, color: Colors.grey, height: 2.5)),
                     ],
                   ),
                   const SizedBox(height: 24),
                   _buildFeature('Live Stream Recording (VOD)'),
                   _buildFeature('Cloud Storage for Matches'),
                   _buildFeature('Advanced Scorecard Overlays'),
                   _buildFeature('PDF & CSV Data Export'),
                   _buildFeature('Sponsor Branding'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Payment Form (Visual Only - kept for UI consistency, though Razorpay handles the form)
            // You might want to remove this if Razorpay is the only input method, 
            // but keeping it as a visual indicator or for other payment methods is fine.
            // For now, I'll comment it out to avoid confusion since Razorpay creates its own UI.
            /*
            const Text('Payment Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[900],
                hintText: 'Card Number',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.credit_card, color: Colors.white60),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[900],
                      hintText: 'MM/YY',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[900],
                      hintText: 'CVV',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            */

            // Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                : const Text('Pay ₹999 & Upgrade', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
             const SizedBox(height: 16),
             const Text(
               'Secured by Razorpay Tests',
               style: TextStyle(color: Colors.white24, fontSize: 12), 
               textAlign: TextAlign.center,
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
