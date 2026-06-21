import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/api/api_client.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/tracking/repository/safety_repository.dart';
import 'package:rent_a_partner/features/profile/screens/trusted_contacts_screen.dart';
import 'package:rent_a_partner/features/auth/repository/auth_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:camera/camera.dart';

class EmergencySosScreen extends ConsumerStatefulWidget {
  final String? bookingId;
  const EmergencySosScreen({super.key, this.bookingId});

  @override
  ConsumerState<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends ConsumerState<EmergencySosScreen> {
  bool _isActivated = false;
  String? _currentSosId;

  void _activateSOS() async {
    setState(() => _isActivated = true);
    
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        debugPrint('Location access failed for SOS');
      }

      final response = await ref.read(apiClientProvider).post('/safety/sos/trigger', data: {
        'booking_id': widget.bookingId,
        'location': {'lat': position?.latitude ?? 0.0, 'lng': position?.longitude ?? 0.0},
      });
      
      _currentSosId = response.data['alert_id'];

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Emergency Alert Sent'),
            content: const Text('Your current location and emergency status have been broadcasted to our safety team and your emergency contacts.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to trigger SOS: $e')));
      setState(() => _isActivated = false);
    }
  }

  void _startPanicRecording() async {
    if (_currentSosId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please activate SOS first')));
      return;
    }
    
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
      final controller = CameraController(backCamera, ResolutionPreset.medium, enableAudio: true);
      
      await controller.initialize();
      await controller.startVideoRecording();
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording evidence...')));
      
      Future.delayed(const Duration(seconds: 15), () async {
        final XFile videoFile = await controller.stopVideoRecording();
        await controller.dispose();
        
        try {
          await ref.read(safetyRepositoryProvider).uploadPanicRecording(_currentSosId!, videoFile.path);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidence uploaded securely.')));
        } catch (e) {
          debugPrint('Upload failed: $e');
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camera error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Safety Center', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onLongPress: _isActivated ? null : _activateSOS,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _isActivated ? Colors.grey : AppColors.primaryPink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isActivated ? Colors.grey : AppColors.primaryPink).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emergency_share_rounded, size: 64, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          _isActivated ? 'SENT' : 'SOS',
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _isActivated ? 'Alert Broadcasted' : 'Long Press to Activate',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _isActivated ? Colors.green : AppColors.darkNavy),
            ),
            const SizedBox(height: 16),
            Text(
              'Activating SOS will immediately share your live location with our 24/7 safety response team and your emergency contacts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey, height: 1.5),
            ),
            const Spacer(),
            _buildSafetyAction(Icons.mic_rounded, 'Start Panic Recording', _startPanicRecording, color: Colors.orange),
            _buildSafetyAction(Icons.phone_in_talk_rounded, 'Call Trusted Contact', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrustedContactsScreen()));
            }),
            _buildSafetyAction(Icons.local_police_outlined, 'Call Emergency Services (112)', () {
              launchUrlString('tel:112');
            }),
            _buildSafetyAction(Icons.mail_outline_rounded, 'Contact Safety Support', () {
              final user = ref.read(currentUserProvider);
              final String subject = Uri.encodeComponent('URGENT Safety Support - ${user?.fullName}');
              final String body = Uri.encodeComponent('User ID: ${user?.id}\nName: ${user?.fullName}\nPhone: ${user?.phoneNumber}\n\nDescription of issue: ');
              launchUrlString('mailto:rrindustryy@gmail.com?subject=$subject&body=$body');
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyAction(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: color != null ? BorderSide(color: color) : null,
        ),
      ),
    );
  }
}
