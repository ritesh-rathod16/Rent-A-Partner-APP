import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/companion/repository/companion_repository.dart';
import 'package:rent_a_partner/features/auth/repository/auth_repository.dart';

class ApplyCompanionScreen extends ConsumerStatefulWidget {
  const ApplyCompanionScreen({super.key});

  @override
  ConsumerState<ApplyCompanionScreen> createState() => _ApplyCompanionScreenState();
}

class _ApplyCompanionScreenState extends ConsumerState<ApplyCompanionScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _checkingStatus = true;
  String? _existingStatus;
  final ImagePicker _picker = ImagePicker();

  // Form Controllers
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _heightController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _instaController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _stateController = TextEditingController();
  final _occupationController = TextEditingController();
  final _bioController = TextEditingController();
  final _rateController = TextEditingController();
  final _citiesController = TextEditingController();
  final _hoursController = TextEditingController();
  final _upiController = TextEditingController();

  String _gender = 'Female';
  final List<File> _photos = [];
  final List<String> _selectedInterests = [];
  final List<String> _selectedCategories = [];
  final List<String> _selectedLanguages = [];
  
  String _idType = 'Aadhaar';
  File? _idImage;
  File? _idBackImage;
  File? _selfieImage;
  File? _qrImage;

  final List<String> _languageOptions = ['English', 'Hindi', 'Marathi'];
  final List<String> _categoryOptions = [
    'Event Partner', 'Shopping Companion', 'Movie Partner', 'Coffee Meetups', 
    'Study Partner', 'Fitness Buddy', 'Party & Wedding', 'Networking Partner'
  ];
  final List<String> _interestSuggestions = [
    'Traveling', 'Music', 'Gaming', 'Fitness', 'Cooking', 'Art', 'Reading', 'Movies', 'Sports'
  ];

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
  }

  Future<void> _checkApplicationStatus() async {
    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      if (user != null && user.isCompanion) {
        setState(() { _existingStatus = 'approved'; _checkingStatus = false; });
        return;
      }
      // Check if there is a pending application
      final repo = ref.read(companionRepositoryProvider);
      final profile = await repo.getCompanionStats().catchError((_) => <String, dynamic>{});
      if (profile.isNotEmpty) {
         // This is a simplified check
      }
      setState(() { _checkingStatus = false; });
    } catch (e) {
      setState(() { _checkingStatus = false; });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty && _dobController.text.isNotEmpty && 
               _heightController.text.isNotEmpty && _phoneController.text.isNotEmpty && 
               _emailController.text.isNotEmpty && _selectedLanguages.isNotEmpty &&
               _occupationController.text.isNotEmpty;
      case 1:
        return _currentAddressController.text.isNotEmpty && _permanentAddressController.text.isNotEmpty &&
               _stateController.text.isNotEmpty;
      case 2:
        return _bioController.text.isNotEmpty && _selectedInterests.isNotEmpty && 
               _selectedCategories.isNotEmpty && _photos.length >= 5;
      case 3:
        return _rateController.text.isNotEmpty && _citiesController.text.isNotEmpty && _hoursController.text.isNotEmpty;
      case 4:
        return _idImage != null && _idBackImage != null && _selfieImage != null;
      case 5:
        return _qrImage != null;
      default:
        return false;
    }
  }

  void _showOtherLanguageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Other Language'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Enter language')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (controller.text.isNotEmpty) {
              setState(() { _selectedLanguages.add(controller.text); });
              Navigator.pop(ctx);
            }
          }, child: const Text('Add')),
        ],
      ),
    );
  }

  Future<void> _pickImage(bool isGallery, {bool isPhotos = false, bool isId = false, bool isSelfie = false, bool isQR = false}) async {
    if (isGallery && isPhotos) {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _photos.addAll(images.map((image) => File(image.path)));
        });
      }
      return;
    }

    final XFile? image = await _picker.pickImage(source: isGallery ? ImageSource.gallery : ImageSource.camera);
    if (image != null) {
      setState(() {
        if (isPhotos) _photos.add(File(image.path));
        else if (isId) {
          if (_idImage == null) _idImage = File(image.path);
          else _idBackImage = File(image.path);
        }
        else if (isSelfie) _selfieImage = File(image.path);
        else if (isQR) _qrImage = File(image.path);
      });
    }
  }

  void _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User session expired. Please login again.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        "user_id": user.id,
        "full_name": _nameController.text,
        "dob": _dobController.text,
        "height": _heightController.text,
        "gender": _gender,
        "phone_number": _phoneController.text,
        "email": _emailController.text,
        "instagram_id": _instaController.text,
        "occupation": _occupationController.text,
        "languages": _selectedLanguages,
        "current_address": _currentAddressController.text,
        "permanent_address": _permanentAddressController.text,
        "state": _stateController.text,
        "bio": _bioController.text,
        "interests": _selectedInterests,
        "service_categories": _selectedCategories,
        "photos": _photos.map((e) => e.path).toList(),
        "hourly_rate": double.parse(_rateController.text),
        "available_cities": _citiesController.text.split(',').map((e) => e.trim()).toList(),
        "availability_hours": _hoursController.text,
        "id_type": _idType,
        "id_url": _idImage?.path ?? "",
        "id_back_url": _idBackImage?.path ?? "",
        "live_selfie_url": _selfieImage?.path ?? "",
        "payment_qr_url": _qrImage?.path ?? "",
        "upi_id": _upiController.text,
      };

      await ref.read(companionRepositoryProvider).submitApplication(data);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Application Submitted'),
            content: const Text('Your application is under review. Please wait for the admin to approve your profile.'),
            actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (e is Exception) {
          errorMsg = e.toString().replaceAll('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingStatus) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_existingStatus == 'approved') {
      return Scaffold(
        appBar: AppBar(title: const Text('Become a Partner')),
        body: const Center(child: Text('You are already a verified companion!')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Become a Partner', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
        backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: AppColors.darkNavy),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryPink)),
        child: Stepper(
          type: StepperType.horizontal,
          elevation: 0,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_validateCurrentStep()) {
              if (_currentStep < 5) setState(() => _currentStep++);
              else _submit();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required information to proceed')));
            }
          },
          onStepCancel: () { if (_currentStep > 0) setState(() => _currentStep--); },
          steps: [
            Step(isActive: _currentStep >= 0, title: const Text('Basic', style: TextStyle(fontSize: 10)), content: _buildBasicInfo()),
            Step(isActive: _currentStep >= 1, title: const Text('Address', style: TextStyle(fontSize: 10)), content: _buildAddressInfo()),
            Step(isActive: _currentStep >= 2, title: const Text('Profile', style: TextStyle(fontSize: 10)), content: _buildProfileInfo()),
            Step(isActive: _currentStep >= 3, title: const Text('Pro', style: TextStyle(fontSize: 10)), content: _buildProfessionalInfo()),
            Step(isActive: _currentStep >= 4, title: const Text('Verify', style: TextStyle(fontSize: 10)), content: _buildVerificationInfo()),
            Step(isActive: _currentStep >= 5, title: const Text('Pay', style: TextStyle(fontSize: 10)), content: _buildPaymentInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
        _customField(_nameController, 'Full Name *', Icons.person_outline),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _customField(_dobController, 'Date of Birth *', Icons.calendar_today, readOnly: true, onTap: () async {
            DateTime? picked = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now());
            if (picked != null) _dobController.text = picked.toString().split(' ')[0];
          })),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: ['Male', 'Female', 'Other'].contains(_gender) ? _gender : 'Male',
              decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.people_outline)),
              items: ['Male', 'Female', 'Other']
                  .toSet()
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _gender = v);
              },
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _customField(_heightController, 'Height (e.g. 5\'8") *', Icons.height)),
          const SizedBox(width: 16),
          Expanded(child: _customField(_phoneController, 'Phone Number *', Icons.phone_outlined, keyboardType: TextInputType.phone)),
        ]),
        const SizedBox(height: 16),
        _customField(_emailController, 'Email Address *', Icons.email_outlined),
        const SizedBox(height: 16),
        _customField(_occupationController, 'Occupation *', Icons.work_outline),
        const SizedBox(height: 16),
        const Text('Languages Spoken *', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(spacing: 8, children: [
          ..._languageOptions.map((lang) => FilterChip(
            label: Text(lang), selected: _selectedLanguages.contains(lang),
            onSelected: (v) => setState(() { if (v) _selectedLanguages.add(lang); else _selectedLanguages.remove(lang); }),
          )),
          ActionChip(label: const Text('+ Other'), onPressed: _showOtherLanguageDialog),
        ]),
        const SizedBox(height: 16),
        _customField(_instaController, 'Instagram ID (Optional)', Icons.camera_alt_outlined),
      ],
    );
  }

  Widget _buildAddressInfo() {
    return Column(children: [
      _customField(_currentAddressController, 'Current Address *', Icons.location_on_outlined, maxLines: 2),
      const SizedBox(height: 16),
      _customField(_permanentAddressController, 'Permanent Address *', Icons.home_outlined, maxLines: 2),
      const SizedBox(height: 16),
      _customField(_stateController, 'State *', Icons.map_outlined),
    ]);
  }

  Widget _buildProfileInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _customField(_bioController, 'Bio *', Icons.info_outline, maxLines: 3),
      const SizedBox(height: 16),
      const Text('Interests *', style: TextStyle(fontWeight: FontWeight.bold)),
      Wrap(spacing: 8, children: _interestSuggestions.map((it) => FilterChip(
        label: Text(it), selected: _selectedInterests.contains(it),
        onSelected: (v) => setState(() { if (v) _selectedInterests.add(it); else _selectedInterests.remove(it); }),
      )).toList()),
      const SizedBox(height: 16),
      const Text('Category Preferences *', style: TextStyle(fontWeight: FontWeight.bold)),
      Wrap(spacing: 8, children: _categoryOptions.map((it) => FilterChip(
        label: Text(it), selected: _selectedCategories.contains(it),
        onSelected: (v) => setState(() { if (v) _selectedCategories.add(it); else _selectedCategories.remove(it); }),
      )).toList()),
      const SizedBox(height: 16),
      Text('Photos (Minimum 5 required, current: ${_photos.length}) *', style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      SizedBox(height: 100, child: ListView.builder(
        scrollDirection: Axis.horizontal, itemCount: _photos.length + 1,
        itemBuilder: (ctx, i) => i == _photos.length ? _addPhotoCard() : _photoCard(_photos[i]),
      )),
    ]);
  }

  Widget _buildProfessionalInfo() {
    return Column(children: [
      _customField(_rateController, 'Hourly Rate (₹) *', Icons.payments_outlined, keyboardType: TextInputType.number),
      const SizedBox(height: 16),
      _customField(_citiesController, 'Available Cities (Comma separated) *', Icons.location_city_outlined),
      const SizedBox(height: 16),
      _customField(_hoursController, 'Availability Hours *', Icons.access_time),
    ]);
  }

  Widget _buildVerificationInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Identity Proof *', style: TextStyle(fontWeight: FontWeight.bold)),
      Row(children: [
        Radio<String>(value: 'Aadhaar', groupValue: _idType, onChanged: (v) => setState(() => _idType = v!)), const Text('Aadhaar'),
        const SizedBox(width: 20),
        Radio<String>(value: 'DL', groupValue: _idType, onChanged: (v) => setState(() => _idType = v!)), const Text('DL'),
      ]),
      _uploadTile('Upload ID Front *', Icons.badge_outlined, () => _showPickerOptions(false, isId: true), isUploaded: _idImage != null),
      const SizedBox(height: 16),
      _uploadTile('Upload ID Back *', Icons.badge_outlined, () => _showPickerOptions(false, isId: true), isUploaded: _idBackImage != null),
      const SizedBox(height: 16),
      _uploadTile('Take a Selfie *', Icons.face, () => _pickImage(false, isSelfie: true), isUploaded: _selfieImage != null),
    ]);
  }

  Widget _buildPaymentInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Payment Details *', style: TextStyle(fontWeight: FontWeight.bold)),
      _uploadTile('Upload Payment QR *', Icons.qr_code, () => _showPickerOptions(false, isQR: true), isUploaded: _qrImage != null),
      const SizedBox(height: 16),
      _customField(_upiController, 'UPI ID (Optional)', Icons.account_balance_wallet_outlined),
      if (_isLoading) const Center(child: CircularProgressIndicator()),
    ]);
  }

  Widget _addPhotoCard() => InkWell(onTap: () => _showPickerOptions(true), child: Container(width: 100, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: const Icon(Icons.add_a_photo, color: Colors.grey)));
  Widget _photoCard(File file) => Container(width: 100, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(file), fit: BoxFit.cover)), child: Align(alignment: Alignment.topRight, child: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _photos.remove(file)))));
  Widget _uploadTile(String t, IconData i, VoidCallback o, {bool isUploaded = false}) => ListTile(onTap: o, leading: Icon(i, color: isUploaded ? Colors.green : AppColors.primaryPink), title: Text(t), trailing: Icon(isUploaded ? Icons.check_circle : Icons.arrow_forward_ios, size: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)));
  void _showPickerOptions(bool isP, {bool isId = false, bool isQR = false}) => showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Wrap(children: [ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () { Navigator.pop(ctx); _pickImage(true, isPhotos: isP, isId: isId, isQR: isQR); }), ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () { Navigator.pop(ctx); _pickImage(false, isPhotos: isP, isId: isId, isQR: isQR); })])));
  Widget _customField(TextEditingController c, String l, IconData i, {TextInputType? keyboardType, int maxLines = 1, bool readOnly = false, VoidCallback? onTap}) => TextFormField(controller: c, keyboardType: keyboardType, maxLines: maxLines, readOnly: readOnly, onTap: onTap, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
}
