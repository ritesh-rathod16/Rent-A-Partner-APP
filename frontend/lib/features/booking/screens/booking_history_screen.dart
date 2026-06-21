import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import '../repository/booking_repository.dart';
import '../models/booking_model.dart';
import 'booking_details_screen.dart';

import 'package:rent_a_partner/core/utils/image_helper.dart';

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text('My Bookings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: bookingsAsync.when(
        data: (bookings) => bookings.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.event_busy, size: 64, color: Colors.grey), const SizedBox(height: 16), Text('No bookings found', style: GoogleFonts.inter(color: Colors.grey))]))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              itemBuilder: (ctx, i) => _buildBookingCard(context, bookings[i]),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsScreen(booking: booking))),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12), 
                    child: ImageHelper.buildImage(
                      booking.companionPhoto, 
                      width: 60, 
                      height: 60, 
                      errorWidget: Container(color: AppColors.softPink, width: 60, height: 60, child: const Icon(Icons.person, color: AppColors.primaryPink))
                    )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.companionName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${booking.date} • ${booking.time}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  _statusPill(booking.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(booking.activity, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.darkNavy, fontSize: 13)),
                  Text('₹${booking.totalAmount.toInt()}', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: AppColors.primaryPink, fontSize: 16)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    Color color = Colors.orange;
    if (status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'completed') color = Colors.green;
    if (status.toLowerCase() == 'cancelled') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
