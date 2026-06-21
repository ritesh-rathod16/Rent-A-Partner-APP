import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../repository/review_repository.dart';

import 'package:rent_a_partner/features/auth/repository/auth_repository.dart';
import 'package:rent_a_partner/features/booking/models/booking_model.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final Booking booking;
  const ReviewScreen({super.key, required this.booking});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  double _rating = 5;
  double _safety = 5;
  final _commentController = TextEditingController();

  void _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    try {
      await ref.read(reviewRepositoryProvider).submitReview({
        'booking_id': widget.booking.id,
        'rating': _rating,
        'safety_score': _safety,
        'written_review': _commentController.text,
        'reviewer_id': user.id,
        'reviewee_id': widget.booking.companionId,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!')));
      }
    } catch (e) {
      debugPrint('Review failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Rate Experience', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(widget.booking.companionPhoto),
                    child: widget.booking.companionPhoto.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'How was your session with ${widget.booking.companionName}?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildRatingSection('Overall Rating', _rating, (val) => setState(() => _rating = val)),
            const SizedBox(height: 32),
            _buildRatingSection('Safety & Comfort', _safety, (val) => setState(() => _safety = val)),
            const SizedBox(height: 32),
            Text('Share more details', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Tell us about your experience...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D8D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _submit,
                child: Text('Submit Review', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(String title, double value, Function(double) onRating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            bool isSelected = index < value;
            return InkWell(
              onTap: () => onRating(index + 1.0),
              child: Icon(
                isSelected ? Icons.star : Icons.star_border,
                color: isSelected ? const Color(0xFFFF4D8D) : Colors.grey.shade300,
                size: 40,
              ),
            );
          }),
        ),
      ],
    );
  }
}
