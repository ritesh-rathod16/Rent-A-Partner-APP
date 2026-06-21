import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/booking/models/booking_model.dart';
import 'package:rent_a_partner/features/chat/screens/chat_screen.dart';
import 'package:rent_a_partner/features/tracking/screens/tracking_screen.dart';
import 'package:rent_a_partner/core/utils/image_helper.dart';

import 'package:rent_a_partner/features/tracking/repository/safety_repository.dart';
import 'package:rent_a_partner/features/auth/repository/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rent_a_partner/core/api/api_error_handler.dart';
import 'package:rent_a_partner/features/review/screens/review_screen.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final Booking booking;
  const BookingDetailsScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(title: const Text('Booking Details'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 24),
            _buildCompanionInfo(context, ref),
            const SizedBox(height: 24),
            _buildMeetingDetails(),
            const SizedBox(height: 24),
            if (booking.status.toLowerCase() == 'completed')
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(booking: booking))),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Rate Your Experience'),
                  ),
                ),
              ),
            _buildPaymentSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.softPink,
            radius: 30,
            child: Icon(Icons.verified_outlined, color: AppColors.primaryPink, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking ${booking.status}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('ID: ${booking.id.toUpperCase()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (booking.status.toLowerCase() == 'active' || booking.status.toLowerCase() == 'confirmed')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(bookingId: booking.id))),
                      icon: const Icon(Icons.location_on_outlined, size: 18),
                      label: const Text('View Location', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryPink,
                        backgroundColor: AppColors.softPink,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCompanionInfo(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: ImageHelper.buildImage(booking.companionPhoto, width: 50, height: 50),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.companionName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Verified Partner', style: TextStyle(color: Colors.blue, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showReportDialog(context, ref),
                icon: const Icon(Icons.report_problem_outlined, color: Colors.red),
              ),
              IconButton(
                onPressed: () {
                  if (booking.status.toLowerCase() == 'confirmed' || booking.status.toLowerCase() == 'active') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(peerName: booking.companionName, peerId: booking.companionId, booking: booking)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat is only available for active/confirmed bookings.')));
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryPink),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMeetingDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meeting Info', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          _infoRow(Icons.calendar_today, 'Date', booking.date),
          _infoRow(Icons.access_time, 'Time', booking.time),
          _infoRow(Icons.timer_outlined, 'Duration', '${booking.duration} Hours'),
          _infoRow(Icons.star_outline, 'Activity', booking.activity),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.darkNavy, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount Paid', style: TextStyle(color: Colors.white70)),
              Text('₹${booking.totalAmount.toInt()}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
              SizedBox(width: 8),
              Text('Payment Successful via Razorpay', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    final List<String> reasons = [
      'Inappropriate Behavior',
      'Harassment',
      'Safety Concern',
      'Fake Profile',
      'No-show / Delay',
      'Payment Issue',
      'Other'
    ];
    
    String? selectedReason;
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Report User', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reason for reporting', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select a reason'),
                      value: selectedReason,
                      items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (v) => setState(() => selectedReason = v),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Description', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Provide more details about the issue...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                if (selectedReason == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a report reason.')));
                  return;
                }
                if (descController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a description.')));
                  return;
                }

                try {
                  final currentUser = ref.read(currentUserProvider);
                  if (currentUser == null) return;

                  final reportedUserId = (currentUser.id == booking.customerId) 
                    ? (booking.companionUserId ?? booking.companionId)
                    : (booking.customerUserId ?? booking.customerId);

                print("Booking ID: ${booking.id}");
                print("Reporting user: $reportedUserId");

                final payload = {
                  'reported_user_id': reportedUserId,
                  'booking_id': booking.id,
                  'reason': selectedReason!,
                  'description': descController.text.trim(),
                };
                
                print('DEBUG: Sending report payload: $payload');

                  await ref.read(safetyRepositoryProvider).fileReport(payload);
                  
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Report submitted successfully. Our safety team will review it.'),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  if (context.mounted) {
                    final errorMsg = ApiErrorHandler.handle(e);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(errorMsg),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
              child: const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData i, String l, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(i, size: 18, color: Colors.grey),
          const SizedBox(width: 16),
          Text(l, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
