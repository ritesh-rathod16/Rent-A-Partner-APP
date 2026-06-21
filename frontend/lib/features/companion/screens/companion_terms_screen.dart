import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'apply_companion_screen.dart';

class CompanionTermsScreen extends StatefulWidget {
  const CompanionTermsScreen({super.key});

  @override
  State<CompanionTermsScreen> createState() => _CompanionTermsScreenState();
}

class _CompanionTermsScreenState extends State<CompanionTermsScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Companion Terms', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkNavy,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RENT A PARTNER', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryPink)),
                  const SizedBox(height: 8),
                  Text('COMPANION TERMS & CONDITIONS', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(
                    'Last Updated: October 2023\n\n'
                    'By applying to become a Companion on Rent A Partner, creating a Companion profile, accepting bookings, or using the platform, you agree to these Companion Terms & Conditions.\n\n'
                    'Failure to comply with these Terms may result in warnings, penalties, suspension, account termination, forfeiture of deposits, and legal action where applicable.\n\n'
                    '1. ELIGIBILITY\n'
                    'To become a Companion, you must:\n'
                    '• Be at least 18 years old.\n'
                    '• Submit accurate information.\n'
                    '• Complete identity verification.\n'
                    '• Successfully pass platform review.\n'
                    '• Maintain a valid and active account.\n\n'
                    '2. COMPANION APPLICATION REQUIREMENTS\n'
                    'Every Companion must submit:\n'
                    '• Identity Documents (Aadhaar or DL)\n'
                    '• Live Selfie Verification\n'
                    '• Personal Info (Name, Age, Height, Email, Insta, Languages)\n'
                    '• Address (Current & Permanent)\n'
                    '• Profile Info (5+ real photos, Bio, Interests, Activity Preferences)\n\n'
                    '7. EARNINGS & PLATFORM FEES\n'
                    '• Companion Receives: 70%\n'
                    '• Platform Fee: 25%\n'
                    '• Security Deposit Contribution: 5%\n\n'
                    '8. SECURITY DEPOSIT POLICY\n'
                    'Used for cancellation penalties, customer compensation, fraud investigations, and policy violations.\n\n'
                    '11. START & END OTP REQUIREMENT\n'
                    'All bookings require OTP verification to start and end.\n\n'
                    '12. LIVE LOCATION REQUIREMENT\n'
                    'GPS must remain enabled during every active booking.\n\n'
                    '14. OFF-PLATFORM TRANSACTIONS\n'
                    'Accepting direct payments or bypassing platform fees will result in immediate termination.\n\n'
                    '16. STRICTLY PROHIBITED ACTIVITIES\n'
                    'Sexual services, escort services, prostitution, illegal activities, drug-related activities, harassment, violence, and fraud are strictly prohibited.\n\n'
                    '24. ZERO-TOLERANCE POLICY\n'
                    'Serious violations may be reported to law enforcement authorities.',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade800, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Text('Full terms available on request. By checking below, you acknowledge and agree to follow all platform rules.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _agreed,
                      activeColor: AppColors.primaryPink,
                      onChanged: (v) => setState(() => _agreed = v!),
                    ),
                    Expanded(
                      child: Text(
                        'I agree to the Rent A Partner Companion Terms & Conditions',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _agreed ? AppColors.primaryPink : Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _agreed ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyCompanionScreen())) : null,
                    child: const Text('Continue to Application', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
