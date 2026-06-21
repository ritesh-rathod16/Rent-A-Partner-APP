import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/companion/repository/companion_repository.dart';
import 'package:rent_a_partner/features/companion/models/companion.dart';
import 'package:rent_a_partner/features/companion/screens/companion_profile_screen.dart';
import 'package:rent_a_partner/core/utils/image_helper.dart';
import 'package:rent_a_partner/features/auth/repository/auth_repository.dart';

class AllCompanionsScreen extends ConsumerWidget {
  const AllCompanionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionsAsync = ref.watch(companionsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text('All Companions', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkNavy,
        elevation: 0,
      ),
      body: companionsAsync.when(
        data: (companions) {
          final list = List<Companion>.from(companions);
          list.sort((a, b) {
            if (a.accountType == 'verified' && b.accountType != 'verified') return -1;
            if (a.accountType != 'verified' && b.accountType == 'verified') return 1;
            return 0;
          });
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: list.length,
            itemBuilder: (ctx, i) => _CompactCompanionCard(companion: list[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CompactCompanionCard extends ConsumerWidget {
  final Companion companion;
  const _CompactCompanionCard({required this.companion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isFavorite = user?.favorites.contains(companion.id) ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompanionProfileScreen(companion: companion))),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: ImageHelper.buildImage(
                      companion.photos.isNotEmpty ? companion.photos[0] : '',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: InkWell(
                      onTap: () async {
                        await ref.read(authRepositoryProvider).toggleFavorite(companion.id);
                        final updatedUser = await ref.read(authRepositoryProvider).getMe();
                        ref.read(currentUserProvider.notifier).state = updatedUser;
                      },
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white.withOpacity(0.8),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: AppColors.primaryPink,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          companion.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      if (companion.accountType == 'verified')
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child: Icon(Icons.verified, color: Colors.blue, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${companion.hourlyRate.toInt()}/hr',
                    style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(companion.rating.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        companion.availableCities.isNotEmpty ? companion.availableCities[0] : 'N/A',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
