import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/tracking/repository/safety_repository.dart';

import 'package:url_launcher/url_launcher_string.dart';

class TrustedContactsScreen extends ConsumerStatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  ConsumerState<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends ConsumerState<TrustedContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await ref.read(safetyRepositoryProvider).getTrustedContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addContact() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String relation = 'Friend';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Trusted Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: relation,
                isExpanded: true,
                items: ['Mother', 'Father', 'Friend', 'Spouse', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setDialogState(() => relation = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );

    if (confirm == true && nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
      try {
        await ref.read(safetyRepositoryProvider).addTrustedContact({
          'name': nameController.text,
          'phone': phoneController.text,
          'relation': relation,
        });
        _loadContacts();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _showEditDialog(Map<String, dynamic> contact) async {
    final nameController = TextEditingController(text: contact['name']);
    final phoneController = TextEditingController(text: contact['phone']);
    String relation = contact['relation'] ?? 'Friend';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Trusted Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: relation,
                isExpanded: true,
                items: ['Mother', 'Father', 'Friend', 'Spouse', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setDialogState(() => relation = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        // Since we don't have a specific edit endpoint, we can delete and add, or update logic
        await ref.read(safetyRepositoryProvider).removeTrustedContact(contact['phone']);
        await ref.read(safetyRepositoryProvider).addTrustedContact({
          'name': nameController.text,
          'phone': phoneController.text,
          'relation': relation,
        });
        _loadContacts();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  void _deleteContact(Map<String, dynamic> contact) async {
    try {
      await ref.read(safetyRepositoryProvider).removeTrustedContact(contact['phone']);
      _loadContacts();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact removed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text('Trusted Contacts', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Emergency Alert System', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Your trusted contacts will be automatically notified via SMS and Email whenever you trigger the SOS button.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 32),
              ..._contacts.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: AppColors.softPink, child: Text(c['name'][0], style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold))),
                  title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${c['relation']} • ${c['phone']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => _showEditDialog(c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone_enabled_rounded, color: Colors.green),
                        onPressed: () => launchUrlString('tel:${c['phone']}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red), 
                        onPressed: () => _deleteContact(c),
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addContact,
                icon: const Icon(Icons.add),
                label: const Text('ADD NEW CONTACT'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
    );
  }
}
