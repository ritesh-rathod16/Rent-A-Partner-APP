import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/companion/models/companion.dart';
import 'package:rent_a_partner/features/admin/repository/admin_repository.dart';
import 'package:rent_a_partner/core/utils/image_helper.dart';

class ApplicationReviewScreen extends ConsumerStatefulWidget {
  final Companion application;
  const ApplicationReviewScreen({super.key, required this.application});

  @override
  ConsumerState<ApplicationReviewScreen> createState() => _ApplicationReviewScreenState();
}

class _ApplicationReviewScreenState extends ConsumerState<ApplicationReviewScreen> {
  bool _isProcessing = false;

  void _handleApprove() async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(adminRepositoryProvider).approveApplication(widget.application.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application Approved!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _handleReject() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Enter reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true && reasonController.text.isNotEmpty) {
      setState(() => _isProcessing = true);
      try {
        await ref.read(adminRepositoryProvider).rejectApplication(widget.application.id, reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application Rejected')));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Review Application'),
        actions: [
          if (_isProcessing)
            const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())
          else ...[
            IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: _handleReject),
            IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _handleApprove),
          ]
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Personal Information'),
            _infoCard([
              _detailRow('Application ID', app.id),
              _detailRow('Full Name', app.fullName),
              _detailRow('Email', app.email),
              _detailRow('Phone', app.phoneNumber),
              _detailRow('Gender', app.gender),
              _detailRow('Age', app.age.toString()),
              _detailRow('DOB', app.dob ?? "N/A"),
              _detailRow('Occupation', app.occupation ?? "N/A"),
            ]),
            const SizedBox(height: 24),
            _sectionHeader('Professional Details'),
            _infoCard([
              _detailRow('Hourly Rate', '₹${app.hourlyRate}/hr'),
              _detailRow('Availability', app.availabilityHours),
              _detailRow('Cities', app.availableCities.join(", ")),
              _detailRow('Languages', app.languages.join(", ")),
              _detailRow('Interests', app.interests.join(", ")),
            ]),
            const SizedBox(height: 24),
            _sectionHeader('Address'),
            _infoCard([
              _detailRow('Current', app.currentAddress ?? "N/A"),
              _detailRow('Permanent', app.permanentAddress ?? "N/A"),
              _detailRow('State', app.state ?? "N/A"),
            ]),
            const SizedBox(height: 24),
            _sectionHeader('Bio'),
            _infoCard([
              Text(app.bio, style: GoogleFonts.inter(height: 1.5)),
            ]),
            const SizedBox(height: 24),
            _sectionHeader('Verification Documents'),
            _documentGrid(),
            const SizedBox(height: 24),
            _sectionHeader('Profile Gallery'),
            _photoGallery(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _handleReject,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                child: const Text('REJECT'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleApprove,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('APPROVE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _documentGrid() {
    final app = widget.application;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _docItem('ID Front', app.idUrl),
        _docItem('ID Back', app.idBackUrl),
        _docItem('Live Selfie', app.liveSelfieUrl),
        _docItem('Payment QR', app.paymentQrUrl ?? ""),
      ],
    );
  }

  Widget _docItem(String label, String url) {
    return InkWell(
      onTap: () => _viewImage(url, label),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (url.isNotEmpty && url != "Not Provided")
              Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: ImageHelper.buildImage(url, width: double.infinity, fit: BoxFit.cover)))
            else
              const Expanded(child: Center(child: Text('Not Uploaded', style: TextStyle(fontSize: 10, color: Colors.grey)))),
            Padding(padding: const EdgeInsets.all(8.0), child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _photoGallery() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.application.photos.length,
        itemBuilder: (ctx, i) => InkWell(
          onTap: () => _viewImage(widget.application.photos[i], 'Profile Photo ${i+1}'),
          child: Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: ImageHelper.buildImage(widget.application.photos[i], fit: BoxFit.cover)),
          ),
        ),
      ),
    );
  }

  void _viewImage(String url, String title) {
    if (url.isEmpty || url == "Not Provided") return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(child: ImageHelper.buildImage(url)),
            ),
            Positioned(top: 40, left: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx))),
          ],
        ),
      ),
    );
  }
}
