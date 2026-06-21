import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/models/advertisement.dart';
import '../repository/admin_repository.dart';

import 'package:rent_a_partner/core/utils/image_helper.dart';

class AdsManagementScreen extends ConsumerStatefulWidget {
  const AdsManagementScreen({super.key});

  @override
  ConsumerState<AdsManagementScreen> createState() => _AdsManagementScreenState();
}

class _AdsManagementScreenState extends ConsumerState<AdsManagementScreen> {
  bool _isLoading = false;
  List<Advertisement> _ads = [];

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);
    try {
      final ads = await ref.read(adminRepositoryProvider).getAdvertisements();
      setState(() => _ads = ads);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text('Advertisements', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryPink),
            onPressed: _showCreateAdDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _ads.isEmpty 
          ? Center(child: Text('No advertisements found', style: GoogleFonts.inter(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ads.length,
              itemBuilder: (ctx, i) {
                final ad = _ads[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ImageHelper.buildImage(ad.imageUrl, width: 80, height: 80),
                    ),
                    title: Text(ad.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ad.adType, style: TextStyle(color: AppColors.primaryPink, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Order: ${ad.displayOrder} | Status: ${ad.status}', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteAd(ad.id),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showCreateAdDialog() {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final imageController = TextEditingController();
    final buttonController = TextEditingController(text: 'Explore Now');
    final linkController = TextEditingController();
    final orderController = TextEditingController(text: '0');
    String adType = 'Hero Banner';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create Advertisement', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(titleController, 'Banner Title *'),
                const SizedBox(height: 12),
                _dialogField(subtitleController, 'Banner Subtitle *'),
                const SizedBox(height: 12),
                _dialogField(imageController, 'Image URL *'),
                const SizedBox(height: 12),
                _dialogField(buttonController, 'Button Text'),
                const SizedBox(height: 12),
                _dialogField(linkController, 'Redirect URL'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: ['Hero Banner', 'Featured Companion', 'Offer', 'Announcement', 'Full Width'].contains(adType) ? adType : 'Hero Banner',
                  decoration: const InputDecoration(labelText: 'Ad Type'),
                  items: ['Hero Banner', 'Featured Companion', 'Offer', 'Announcement', 'Full Width']
                      .toSet()
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => adType = v);
                  },
                ),
                const SizedBox(height: 12),
                _dialogField(orderController, 'Display Order', keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                          if (date != null) setDialogState(() => startDate = date);
                        },
                        child: Text('Start: ${DateFormat('dd MMM').format(startDate)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                          if (date != null) setDialogState(() => endDate = date);
                        },
                        child: Text('End: ${DateFormat('dd MMM').format(endDate)}'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || imageController.text.isEmpty) return;
                try {
                  await ref.read(adminRepositoryProvider).createAdvertisement({
                    'title': titleController.text,
                    'subtitle': subtitleController.text,
                    'image_url': imageController.text,
                    'button_text': buttonController.text,
                    'redirect_link': linkController.text,
                    'ad_type': adType,
                    'display_order': int.tryParse(orderController.text) ?? 0,
                    'status': 'active',
                    'start_date': startDate.toIso8601String(),
                    'end_date': endDate.toIso8601String(),
                  });
                  Navigator.pop(ctx);
                  _loadAds();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              child: const Text('Create Ad'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController c, String l, {TextInputType? keyboardType}) {
    return TextField(controller: c, keyboardType: keyboardType, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder()));
  }

  Future<void> _deleteAd(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ad'),
        content: const Text('Remove this advertisement?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(adminRepositoryProvider).deleteAdvertisement(id);
      _loadAds();
    }
  }
}
