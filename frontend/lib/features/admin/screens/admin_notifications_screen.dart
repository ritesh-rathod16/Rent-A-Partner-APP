import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Admin Alerts', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAlertItem(
            'New Application',
            'Siddharth M. has applied to be a companion.',
            'Just now',
            Icons.person_add,
            Colors.blue,
          ),
          _buildAlertItem(
            'High Revenue Alert',
            'Platform revenue exceeded ₹50,000 today!',
            '2 hours ago',
            Icons.trending_up,
            Colors.green,
          ),
          _buildAlertItem(
            'Security Flag',
            'Multiple failed login attempts from IP: 192.168.1.1',
            '5 hours ago',
            Icons.security,
            Colors.orange,
          ),
          _buildAlertItem(
            'User Dispute',
            'Dispute reported for Booking #BK-992',
            '1 day ago',
            Icons.report_problem,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String body, String time, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(body, style: const TextStyle(fontSize: 12)),
        trailing: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ),
    );
  }
}
