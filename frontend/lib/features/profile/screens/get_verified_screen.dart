import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/auth/repository/auth_repository.dart';
import 'package:rent_a_partner/features/admin/repository/admin_repository.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class GetVerifiedScreen extends ConsumerStatefulWidget {
  const GetVerifiedScreen({super.key});

  @override
  ConsumerState<GetVerifiedScreen> createState() => _GetVerifiedScreenState();
}

class _GetVerifiedScreenState extends ConsumerState<GetVerifiedScreen> {
  late Razorpay _razorpay;
  Map<String, dynamic>? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ref.read(adminRepositoryProvider).getVerificationSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // In real scenario, verify on backend first. Here we assume success.
      await ref.read(adminRepositoryProvider).verifyUserBadge(ref.read(currentUserProvider)!.id, 'verify');
      final updatedUser = await ref.read(authRepositoryProvider).getMe();
      ref.read(currentUserProvider.notifier).state = updatedUser;
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Congratulations! You are now a Verified Partner.')));
      }
    } catch (e) {
      debugPrint('Verification update failed: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: ${response.message}')));
  }

  void _startPayment() {
    if (_settings == null) return;
    
    var options = {
      'key': 'rzp_live_S3PqGffrDLRgtX',
      'amount': (_settings!['verification_price'] * 100).toInt(),
      'name': 'Rent A Partner',
      'description': 'Account Verification',
      'prefill': {
        'contact': ref.read(currentUserProvider)?.phoneNumber ?? '',
        'email': ref.read(currentUserProvider)?.email ?? ''
      }
    };
    _razorpay.open(options);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_settings == null) return const Scaffold(body: Center(child: Text('Service unavailable')));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Get Verified'), elevation: 0),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.softPink,
                  child: Icon(Icons.verified_rounded, color: Colors.blue, size: 60),
                ),
                const SizedBox(height: 24),
                Text('Get the Blue Badge', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Enhance your profile credibility and get more bookings with a verified status.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                ...(_settings!['benefits'] as List? ?? []).map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Text(benefit.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Verification Fee', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('₹${_settings!['verification_price']}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryPink)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: ElevatedButton(
            onPressed: _startPayment,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
