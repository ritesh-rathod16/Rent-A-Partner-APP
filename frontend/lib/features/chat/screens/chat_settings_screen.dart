import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';

class ChatSettingsScreen extends StatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  bool _readReceipts = true;
  bool _typingIndicator = true;
  bool _msgNotifications = true;
  bool _autoDownload = false;
  String _retention = '90 Days';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text('Chat Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _sectionHeader('Message Controls'),
          _buildSwitch('Read Receipts', 'Allow others to see when you read messages', _readReceipts, (v) => setState(() => _readReceipts = v)),
          _buildSwitch('Typing Status', 'Show when you are typing', _typingIndicator, (v) => setState(() => _typingIndicator = v)),
          _buildSwitch('Notifications', 'Receive alerts for new messages', _msgNotifications, (v) => setState(() => _msgNotifications = v)),
          
          const SizedBox(height: 32),
          _sectionHeader('Privacy & Storage'),
          _buildSwitch('Auto Download', 'Automatically download images over WiFi', _autoDownload, (v) => setState(() => _autoDownload = v)),
          
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Message Retention', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: ['30 Days', '90 Days', 'Forever'].contains(_retention) ? _retention : '90 Days',
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: ['30 Days', '90 Days', 'Forever']
                      .toSet()
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _retention = v);
                  },
                )
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          _sectionHeader('Security'),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.security_rounded, color: Colors.green),
            title: const Text('Contact Protection Active'),
            subtitle: const Text('Phone numbers and payment links are automatically blocked.', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String t) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(t, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)));

  Widget _buildSwitch(String t, String s, bool v, Function(bool) o) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: SwitchListTile(title: Text(t, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text(s, style: const TextStyle(fontSize: 11)), value: v, onChanged: o, activeColor: AppColors.primaryPink),
  );
}
