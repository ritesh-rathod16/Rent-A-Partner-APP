import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import 'package:rent_a_partner/features/companion/models/companion.dart';
import 'package:rent_a_partner/features/booking/repository/booking_repository.dart';
import 'package:rent_a_partner/features/auth/repository/auth_repository.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/core/utils/image_helper.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Companion companion;
  const BookingScreen({super.key, required this.companion});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late Razorpay _razorpay;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  int _duration = 2;
  String _activity = 'Event Partner';
  String _currentBookingId = '';
  
  final List<String> _activities = ['Travel', 'Events', 'Event Partner', 'Party', 'Fitness', 'Movie', 'Coffee'];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ref.read(bookingRepositoryProvider).confirmBooking(
      _currentBookingId,
      response.paymentId!,
      response.signature!,
    );
    ref.invalidate(myBookingsProvider);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Booking Confirmed!'),
        content: const Text('Your session has been successfully scheduled. You can track it in the Bookings tab.'),
        actions: [TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Great!'))],
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: ${response.message}')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void _startPayment() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to book a companion')));
      return;
    }
    
    final amount = widget.companion.hourlyRate * _duration;
    try {
      final bookingInfo = await ref.read(bookingRepositoryProvider).createBooking(
        widget.companion.id,
        DateFormat('yyyy-MM-dd').format(_selectedDate),
        _selectedTime.format(context),
        _duration,
        _activity,
        amount,
        user.id,
      );

      _currentBookingId = bookingInfo['booking_id'];

      var options = {
        'key': 'rzp_live_S3PqGffrDLRgtX',
        'amount': (amount * 100).toInt(),
        'name': 'Rent A Partner',
        'description': 'Booking for ${widget.companion.fullName}',
        'order_id': bookingInfo['razorpay_order_id'],
        'prefill': {'contact': user.phoneNumber, 'email': user.email},
      };

      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text('Schedule Booking', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSummarySection(),
            const SizedBox(height: 24),
            _buildSelectionSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _startPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPink,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'Continue to Payment • ₹${(widget.companion.hourlyRate * _duration).toInt()}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking Summary', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: ImageHelper.buildImage(widget.companion.photos.isNotEmpty ? widget.companion.photos[0] : '', width: 60, height: 60),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.companion.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(widget.companion.availableCities.join(", "), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          _priceRow('Base Hourly Rate', '₹${widget.companion.hourlyRate.toInt()}'),
          _priceRow('Total Duration', '$_duration Hours'),
          const Divider(height: 32),
          _priceRow('Total Amount', '₹${(widget.companion.hourlyRate * _duration).toInt()}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Select Date'),
          const SizedBox(height: 12),
          _pickerTile(DateFormat('EEEE, dd MMM yyyy').format(_selectedDate), Icons.calendar_today, () async {
            final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
            if (date != null) setState(() => _selectedDate = date);
          }),
          const SizedBox(height: 24),
          _sectionTitle('Start Time'),
          const SizedBox(height: 12),
          _pickerTile(_selectedTime.format(context), Icons.access_time, () async {
            final time = await showTimePicker(context: context, initialTime: _selectedTime);
            if (time != null) setState(() => _selectedTime = time);
          }),
          const SizedBox(height: 24),
          _sectionTitle('Duration (Hours)'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [1, 2, 3, 4, 5, 6, 8, 12].map((h) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _durationChip(h),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Activity Category'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _activities.contains(_activity) ? _activity : _activities.first,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            items: _activities
                .toSet()
                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                .toList(),
            onChanged: (v) {
              debugPrint('Selected Activity: $v');
              if (v != null) setState(() => _activity = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14));

  Widget _pickerTile(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryPink, size: 20),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _durationChip(int h) {
    bool selected = _duration == h;
    return InkWell(
      onTap: () => setState(() => _duration = h),
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPink : AppColors.softPink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$h', style: TextStyle(color: selected ? Colors.white : AppColors.primaryPink, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _priceRow(String l, String v, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TextStyle(color: isTotal ? AppColors.darkNavy : Colors.grey, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(v, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTotal ? 18 : 14, color: isTotal ? AppColors.primaryPink : AppColors.darkNavy)),
        ],
      ),
    );
  }
}
