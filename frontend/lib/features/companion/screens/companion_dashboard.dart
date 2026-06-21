import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/companion/repository/companion_repository.dart';
import 'package:rent_a_partner/features/booking/repository/booking_repository.dart';
import 'package:rent_a_partner/features/tracking/repository/tracking_repository.dart';
import 'package:rent_a_partner/features/tracking/screens/tracking_screen.dart';
import 'package:rent_a_partner/features/companion/screens/companion_profile_preview_screen.dart';
import 'package:rent_a_partner/features/companion/screens/companion_settings_screen.dart';
import 'package:rent_a_partner/features/companion/screens/photo_management_screen.dart';

final companionStatsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(companionRepositoryProvider).getCompanionStats();
});

class CompanionDashboard extends ConsumerStatefulWidget {
  const CompanionDashboard({super.key});

  @override
  ConsumerState<CompanionDashboard> createState() => _CompanionDashboardState();
}

class _CompanionDashboardState extends ConsumerState<CompanionDashboard> {
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _startLocationSharing();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationSharing() {
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final stats = ref.read(companionStatsProvider).value;
      if (stats != null && stats['is_online'] == true) {
        try {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            final session = await ref.read(bookingRepositoryProvider).getActiveSession();
            if (session != null) {
              Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
              await ref.read(trackingRepositoryProvider).updateLocation(
                stats['user_id'] ?? '',
                session['id'],
                position.latitude,
                position.longitude,
              );
            }
          }
        } catch (e) {
          debugPrint('Location update failed: $e');
        }
      }
    });
  }

  void _updateRates() async {
    final rateController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Hourly Rate'),
        content: TextField(
          controller: rateController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Rate (₹)', prefixText: '₹'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );

    if (confirm == true && rateController.text.isNotEmpty) {
      try {
        await ref.read(companionRepositoryProvider).updateRates(double.parse(rateController.text));
        ref.invalidate(companionStatsProvider);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rates updated successfully!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _setAvailability() async {
    final hoursController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Availability'),
        content: TextField(
          controller: hoursController,
          decoration: const InputDecoration(hintText: 'e.g. 10 AM - 8 PM'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (confirm == true && hoursController.text.isNotEmpty) {
      try {
        await ref.read(companionRepositoryProvider).setAvailability(hoursController.text);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Availability updated!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _managePhotos() async {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoManagementScreen()));
  }

  void _toggleAvailability() async {
    try {
      await ref.read(companionRepositoryProvider).toggleAvailability();
      ref.invalidate(companionStatsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to toggle: $e')));
    }
  }

  void _previewProfile() async {
    try {
      final companion = await ref.read(companionRepositoryProvider).getMyCompanionProfile();
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => CompanionProfilePreviewScreen(companion: companion)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    }
  }

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanionSettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(companionStatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Companion Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkNavy,
        elevation: 0,
        actions: [
          IconButton(onPressed: () => ref.invalidate(companionStatsProvider), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Online Status', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(stats['is_online'] == true ? 'Visible to Users' : 'Hidden from Users', style: TextStyle(fontSize: 12, color: stats['is_online'] == true ? Colors.green : Colors.red)),
                    ],
                  ),
                  Switch(
                    value: stats['is_online'] ?? false,
                    onChanged: (_) => _toggleAvailability(),
                    activeColor: AppColors.primaryPink,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildEarningsCard(stats),
              const SizedBox(height: 32),
              _sectionHeader('Today\'s Schedule'),
              const SizedBox(height: 16),
              ref.watch(activeSessionProvider).when(
                data: (session) => session == null 
                  ? const Text('No active bookings for today.') 
                  : _buildActiveBooking(session),
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Error: $e'),
              ),
              const SizedBox(height: 32),
              _sectionHeader('Profile Performance'),
              const SizedBox(height: 16),
              _buildStatsGrid(stats),
              const SizedBox(height: 32),
              _sectionHeader('Quick Actions'),
              const SizedBox(height: 16),
              _buildActionGrid(),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading dashboard: $e')),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildEarningsCard(Map<String, dynamic> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Earnings', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('₹${stats['total_earnings']}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _earningStat('This Week', '₹${stats['weekly_earnings']}'),
              _earningStat('Bookings', '${stats['total_bookings']}'),
              _earningStat('Rating', '${stats['rating']} ★'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _earningStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildActiveBooking(Map<String, dynamic> session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.softPink.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.softPink),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24, 
                backgroundImage: session['customer_photo'] != null && session['customer_photo'].isNotEmpty 
                  ? NetworkImage(session['customer_photo']) 
                  : null,
                child: session['customer_photo'] == null || session['customer_photo'].isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session['customer_name'] ?? 'Customer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    Text('${session['date'] ?? ''} • ${session['time'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                child: Text((session['status'] ?? 'Active').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live Location Sharing', style: TextStyle(fontSize: 13)),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(bookingId: session['id'])));
                }, 
                child: const Text('View on Map')
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _statCard('Profile Visits', '${stats['profile_visits'] ?? 0}', Icons.visibility_outlined, Colors.blue),
        _statCard('Response Rate', '${stats['response_rate'] ?? 0}%', Icons.bolt, Colors.orange),
        _statCard('Completion', '${stats['completion_rate'] ?? 0}%', Icons.task_alt, Colors.green),
        _statCard('Total Hours', '${stats['total_hours'] ?? 0}h', Icons.timer_outlined, Colors.purple),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _actionBtn(Icons.edit_note, 'Update Rates', onTap: _updateRates),
        _actionBtn(Icons.event_available, 'Set Availability', onTap: _setAvailability),
        _actionBtn(Icons.photo_library_outlined, 'Manage Photos', onTap: _managePhotos),
        _actionBtn(Icons.person_outline, 'Preview Profile', onTap: _previewProfile),
        _actionBtn(Icons.settings_outlined, 'Settings', onTap: _openSettings),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.softPink.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primaryPink, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
