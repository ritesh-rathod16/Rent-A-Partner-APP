import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';

import 'package:url_launcher/url_launcher_string.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _launchEmail() => launchUrlString('mailto:rrindustryy@gmail.com');
  void _launchCall() => launchUrlString('tel:7721874530');
  void _launchWeb() => launchUrlString('https://rentapartner.vercel.app');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildContactCard(),
          const SizedBox(height: 32),
          Text('Frequently Asked Questions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildFaqItem('How do I book a companion?', 'Navigate to a companion profile, select your date and time, and click "Book Now". Payment is required to confirm.'),
          _buildFaqItem('Is my data secure?', 'Yes, we use industry-standard encryption to protect your personal information and payment details.'),
          _buildFaqItem('Can I cancel a booking?', 'Cancellations are allowed up to 24 hours before the session. Refunds are processed according to our policy.'),
          _buildFaqItem('How do I become a partner?', 'Go to your Profile and click on "Become a Partner" to start your application.'),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _launchEmail,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Chat with Support'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Icon(Icons.headset_mic_outlined, size: 48, color: AppColors.primaryPink),
          const SizedBox(height: 16),
          Text('How can we help you?', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Our support team is available 24/7 to assist you.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.grey)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _contactIcon(Icons.email_outlined, 'Email Us', onTap: _launchEmail),
              _contactIcon(Icons.phone_outlined, 'Call Us', onTap: _launchCall),
              _contactIcon(Icons.language, 'Website', onTap: _launchWeb),
            ],
          )
        ],
      ),
    );
  }

  Widget _contactIcon(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.softPink, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryPink, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(q, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(a, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
