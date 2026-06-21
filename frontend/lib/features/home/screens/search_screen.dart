import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/companion/repository/companion_repository.dart';
import 'package:rent_a_partner/features/companion/models/companion.dart';
import 'package:rent_a_partner/features/companion/screens/companion_profile_screen.dart';

import 'package:rent_a_partner/core/utils/image_helper.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<Companion> _results = [];
  bool _isSearching = false;

  void _onSearch(String val) async {
    if (val.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final allCompanions = await ref.read(companionRepositoryProvider).getCompanions();
      final filtered = allCompanions.where((c) {
        final query = val.toLowerCase();
        return c.fullName.toLowerCase().contains(query) || 
               c.bio.toLowerCase().contains(query) ||
               c.availableCities.any((city) => city.toLowerCase().contains(query)) ||
               c.interests.any((i) => i.toLowerCase().contains(query));
      }).toList();

      filtered.sort((a, b) {
        if (a.accountType == 'verified' && b.accountType != 'verified') return -1;
        if (a.accountType != 'verified' && b.accountType == 'verified') return 1;
        return 0;
      });

      setState(() => _results = filtered);
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(child: _buildSearchBar()),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.tune_rounded, color: AppColors.primaryPink),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isSearching 
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _results.length,
                      itemBuilder: (context, index) => _buildResultCard(_results[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Search by name, interest, activity...',
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryPink, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text('No companions found', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
          Text('Try searching for a different city or activity', style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildResultCard(Companion companion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompanionProfileScreen(companion: companion))),
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ImageHelper.buildImage(companion.photos.isNotEmpty ? companion.photos[0] : '', width: 50, height: 50),
        ),
        title: Row(
          children: [
            Flexible(child: Text(companion.fullName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            if (companion.accountType == 'verified') ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: Colors.blue, size: 16),
            ],
          ],
        ),
        subtitle: Text(companion.availableCities.join(", "), style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${companion.hourlyRate.toInt()}/hr', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
            Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, color: Colors.amber, size: 12), Text(companion.rating.toString(), style: const TextStyle(fontSize: 10))]),
          ],
        ),
      ),
    );
  }
}
