import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/companion/repository/companion_repository.dart';
import 'package:rent_a_partner/features/companion/screens/companion_profile_screen.dart';
import 'package:rent_a_partner/features/booking/screens/booking_history_screen.dart';
import 'package:rent_a_partner/features/profile/screens/profile_screen.dart';
import 'package:rent_a_partner/features/profile/screens/notifications_screen.dart';
import 'package:rent_a_partner/features/auth/repository/auth_repository.dart';
import 'package:rent_a_partner/features/home/repository/ads_repository.dart';
import 'package:rent_a_partner/features/home/models/advertisement.dart';
import 'package:rent_a_partner/features/companion/models/companion.dart';
import 'package:rent_a_partner/features/companion/screens/companion_terms_screen.dart';
import 'package:rent_a_partner/core/utils/image_helper.dart';
import 'package:rent_a_partner/features/chat/screens/chat_list_screen.dart';
import 'package:rent_a_partner/features/booking/repository/booking_repository.dart';
import 'package:rent_a_partner/features/tracking/screens/tracking_screen.dart';
import 'all_companions_screen.dart';
import 'search_screen.dart';

final homeTabIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const HomeView(),
    const SearchScreen(),
    const BookingHistoryScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(homeTabIndexProvider);
    
    return Scaffold(
      key: _scaffoldKey,
      body: _screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(homeTabIndexProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryPink,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), activeIcon: Icon(Icons.search_rounded), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month_rounded), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), activeIcon: Icon(Icons.chat_bubble_rounded), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final photoUrl = user?.photoUrl;
    final activeAds = ref.watch(activeAdsProvider);
    final companionsAsync = ref.watch(companionsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Container(
      color: AppColors.lightGray,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {},
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.primaryPink, size: 20),
                              const SizedBox(width: 4),
                              Text(user?.city ?? 'Mumbai, India', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())), 
                              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.darkNavy, size: 28)
                            ),
                            InkWell(
                              onTap: () => ref.read(homeTabIndexProvider.notifier).state = 4, // Go to Profile
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.softPink,
                                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
                                  ? ImageHelper.getImageProvider(photoUrl) 
                                  : null,
                                child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, color: AppColors.primaryPink, size: 20) : null,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Hi, ${user?.fullName.split(' ')[0] ?? 'Partner'} 👋', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkNavy)),
                    Text('Find your perfect companion for every moment.', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 24),
                    _buildSearchBar(context),
                  ],
                ),
              ),
            ),

            // Active Session Card
            ref.watch(activeSessionProvider).when(
              data: (session) => session == null 
                ? const SliverToBoxAdapter(child: SizedBox.shrink()) 
                : SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _buildActiveSessionCard(context, session),
                    ),
                  ),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Hero Banners
            activeAds.when(
              data: (ads) => ads.isEmpty ? const SliverToBoxAdapter(child: SizedBox(height: 20)) : SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 20), child: _AdCarousel(ads: ads))),
              loading: () => const SliverToBoxAdapter(child: SizedBox(height: 160, child: Center(child: CircularProgressIndicator()))),
              error: (e, s) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Categories
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 28), child: _buildCategories(ref, context))),

            // Top Companions Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Top Companions', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllCompanionsScreen())), 
                      child: Text('See All', style: GoogleFonts.inter(color: AppColors.primaryPink, fontWeight: FontWeight.bold))
                    ),
                  ],
                ),
              ),
            ),

            // Companions List
            companionsAsync.when(
              data: (companions) {
                var filtered = selectedCategory == 'All' 
                    ? companions 
                    : companions.where((c) => c.serviceCategories.contains(selectedCategory)).toList();
                
                // Sort: Verified at the top
                filtered.sort((a, b) {
                  if (a.accountType == 'verified' && b.accountType != 'verified') return -1;
                  if (a.accountType != 'verified' && b.accountType == 'verified') return 1;
                  // Then by rating
                  return b.rating.compareTo(a.rating);
                });

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) => _CompanionCard(companion: filtered[index]), childCount: filtered.length)),
                );
              },
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            ),

            // Become Companion Banner
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: _buildBecomeCompanionPromo(context))),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionCard(BuildContext context, Map<String, dynamic> session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.darkNavy.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(session['companion_photo'] ?? ''),
                child: session['companion_photo'] == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Session with ${session['companion_name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Status: ${session['status']}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(bookingId: session['id']))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Track Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]),
      child: TextField(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Search by name, interest, activity...',
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryPink, size: 24),
          suffixIcon: Container(margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.softPink, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.tune_rounded, color: AppColors.primaryPink, size: 18)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategories(WidgetRef ref, BuildContext context) {
    final categories = [
      {'name': 'All', 'icon': Icons.grid_view_rounded},
      {'name': 'Travel', 'icon': Icons.flight_rounded},
      {'name': 'Events', 'icon': Icons.confirmation_number_rounded},
      {'name': 'Party', 'icon': Icons.celebration_rounded},
      {'name': 'Fitness', 'icon': Icons.fitness_center_rounded},
      {'name': 'More', 'icon': Icons.more_horiz_rounded},
    ];
    final selected = ref.watch(selectedCategoryProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(children: categories.map((cat) {
        final isSelected = selected == cat['name'];
        return Padding(
          padding: const EdgeInsets.only(right: 20),
          child: InkWell(
            onTap: () {
              if (cat['name'] == 'More') {
                _showAllCategories(context, ref);
              } else {
                ref.read(selectedCategoryProvider.notifier).state = cat['name'] as String;
              }
            },
            child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200), 
                padding: const EdgeInsets.all(16), 
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryPink : AppColors.softPink, 
                  shape: BoxShape.circle,
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.primaryPink.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))] : null,
                ), 
                child: Icon(cat['icon'] as IconData, color: isSelected ? Colors.white : AppColors.primaryPink, size: 26)
              ),
              const SizedBox(height: 10),
              Text(cat['name'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? AppColors.primaryPink : AppColors.darkNavy)),
            ]),
          ),
        );
      }).toList()),
    );
  }

  void _showAllCategories(BuildContext context, WidgetRef ref) {
    final allCategories = [
      {'name': 'Event Partner', 'icon': Icons.confirmation_number_rounded},
      {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded},
      {'name': 'Movie Partner', 'icon': Icons.movie_creation_rounded},
      {'name': 'Coffee Meetups', 'icon': Icons.coffee_rounded},
      {'name': 'Study Partner', 'icon': Icons.book_rounded},
      {'name': 'Fitness Buddy', 'icon': Icons.fitness_center_rounded},
      {'name': 'Party & Wedding', 'icon': Icons.celebration_rounded},
      {'name': 'Networking', 'icon': Icons.business_center_rounded},
      {'name': 'Photography', 'icon': Icons.camera_alt_rounded},
      {'name': 'Hiking', 'icon': Icons.terrain_rounded},
      {'name': 'Cricket', 'icon': Icons.sports_cricket_rounded},
      {'name': 'Tour Guide', 'icon': Icons.map_rounded},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('Explore Categories', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.85,
                ),
                itemCount: allCategories.length,
                itemBuilder: (ctx, i) {
                  final cat = allCategories[i];
                  return InkWell(
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = cat['name'] as String;
                      Navigator.pop(ctx);
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(color: AppColors.softPink, shape: BoxShape.circle),
                          child: Icon(cat['icon'] as IconData, color: AppColors.primaryPink, size: 28),
                        ),
                        const SizedBox(height: 10),
                        Text(cat['name'] as String, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNavy)),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBecomeCompanionPromo(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryPink,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPink.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: Opacity(
                    opacity: 0.2,
                    child: Icon(Icons.people_alt_rounded, size: constraints.maxWidth * 0.45, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Become a Companion',
                        style: GoogleFonts.poppins(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Earn on your time, your way!',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9), 
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanionTermsScreen())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryPink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          elevation: 0,
                        ),
                        child: const Text('Apply Now', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }
}

class _AdCarousel extends StatefulWidget {
  final List<Advertisement> ads;
  const _AdCarousel({required this.ads});

  @override
  State<_AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<_AdCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (_currentPage < widget.ads.length - 1) _currentPage++; else _currentPage = 0;
      if (_pageController.hasClients) _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutExpo);
    });
  }

  @override
  void dispose() { _timer?.cancel(); _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(height: 180, child: PageView.builder(controller: _pageController, onPageChanged: (p) => setState(() => _currentPage = p), itemCount: widget.ads.length, itemBuilder: (ctx, i) => _buildAdCard(widget.ads[i]))),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.ads.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), height: 6, width: _currentPage == i ? 20 : 6, decoration: BoxDecoration(color: _currentPage == i ? AppColors.primaryPink : Colors.grey.shade300, borderRadius: BorderRadius.circular(3))))),
    ]);
  }

  Widget _buildAdCard(Advertisement ad) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageHelper.buildImage(ad.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(ad.title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(ad.subtitle, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(ad.buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanionCard extends ConsumerWidget {
  final Companion companion;
  const _CompanionCard({required this.companion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isFavorite = user?.favorites.contains(companion.id) ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))]),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompanionProfileScreen(companion: companion))),
        borderRadius: BorderRadius.circular(28),
        child: Column(children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), 
              child: ImageHelper.buildImage(
                companion.photos.isNotEmpty ? companion.photos[0] : '', 
                height: 220, 
                width: double.infinity,
                errorWidget: Container(height: 220, color: AppColors.softPink, child: const Icon(Icons.person, size: 60, color: AppColors.primaryPink))
              )
            ),
            Positioned(
              top: 16, 
              right: 16, 
              child: InkWell(
                onTap: () async {
                  await ref.read(authRepositoryProvider).toggleFavorite(companion.id);
                  final updatedUser = await ref.read(authRepositoryProvider).getMe();
                  ref.read(currentUserProvider.notifier).state = updatedUser;
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9), 
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border, 
                    color: AppColors.primaryPink, 
                    size: 22
                  )
                ),
              )
            ),
            Positioned(bottom: 16, left: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)), child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: companion.isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle)), const SizedBox(width: 8), Text(companion.isOnline ? 'Online' : 'Offline', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))]))),
          ]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Row(children: [
                    Flexible(
                      child: Text(
                        companion.age > 0 
                          ? '${companion.fullName}, ${companion.age}' 
                          : companion.fullName, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis, 
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ),
                    if (companion.accountType == 'verified') ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Colors.blue, size: 18),
                    ],
                  ]),
                ),
                Text('₹${companion.hourlyRate.toInt()}/hr', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryPink)),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [const Icon(Icons.location_on_rounded, color: Colors.grey, size: 16), const SizedBox(width: 4), Text(companion.availableCities.isNotEmpty ? companion.availableCities[0] : 'Mumbai', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13))]),
                Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 20), const SizedBox(width: 4), Text(companion.rating.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14))]),
              ]),
            ]),
          )
        ]),
      ),
    );
  }
}
