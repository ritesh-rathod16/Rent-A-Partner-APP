import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../repository/companion_repository.dart';

class CompanionSettingsScreen extends ConsumerStatefulWidget {
  const CompanionSettingsScreen({super.key});

  @override
  ConsumerState<CompanionSettingsScreen> createState() => _CompanionSettingsScreenState();
}

class _CompanionSettingsScreenState extends ConsumerState<CompanionSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailAlerts = true;
  bool _autoReply = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('General', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
          const SizedBox(height: 16),
          _buildSwitchTile('Push Notifications', 'Get alerts for new booking requests', _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
          const Divider(),
          _buildSwitchTile('Email Alerts', 'Receive account updates via email', _emailAlerts, (v) => setState(() => _emailAlerts = v)),
          const Divider(),
          _buildSwitchTile('Auto Reply', 'Automatically respond to new messages', _autoReply, (v) => setState(() => _autoReply = v)),
          const SizedBox(height: 32),
          Text('Privacy', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
          const SizedBox(height: 16),
          _buildSwitchTile('Show Online Status', 'Allow users to see when you are active', true, (v) {}),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Settings'),
          )
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String sub, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryPink,
    );
  }

  void _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(companionRepositoryProvider).updateSettings({
        'push_notifications': _notificationsEnabled,
        'email_alerts': _emailAlerts,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
