import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Terms & Policies', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkNavy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('RENT A PARTNER'),
            _paragraph('Last Updated: June 20, 2024'),
            const SizedBox(height: 24),
            _paragraph('Welcome to Rent A Partner. By creating an account, accessing, or using the platform, you agree to be bound by these Terms & Conditions.'),
            const Divider(height: 48),
            
            _sectionHeader('1. ABOUT RENT A PARTNER'),
            _paragraph('Rent A Partner is a technology platform that allows users to discover, book, and interact with verified companions for lawful social activities.'),
            _bulletPoint('Events'),
            _bulletPoint('Travel companionship'),
            _bulletPoint('Shopping'),
            _bulletPoint('Fitness activities'),
            _bulletPoint('Coffee meetups'),
            _bulletPoint('Study sessions'),
            _bulletPoint('Entertainment activities'),
            _bulletPoint('Networking events'),
            const SizedBox(height: 16),
            _paragraph('Rent A Partner is NOT:'),
            _bulletPoint('A dating service'),
            _bulletPoint('A matchmaking platform'),
            _bulletPoint('An escort service'),
            _bulletPoint('An adult entertainment platform'),
            _bulletPoint('A prostitution service'),
            
            _sectionHeader('2. ELIGIBILITY'),
            _paragraph('To use Rent A Partner:'),
            _bulletPoint('You must be at least 18 years old.'),
            _bulletPoint('You must provide accurate information.'),
            _bulletPoint('You must comply with all local laws.'),
            _paragraph('Accounts created using false information may be permanently terminated.'),

            _sectionHeader('3. ACCOUNT REGISTRATION'),
            _subHeader('Customer Registration'),
            _paragraph('Customers must provide Full Name, Email Address, Date of Birth, and Gender. Verification is completed through Email OTP.'),
            _subHeader('Companion Registration'),
            _paragraph('Companions must complete an application process including Government ID Verification, Live Selfie Verification, Profile Review, and Admin Approval.'),

            _sectionHeader('4. EMAIL OTP VERIFICATION'),
            _paragraph('All users must verify their email. OTP expires after 5 minutes and may only be used once. Excessive requests may result in restrictions.'),

            _sectionHeader('5. COMPANION APPLICATION POLICY'),
            _paragraph('Companions must provide Aadhaar Card or Driving License, Live Selfie, and Minimum 5 Real Photos. AI-generated photos or fake documents are strictly prohibited.'),

            _sectionHeader('6. BOOKINGS'),
            _paragraph('All bookings must be completed through Rent A Partner. Process: Select Companion -> Select Date & Time -> Select Duration -> Complete Payment -> Receive Confirmation.'),

            _sectionHeader('7. COMMUNICATION POLICY'),
            _paragraph('Before Booking: Users may NOT chat, call, or exchange contact details.'),
            _paragraph('After Booking: Users may use in-app chat, voice, and video calls. Communication must remain respectful.'),

            _sectionHeader('8. LIVE LOCATION REQUIREMENT'),
            _paragraph('During active bookings, live location sharing is mandatory. GPS must remain enabled for safety and dispute resolution.'),

            _sectionHeader('9. PAYMENT POLICY'),
            _paragraph('All payments must be processed through the platform. Off-platform payments are strictly prohibited.'),

            _sectionHeader('10. REFUND POLICY'),
            _subHeader('Customer Cancellation'),
            _bulletPoint('> 12 hours: 75% Refund'),
            _bulletPoint('2-12 hours: 50% Refund'),
            _bulletPoint('< 1 hour: No Refund'),
            _subHeader('Companion Cancellation'),
            _paragraph('Customer receives 100% refund. Companion receives a penalty deduction from their security deposit.'),

            _sectionHeader('11. SECURITY DEPOSIT POLICY'),
            _paragraph('Companions maintain a security deposit wallet used for penalties, fraud investigations, or customer compensation.'),

            _sectionHeader('12. REVIEWS & RATINGS'),
            _paragraph('Reviews are mandatory for both customers and companions to maintain platform quality.'),

            _sectionHeader('13. USER CONDUCT'),
            _paragraph('Prohibited conduct includes harassment, threats, abuse, stalking, hate speech, discrimination, violence, or extortion.'),

            _sectionHeader('14. STRICTLY PROHIBITED ACTIVITIES'),
            _paragraph('Sexual services, solicitation, prostitution, trafficking, illegal activities, and drugs are strictly forbidden and will be reported to authorities.'),

            _sectionHeader('15. PROFILE CONTENT RULES'),
            _paragraph('Explicit content, nudity, fake photos, or copyrighted material are prohibited.'),

            _sectionHeader('24. MODIFICATIONS'),
            _paragraph('Rent A Partner may modify these Terms & Conditions at any time. Continued use constitutes acceptance.'),

            _sectionHeader('26. ZERO-TOLERANCE POLICY'),
            _paragraph('Immediate termination and reporting to authorities for illegal activities or harassment.'),

            const SizedBox(height: 32),
            _sectionHeader('COMMUNITY PROMISE'),
            _paragraph('Rent A Partner exists to create safe, respectful, and meaningful social companionship experiences.'),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryPink),
      ),
    );
  }

  Widget _subHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
      ),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: Colors.grey.shade800),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
          Expanded(child: _paragraph(text)),
        ],
      ),
    );
  }
}
