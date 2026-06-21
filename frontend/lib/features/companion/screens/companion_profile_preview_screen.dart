import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/companion.dart';
import '../../../core/theme/app_theme.dart';
import '../repository/companion_repository.dart';
import 'package:rent_a_partner/core/utils/image_helper.dart';

class CompanionProfilePreviewScreen extends ConsumerStatefulWidget {
  final Companion companion;
  const CompanionProfilePreviewScreen({super.key, required this.companion});

  @override
  ConsumerState<CompanionProfilePreviewScreen> createState() => _CompanionProfilePreviewScreenState();
}

class _CompanionProfilePreviewScreenState extends ConsumerState<CompanionProfilePreviewScreen> {
  late TextEditingController _bioController;
  late TextEditingController _rateController;
  late TextEditingController _cityController;
  late TextEditingController _availabilityController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.companion.bio);
    _rateController = TextEditingController(text: widget.companion.hourlyRate.toString());
    _cityController = TextEditingController(text: widget.companion.availableCities.join(', '));
    _availabilityController = TextEditingController(text: widget.companion.availabilityHours);
  }

  void _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(companionRepositoryProvider).updateCompanionProfile({
        'bio': _bioController.text,
        'hourly_rate': double.parse(_rateController.text),
        'available_cities': _cityController.text.split(',').map((e) => e.trim()).toList(),
        'availability_hours': _availabilityController.text,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateMainPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        await ref.read(companionRepositoryProvider).uploadCompanionPhoto(image.path);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo updated!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  void _removePhoto(String url) async {
    try {
      await ref.read(companionRepositoryProvider).removeGalleryPhoto(url);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo removed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Widget _addGalleryItem() {
    return InkWell(
      onTap: () async {
        final picker = ImagePicker();
        final images = await picker.pickMultiImage();
        if (images.isNotEmpty) {
           await ref.read(companionRepositoryProvider).uploadGallery(images.map((e) => e.path).toList());
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photos uploaded!')));
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
        child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile Preview'),
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _isEditing = true))
          else if (_isSaving)
            const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 350,
                  width: double.infinity,
                  child: ImageHelper.buildImage(widget.companion.photos.isNotEmpty ? widget.companion.photos[0] : ''),
                ),
                Container(
                  height: 350,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent])
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    top: 20, right: 20,
                    child: FloatingActionButton.small(
                      onPressed: _updateMainPhoto,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                Positioned(
                  bottom: 30,
                  left: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.companion.fullName, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      if (!_isEditing)
                        Text('₹${widget.companion.hourlyRate}/hr', style: GoogleFonts.inter(fontSize: 18, color: AppColors.primaryPink, fontWeight: FontWeight.bold))
                      else
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _rateController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Hourly Rate', labelStyle: TextStyle(color: Colors.white)),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                    ],
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing) ...[
                    _editField(_cityController, 'Available Cities (comma separated)'),
                    const SizedBox(height: 16),
                    _editField(_availabilityController, 'Availability (e.g. 10AM - 8PM)'),
                    const SizedBox(height: 16),
                  ],
                  _buildSection('Quick Stats', [
                    _detailRow('Age', widget.companion.age.toString()),
                    _detailRow('Gender', widget.companion.gender),
                    _detailRow('Height', widget.companion.height ?? "N/A"),
                    _detailRow('Occupation', widget.companion.occupation ?? "N/A"),
                    _detailRow('Trust Score', '${widget.companion.trustScore}%'),
                  ]),
                  const SizedBox(height: 32),
                  Text('About Me', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (!_isEditing)
                    Text(widget.companion.bio, style: const TextStyle(height: 1.5, fontSize: 15))
                  else
                    TextField(
                      controller: _bioController,
                      maxLines: 5,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  const SizedBox(height: 32),
                  _buildSection('Professional Info', [
                    _detailRow('Hourly Rate', '₹${widget.companion.hourlyRate.toInt()}/hr'),
                    _detailRow('Cities', widget.companion.availableCities.join(', ')),
                    _detailRow('Languages', widget.companion.languages.join(', ')),
                    _detailRow('Availability', widget.companion.availabilityHours),
                  ]),
                  const SizedBox(height: 32),
                  _buildSection('Identity & Safety', [
                    _detailRow('ID Type', widget.companion.idType),
                    _detailRow('ID Verified', widget.companion.isIdentityVerified ? 'YES' : 'Pending'),
                    _detailRow('Account Type', widget.companion.accountType.toUpperCase()),
                  ]),
                  const SizedBox(height: 32),
                  Text('Gallery', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.companion.photos.length + (_isEditing ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i == widget.companion.photos.length) {
                          return _addGalleryItem();
                        }
                        return Stack(
                          children: [
                            Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ImageHelper.buildImage(widget.companion.photos[i], fit: BoxFit.cover),
                              ),
                            ),
                            if (_isEditing)
                              Positioned(
                                top: 4, right: 16,
                                child: InkWell(
                                  onTap: () => _removePhoto(widget.companion.photos[i]),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              )
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Interests', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: widget.companion.interests.map((it) => Chip(label: Text(it))).toList()),
                  const SizedBox(height: 32),
                  _buildSection('Application Details', [
                    _detailRow('Status', widget.companion.status.toUpperCase()),
                    _detailRow('Joined', widget.companion.createdAt?.toLocal().toString().split(' ')[0] ?? 'N/A'),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
          child: Column(children: rows),
        )
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _editField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}
