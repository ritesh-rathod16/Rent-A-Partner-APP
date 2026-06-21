import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/auth/repository/auth_repository.dart';
import '../repository/settings_repository.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PrivacySecurityScreen extends ConsumerStatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  ConsumerState<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends ConsumerState<PrivacySecurityScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadLocalSettings();
  }

  Future<void> _loadLocalSettings() async {
    final bio = await _storage.read(key: 'biometric_lock');
    setState(() => _biometricEnabled = bio == 'true');
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      
      if (!canAuthenticate) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometrics not supported on this device')));
        return;
      }

      try {
        final bool didAuthenticate = await _auth.authenticate(
          localizedReason: 'Please authenticate to enable biometric lock',
          options: const AuthenticationOptions(stickyAuth: true),
        );
        
        if (didAuthenticate) {
          await _storage.write(key: 'biometric_lock', value: 'true');
          setState(() => _biometricEnabled = true);
        }
      } catch (e) {
        debugPrint('Biometric error: $e');
      }
    } else {
      await _storage.write(key: 'biometric_lock', value: 'false');
      setState(() => _biometricEnabled = false);
    }
  }

  Future<void> _updatePrivacy(String key, bool value) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final newSettings = Map<String, bool>.from(user.privacySettings);
    newSettings[key] = value;

    try {
      await ref.read(settingsRepositoryProvider).updatePrivacySettings(newSettings);
      final updatedUser = await ref.read(authRepositoryProvider).getMe();
      ref.read(currentUserProvider.notifier).state = updatedUser;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final privacy = user.privacySettings;

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text('Privacy & Security', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _sectionHeader('Privacy Settings'),
          _buildSwitchTile(
            'Public Profile', 
            'Allow others to find you in search results', 
            privacy['public_profile'] ?? true, 
            (v) => _updatePrivacy('public_profile', v)
          ),
          _buildSwitchTile(
            'Active Status', 
            'Show when you are active on the platform', 
            privacy['show_active_status'] ?? true, 
            (v) => _updatePrivacy('show_active_status', v)
          ),
          
          const SizedBox(height: 32),
          _sectionHeader('Security Settings'),
          _buildSwitchTile(
            'Biometric Lock', 
            'Use FaceID or Fingerprint to unlock app', 
            _biometricEnabled, 
            _toggleBiometric
          ),
          _buildSwitchTile(
            'Two-Factor Auth', 
            'Require OTP for login from new devices', 
            privacy['two_factor_auth'] ?? false, 
            (v) => _handle2FAToggle(v)
          ),
          
          const Divider(height: 48),
          _buildActionTile(Icons.password_rounded, 'Change Password', _showChangePasswordDialog),
          _buildActionTile(Icons.devices_rounded, 'Connected Devices', _showConnectedDevices),
          _buildActionTile(Icons.delete_forever_rounded, 'Deactivate Account', _showDeactivateConfirm, color: Colors.red),
        ],
      ),
    );
  }

  void _handle2FAToggle(bool value) async {
    if (value) {
      // Show OTP verification flow
      await ref.read(settingsRepositoryProvider).enable2FA();
      _showOTPDialog();
    } else {
      await ref.read(settingsRepositoryProvider).disable2FA();
      final updatedUser = await ref.read(authRepositoryProvider).getMe();
      ref.read(currentUserProvider.notifier).state = updatedUser;
    }
  }

  void _showOTPDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify OTP'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Enter 6-digit OTP sent to email')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(settingsRepositoryProvider).verify2FA(controller.text);
              final updatedUser = await ref.read(authRepositoryProvider).getMe();
              ref.read(currentUserProvider.notifier).state = updatedUser;
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentController, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            TextField(controller: newController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            TextField(controller: confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              try {
                await ref.read(settingsRepositoryProvider).changePassword(currentController.text, newController.text);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showConnectedDevices() async {
    final devices = await ref.read(settingsRepositoryProvider).getConnectedDevices();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Connected Devices', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...devices.map((d) => ListTile(
              leading: const Icon(Icons.smartphone),
              title: Text(d['device_name']),
              subtitle: Text('Last active: ${d['last_active']}'),
              trailing: d['is_current'] ? const Text('Current', style: TextStyle(color: Colors.green)) : IconButton(icon: const Icon(Icons.logout), onPressed: () {}),
            )),
          ],
        ),
      ),
    );
  }

  void _showDeactivateConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Account?'),
        content: const Text('Are you sure you want to deactivate your account? This action is permanent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(settingsRepositoryProvider).deactivateAccount();
              await ref.read(authRepositoryProvider).logout();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Deactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
    );
  }

  Widget _buildSwitchTile(String title, String sub, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryPink,
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color ?? AppColors.darkNavy, size: 20),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: color)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      ),
    );
  }
}
