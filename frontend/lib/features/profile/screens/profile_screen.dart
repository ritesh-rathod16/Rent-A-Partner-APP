import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/auth/repository/auth_repository.dart';
import 'package:rent_a_partner/features/auth/models/user_model.dart';
import 'package:rent_a_partner/features/companion/models/companion.dart';
import 'package:rent_a_partner/features/companion/repository/companion_repository.dart';
import 'package:rent_a_partner/features/booking/repository/booking_repository.dart';
import 'package:rent_a_partner/features/companion/screens/companion_profile_screen.dart';
import 'package:rent_a_partner/features/admin/screens/admin_dashboard.dart';
import 'package:rent_a_partner/core/utils/image_helper.dart';
import 'package:rent_a_partner/core/api/api_error_handler.dart';

import 'wallet_screen.dart';
import 'terms_conditions_screen.dart';
import 'notifications_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';
import 'get_verified_screen.dart';
import 'trusted_contacts_screen.dart';
import '../../companion/screens/companion_terms_screen.dart';
import '../../companion/screens/companion_dashboard.dart';
import '../../booking/screens/booking_history_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../tracking/screens/emergency_sos_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    if (!mounted) return;
    final ImagePicker picker = ImagePicker();
    XFile? image;
    
    try {
      image = await picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      return;
    }
    
    if (image != null && mounted) {
      CroppedFile? croppedFile;
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Edit Profile Photo',
              toolbarColor: AppColors.primaryPink,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.original,
              ],
            ),
            IOSUiSettings(
              title: 'Edit Profile Photo',
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.original,
              ],
            ),
          ],
        );
      } catch (e) {
        debugPrint('Crop error: $e');
      }

      if (croppedFile != null && mounted) {
        setState(() => _isUploading = true);
        try {
          // Perform upload
          final String filePath = croppedFile.path;
          print('DEBUG_UPLOAD: Starting upload for $filePath');
          
          await ref.read(authRepositoryProvider).uploadPhoto(filePath);
          
          // Refresh user data
          print('DEBUG_UPLOAD: Upload complete, refreshing user');
          final updatedUser = await ref.read(authRepositoryProvider).getMe();
          
          if (mounted) {
            if (updatedUser != null) {
              ref.read(currentUserProvider.notifier).state = updatedUser;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
            } else {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload succeeded but failed to refresh profile.')));
            }
          }
        } catch (e) {
          print('DEBUG_UPLOAD: Error in upload flow: $e');
          if (mounted) {
            final errorMsg = ApiErrorHandler.handle(e);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $errorMsg')));
          }
        } finally {
          if (mounted) setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: const Color(0xFF0F172A),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        Stack(
                          children: [
                            InkWell(
                              onTap: _isUploading ? null : () => _pickAndUploadPhoto(context),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Color(0xFFFF4D8D), shape: BoxShape.circle),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                    ? ImageHelper.getImageProvider(user.photoUrl!)
                                    : null,
                                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                                    ? const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt, color: AppColors.primaryPink),
                                          Text('Upload', style: TextStyle(fontSize: 10, color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
                                        ],
                                      )
                                    : null,
                                ),
                              ),
                            ),
                            if (_isUploading)
                              const Positioned.fill(child: CircularProgressIndicator(color: Colors.white)),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () => _openEditProfile(context, ref),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.edit, size: 16, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        if (user.accountType == 'verified')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified, color: Colors.blue, size: 16),
                              const SizedBox(width: 4),
                              Text('Verified Partner', style: GoogleFonts.inter(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        Text(
                          user.email,
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                        ),
                        if (user.bio != null && user.bio!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 40, right: 40),
                            child: Text(
                              user.bio!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (user.accountType != 'verified')
                          InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GetVerifiedScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: AppColors.primaryPink, borderRadius: BorderRadius.circular(20)),
                              child: const Text('Get Verified Badge', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(user, ref),
                      const SizedBox(height: 32),
                      _sectionTitle('Account Settings'),
                      _buildProfileItem(context, Icons.person_outline, 'Edit Profile', onTap: () => _openEditProfile(context, ref)),
                      _buildProfileItem(context, Icons.history, 'Booking History', target: const BookingHistoryScreen()),
                      _buildProfileItem(context, Icons.favorite_border, 'Saved Partners', onTap: () => _openSavedCompanions(context)),
                      _buildProfileItem(context, Icons.wallet_outlined, 'My Wallet', subtitle: 'Balance: ₹${user.walletBalance}', target: const WalletScreen()),
                      const SizedBox(height: 24),
                      _sectionTitle('Partner Mode'),
                      _buildProfileItem(context, Icons.verified_user_outlined, 'Become a Partner', target: const CompanionTermsScreen()),
                      _buildProfileItem(context, Icons.dashboard_outlined, 'Partner Dashboard', target: const CompanionDashboard()),
                      if (user.email == 'riteshrathod016@gmail.com')
                        _buildProfileItem(context, Icons.admin_panel_settings_outlined, 'Admin Control Panel', target: const AdminDashboard()),
                      const SizedBox(height: 24),
                      _sectionTitle('General'),
                      _buildProfileItem(context, Icons.notifications_none, 'Notifications', target: const NotificationsScreen()),
                      _buildProfileItem(context, Icons.security, 'Privacy & Security', target: const PrivacySecurityScreen()),
                      _buildProfileItem(context, Icons.people_outline, 'Trusted Contacts', target: const TrustedContactsScreen()),
                      _buildProfileItem(context, Icons.description_outlined, 'Terms & Policies', target: const TermsConditionsScreen()),
                      _buildProfileItem(context, Icons.help_outline, 'Help & Support', target: const HelpSupportScreen()),
                      _buildProfileItem(context, Icons.emergency_share_rounded, 'Safety Center (SOS)', target: const EmergencySosScreen(), color: AppColors.primaryPink),
                      const SizedBox(height: 24),
                      _buildProfileItem(context, Icons.logout, 'Logout', color: Colors.red, onTap: () async {
                        await ref.read(authRepositoryProvider).logout();
                        ref.read(currentUserProvider.notifier).state = null; // Clear local state
                        if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                      }),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isUploading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _openEditProfile(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditProfileSheet(ref: ref),
    );
  }

  void _openSavedCompanions(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedCompanionsScreen()));
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.2)),
    );
  }

  Widget _buildStatsRow(UserModel user, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    final bookingCount = bookingsAsync.maybeWhen(
      data: (bookings) => bookings.length,
      orElse: () => 0,
    );

    return Row(
      children: [
        Expanded(child: _statItem('$bookingCount', 'Bookings')),
        Expanded(child: _statItem('${user.favorites.length}', 'Saved')),
        Expanded(child: _statItem('₹${user.walletBalance.toInt()}', 'Balance')),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String title, {Color? color, Widget? target, String? subtitle, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: (color ?? const Color(0xFF0F172A)).withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color ?? const Color(0xFF0F172A), size: 20),
        ),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: color, fontSize: 15)),
        subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.inter(fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: onTap ?? () {
          if (target != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => target));
          }
        },
      ),
    );
  }
}

