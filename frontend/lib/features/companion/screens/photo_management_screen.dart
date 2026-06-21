import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import '../repository/companion_repository.dart';

class PhotoManagementScreen extends ConsumerStatefulWidget {
  const PhotoManagementScreen({super.key});

  @override
  ConsumerState<PhotoManagementScreen> createState() => _PhotoManagementScreenState();
}

class _PhotoManagementScreenState extends ConsumerState<PhotoManagementScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  List<String> _currentPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  void _loadPhotos() async {
    try {
      final companion = await ref.read(companionRepositoryProvider).getMyCompanionProfile();
      setState(() {
        _currentPhotos = List<String>.from(companion.photos);
      });
    } catch (e) {
      debugPrint('Failed to load photos: $e');
    }
  }

  Future<void> _addPhoto() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _currentPhotos.addAll(images.map((image) => image.path));
      });
    }
  }

  void _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      // In real scenario, we should upload local paths first to get URLs
      // For this implementation, we assume URLs or handle upload in repository
      await ref.read(companionRepositoryProvider).updatePhotos(_currentPhotos);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photos updated successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Manage Gallery', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkNavy,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
          if (!_isSaving)
            TextButton(onPressed: _saveChanges, child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: _currentPhotos.length + 1,
        itemBuilder: (context, index) {
          if (index == _currentPhotos.length) {
            return InkWell(
              onTap: _addPhoto,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
              ),
            );
          }
          final photo = _currentPhotos[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: photo.startsWith('http') 
                  ? Image.network(photo, fit: BoxFit.cover)
                  : Image.file(File(photo), fit: BoxFit.cover),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => setState(() => _currentPhotos.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
