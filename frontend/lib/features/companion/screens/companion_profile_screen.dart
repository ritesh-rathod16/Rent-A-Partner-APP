import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/companion/models/companion.dart';
import 'package:rent_a_partner/features/booking/repository/booking_repository.dart';
import 'package:rent_a_partner/features/booking/screens/booking_screen.dart';
import 'package:rent_a_partner/features/chat/screens/chat_screen.dart';
import 'package:rent_a_partner/features/auth/repository/auth_repository.dart';
import 'package:rent_a_partner/core/utils/image_helper.dart';

class CompanionProfileScreen extends ConsumerWidget {
  final Companion companion;
  const CompanionProfileScreen({super.key, required this.companion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isFavorite = user?.favorites.contains(companion.id) ?? false;

    final bookingsAsync = ref.watch(myBookingsProvider);
    final hasConfirmedBooking = bookingsAsync.maybeWhen(
      data: (bookings) => bookings.any((b) =>
          b.companionId == companion.id &&
          (b.status.toLowerCase() == 'confirmed' ||
              b.status.toLowerCase() == 'active')),
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // HEADER SECTION - SliverAppBar
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.darkNavy,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: BackButton(color: Colors.white),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border, 
                      color: isFavorite ? AppColors.primaryPink : Colors.white
                    ),
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).toggleFavorite(companion.id);
                      final updatedUser = await ref.read(authRepositoryProvider).getMe();
                      ref.read(currentUserProvider.notifier).state = updatedUser;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ImageHelper.buildImage(
                    companion.photos.isNotEmpty ? companion.photos[0] : '',
                    fit: BoxFit.cover,
                    errorWidget: Container(color: AppColors.softPink, child: const Icon(Icons.person, size: 100, color: AppColors.primaryPink))
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Image Count Badge removed per Issue 4
                ],
              ),
            ),
          ),

          // PROFILE INFORMATION CARD
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      companion.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkNavy,
                                      ),
                                    ),
                                  ),
                                  if (companion.accountType == 'verified') ...[
                                    const SizedBox(width: 8),
                                    const Tooltip(
                                      message: 'Verified Partner',
                                      child: Icon(Icons.verified, color: Colors.blue, size: 22),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${companion.age > 0 ? "${companion.age} • " : ""}${companion.gender} • ${companion.availableCities.isNotEmpty ? companion.availableCities[0] : "N/A"}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (companion.accountType == 'verified')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Verified Partner Account',
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: companion.isOnline ? AppColors.successGreen : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    companion.isOnline ? 'Online' : 'Offline',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: companion.isOnline ? AppColors.successGreen : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // PRICE CARD
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.softPink,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '₹${companion.hourlyRate.toInt()}/hr',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                              const Text(
                                'Min 2 Hours',
                                style: TextStyle(fontSize: 10, color: AppColors.primaryPink, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

    // DETAIL GRID (3-column stats)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildStatCard('Height', companion.height ?? "N/A")),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard('Trust Score', '${companion.trustScore}%')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatCard('Total Bookings', '${companion.totalBookings}')),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ABOUT SECTION
                    _sectionTitle('About Me'),
                    const SizedBox(height: 12),
                    Text(
                      companion.bio,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // PHOTO GALLERY
                    _sectionTitle('Gallery'),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: companion.photos.length,
                        itemBuilder: (ctx, i) => GestureDetector(
                          onTap: () => _showFullScreenGallery(context, companion.photos, i),
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ImageHelper.buildImage(companion.photos[i], fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // INTERESTS SECTION
                    _sectionTitle('Interests'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: companion.interests.map((e) => Chip(
                        label: Text(e),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade200),
                        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.darkNavy),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      )).toList(),
                    ),
                    const SizedBox(height: 32),

                    // RATINGS & REVIEWS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionTitle('Reviews'),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              companion.rating.toString(),
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              ' (${companion.reviewCount} reviews)',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // BOTTOM ACTION BAR
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: Row(
          children: [
            // CHAT ACCESS LOGIC
            InkWell(
              onTap: () {
                if (hasConfirmedBooking) {
                  final booking = bookingsAsync.value!.firstWhere((b) =>
                      b.companionId == companion.id &&
                      (b.status.toLowerCase() == 'confirmed' ||
                          b.status.toLowerCase() == 'active'));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        peerName: companion.fullName,
                        peerId: companion.id,
                        booking: booking,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Chat will be unlocked after booking confirmation.'),
                    backgroundColor: AppColors.darkNavy,
                  ));
                }
              },
              child: Container(
                width: 60,
                height: 56,
                decoration: BoxDecoration(
                  color: hasConfirmedBooking ? AppColors.softPink : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  hasConfirmedBooking ? Icons.chat_bubble_outline : Icons.lock_outline,
                  color: hasConfirmedBooking ? AppColors.primaryPink : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // BOOK NOW BUTTON
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(companion: companion),
                    ),
                  );
                },
                child: Text(
                  'Book Now',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.darkNavy,
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNavy,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenGallery(BuildContext context, List<String> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: photos.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (ctx, i) => InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(child: ImageHelper.buildImage(photos[i], fit: BoxFit.contain)),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