class EditProfileSheet extends StatefulWidget {
  final WidgetRef ref;
  const EditProfileSheet({super.key, required this.ref});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _dobController;
  late TextEditingController _cityController;
  late TextEditingController _interestsController;
  String _gender = 'Male';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = widget.ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.fullName);
    _bioController = TextEditingController(text: user?.bio);
    _dobController = TextEditingController(text: user?.dob);
    _cityController = TextEditingController(text: user?.city);
    _interestsController = TextEditingController(text: user?.favorites.join(', ')); // Or actual interests field if exists
    _gender = user?.gender ?? 'Male';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dobController,
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now());
                if (date != null) setState(() => _dobController.text = date.toString().split(' ')[0]);
              },
              decoration: const InputDecoration(labelText: 'Date of Birth', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: ['Male', 'Female', 'Other'].contains(_gender) ? _gender : 'Male',
              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
              items: ['Male', 'Female', 'Other']
                  .toSet()
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _gender = v);
              },
            ),
            const SizedBox(height: 16),
            const Text('Interests', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // For simplicity, using a comma separated field or you can implement chips
            TextField(
              controller: _interestsController,
              decoration: const InputDecoration(labelText: 'Interests (comma separated)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSaving ? null : () async {
                  setState(() => _isSaving = true);
                  try {
                    await widget.ref.read(authRepositoryProvider).updateProfile({
                      'full_name': _nameController.text,
                      'city': _cityController.text,
                      'bio': _bioController.text,
                      'dob': _dobController.text,
                      'gender': _gender,
                      'interests': _interestsController.text.split(',').map((e) => e.trim()).toList(),
                    });
                    final updatedUser = await widget.ref.read(authRepositoryProvider).getMe();
                    widget.ref.read(currentUserProvider.notifier).state = updatedUser;
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                  } finally {
                    setState(() => _isSaving = false);
                  }
                },
                child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedCompanionsScreen extends ConsumerWidget {
  const SavedCompanionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final companionsAsync = ref.watch(companionsProvider);

    if (user == null || user.favorites.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Partners')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('No saved partners yet', style: GoogleFonts.inter(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text('Saved Partners', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: companionsAsync.when(
        data: (companions) {
          final savedCompanions = companions.where((c) => user.favorites.contains(c.id)).toList();
          if (savedCompanions.isEmpty) {
            return const Center(child: Text('No saved partners found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: savedCompanions.length,
            itemBuilder: (context, index) => _SavedCompanionCard(companion: savedCompanions[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SavedCompanionCard extends ConsumerWidget {
  final Companion companion;
  const _SavedCompanionCard({required this.companion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: Text(companion.fullName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text(companion.availableCities.join(", "), style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: AppColors.primaryPink),
          onPressed: () async {
            await ref.read(authRepositoryProvider).toggleFavorite(companion.id);
            final updatedUser = await ref.read(authRepositoryProvider).getMe();
            ref.read(currentUserProvider.notifier).state = updatedUser;
          },
        ),
      ),
    );
  }
}
