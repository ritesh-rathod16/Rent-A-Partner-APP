import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/auth/screens/login_screen.dart';
import 'package:rent_a_partner/features/admin/repository/admin_repository.dart';
import 'package:rent_a_partner/features/companion/models/companion.dart';
import 'package:rent_a_partner/features/auth/models/user_model.dart';
import 'package:rent_a_partner/features/booking/models/booking_model.dart';
import 'package:rent_a_partner/features/admin/models/payment_model.dart';
import 'package:rent_a_partner/features/admin/screens/ads_management_screen.dart';
import 'package:rent_a_partner/features/admin/screens/application_review_screen.dart';
import 'package:rent_a_partner/features/tracking/screens/tracking_screen.dart';
import 'package:rent_a_partner/features/chat/screens/chat_screen.dart';
import '../../../core/utils/image_helper.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  int _selectedIndex = 0;
  List<Companion> _pendingApplications = [];
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  List<Payment> _payments = [];
  List<Booking> _activeBookings = [];
  List<Booking> _bookingLogs = [];
  List<Map<String, dynamic>> _statements = [];
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _performance;
  bool _isLoading = true;
  String? _errorMessage;
  
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _emailSubjectController = TextEditingController();
  final TextEditingController _emailMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _userSearchController.addListener(_filterUsers);
  }

  void _filterUsers() {
    final query = _userSearchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user.fullName.toLowerCase().contains(query) || 
               user.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final repo = ref.read(adminRepositoryProvider);
      
      final results = await Future.wait([
        repo.getStats().catchError((e) => <String, dynamic>{}),
        repo.getPendingApplications().catchError((e) => <Companion>[]),
        repo.getUsers().catchError((e) => <UserModel>[]),
        repo.getPayments().catchError((e) => <Payment>[]),
        repo.getPerformanceData().catchError((e) => <String, dynamic>{}),
        repo.getActiveBookings().catchError((e) => <Booking>[]),
        repo.getBookingLogs().catchError((e) => <Booking>[]),
        repo.getStatements().catchError((e) => <Map<String, dynamic>>[]),
        repo.getReports().catchError((e) => <Map<String, dynamic>>[]),
        repo.getDetailedSOSAlerts().catchError((e) => <Map<String, dynamic>>[]),
      ]);
      
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _pendingApplications = results[1] as List<Companion>;
        _users = results[2] as List<UserModel>;
        _filteredUsers = _users;
        _payments = results[3] as List<Payment>;
        _performance = results[4] as Map<String, dynamic>;
        _activeBookings = results[5] as List<Booking>;
        _bookingLogs = results[6] as List<Booking>;
        _statements = results[7] as List<Map<String, dynamic>>;
        _reports = results[8] as List<Map<String, dynamic>>;
        _sosAlerts = results[9] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  List<Map<String, dynamic>> _sosAlerts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text('Admin Control', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.primaryPink), onPressed: _loadData),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to connect to server', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                  child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _loadData, child: const Text('Try Again')),
              ],
            ))
          : _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: AppColors.darkNavy,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF020617)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(radius: 35, backgroundColor: AppColors.primaryPink, child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 30)),
                    const SizedBox(height: 12),
                    Text('Admin Portal', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(Icons.dashboard_rounded, 'Dashboard', 0),
                  _drawerItem(Icons.group_rounded, 'User Management', 1),
                  _drawerItem(Icons.verified_user_rounded, 'Companion Apps', 2),
                  _drawerItem(Icons.location_searching_rounded, 'Active Bookings', 3),
                  _drawerItem(Icons.history_rounded, 'Booking Logs', 4),
                  _drawerItem(Icons.account_balance_wallet_rounded, 'Revenue', 5),
                  _drawerItem(Icons.campaign_rounded, 'Ads Management', 6),
                  _drawerItem(Icons.alternate_email_rounded, 'Bulk Email', 7),
                  _drawerItem(Icons.notifications_active_rounded, 'Notification Center', 8),
                  _drawerItem(Icons.chat_rounded, 'Admin Chat', 9),
                  _drawerItem(Icons.verified_rounded, 'Verification Config', 10),
                  _drawerItem(Icons.emergency_share_rounded, 'SOS Alerts', 11),
                  _drawerItem(Icons.report_problem_rounded, 'User Reports', 12),
                  _drawerItem(Icons.receipt_long_rounded, 'Statements', 13),
                  _drawerItem(Icons.settings_suggest_rounded, 'System Settings', 14),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.white70)),
              onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    bool selected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.white : Colors.white54),
      title: Text(title, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      selectedTileColor: AppColors.primaryPink,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _dashboardHome();
      case 1: return _userManagement();
      case 2: return _companionApplications();
      case 3: return _activeBookingsView();
      case 4: return _bookingLogsView();
      case 5: return _revenueAnalytics();
      case 6: return const AdsManagementScreen();
      case 7: return _bulkEmailView();
      case 8: return _notificationCenterView();
      case 9: return _adminChatView();
      case 10: return _verificationConfigView();
      case 11: return _sosAlertsView();
      case 12: return _reportsView();
      case 13: return _statementsView();
      case 14: return _systemSettingsView();
      default: return _dashboardHome();
    }
  }

  Widget _adminChatView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              hintText: 'Search companions to chat...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primaryPink),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredUsers.length,
            itemBuilder: (ctx, i) {
              final user = _filteredUsers[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.softPink,
                    backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty) 
                        ? ImageHelper.getImageProvider(user.photoUrl!) 
                        : null,
                    child: (user.photoUrl == null || user.photoUrl!.isEmpty) 
                        ? const Icon(Icons.person, color: AppColors.primaryPink) 
                        : null,
                  ),
                  title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user.isCompanion ? 'Companion' : 'User'),
                  trailing: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryPink),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                      peerName: user.fullName,
                      peerId: user.id,
                      peerPhoto: user.photoUrl,
                    )));
                  },
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _notificationCenterView() {
    final titleController = TextEditingController();
    final msgController = TextEditingController();
    String target = 'all';

    return StatefulBuilder(
      builder: (context, setNotifState) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notification Center', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _infoCard([
              const Text('Send To:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: target,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All Users')),
                  const DropdownMenuItem(value: 'verified', child: Text('Verified Users Only')),
                  const DropdownMenuItem(value: 'companions', child: Text('Companions Only')),
                ],
                onChanged: (v) => setNotifState(() => target = v!),
              ),
              const SizedBox(height: 16),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Notification Title', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: msgController, maxLines: 4, decoration: const InputDecoration(labelText: 'Message Body', border: OutlineInputBorder())),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || msgController.text.isEmpty) return;
                  try {
                    await ref.read(adminRepositoryProvider).sendNotification({
                      'title': titleController.text,
                      'message': msgController.text,
                      'target': target,
                    });
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications sent successfully!')));
                    titleController.clear();
                    msgController.clear();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                },
                child: const Text('SEND BROADCAST'),
              ),
            ),
            const SizedBox(height: 48),
            Text('Notification History', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ref.read(adminRepositoryProvider).getNotificationHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final history = snapshot.data ?? [];
                return Column(
                  children: history.map((h) => Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text(h['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${h['message']}\nTarget: ${h['target']} | Recipients: ${h['recipient_count']}'),
                      trailing: Text(h['status']?.toString() ?? 'Delivered', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                      isThreeLine: true,
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sosAlertsView() {
    if (_sosAlerts.isEmpty) return const Center(child: Text('No active SOS alerts'));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sosAlerts.length,
      itemBuilder: (ctx, i) {
        final a = _sosAlerts[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Colors.red.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CRITICAL SOS: ${a['_id'].toString().substring(a['_id'].toString().length - 6)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    _statusChip(a['status']?.toString() ?? 'ACTIVE'),
                  ],
                ),
                const Divider(),
                _detailRow('User', a['user_name']?.toString() ?? 'N/A'),
                _detailRow('Phone', a['user_phone']?.toString() ?? 'N/A'),
                _detailRow('IP Address', a['ip_address']?.toString() ?? 'Unknown'),
                _detailRow('Timestamp', a['triggered_at']?.toString() ?? 'N/A'),
                const SizedBox(height: 12),
                const Text('Trusted Contacts:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ...(a['trusted_contacts'] as List? ?? []).map((c) => Text('• ${c['name']}: ${c['phone']} (${c['relation']})', style: const TextStyle(fontSize: 11))),
                const SizedBox(height: 12),
                const Text('Panic Recordings:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ...(a['recordings'] as List? ?? []).map((r) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.play_circle_fill, color: Colors.blue),
                  title: const Text('Evidence Recording', style: TextStyle(fontSize: 11)),
                  onTap: () => launchUrlString(r.toString()),
                )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (a['booking_id'] != null && a['booking_id'] != "null" && a['booking_id'].toString().isNotEmpty)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(bookingId: a['booking_id'].toString()))),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('TRACK LIVE'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        )
                      ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                      onPressed: () async {
                         await ref.read(adminRepositoryProvider).resolveSOS(a['_id'].toString());
                         _loadData();
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dashboardHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Overview', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _statCard('Total Users', _stats?['total_users']?.toString() ?? '0', Icons.people_alt, Colors.blue),
              _statCard('Total Companions', _stats?['total_companions']?.toString() ?? '0', Icons.star_rounded, Colors.orange),
              _statCard('SOS Alerts', _stats?['active_sos']?.toString() ?? '0', Icons.emergency_share, Colors.red),
              _statCard('User Reports', _stats?['pending_reports']?.toString() ?? '0', Icons.report_gmailerrorred_rounded, Colors.redAccent),
              _statCard('Total Revenue', "₹${_stats?['total_revenue']?.toString() ?? '0'}", Icons.payments_rounded, Colors.purple),
              _statCard('Active Bookings', _stats?['active_bookings']?.toString() ?? '0', Icons.calendar_today_rounded, Colors.green),
              _statCard('Withdrawals', _stats?['withdrawal_requests']?.toString() ?? '0', Icons.account_balance_wallet_rounded, Colors.deepOrange),
            ],
          ),
          const SizedBox(height: 32),
          Text('Recent Platform Alerts', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...(_stats?['recent_alerts'] as List? ?? []).map((a) {
            if (a == null || a is! Map) return const SizedBox.shrink();
            final bool isSOS = a['type'] == 'SOS';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSOS ? Colors.red.shade50 : Colors.white, 
                borderRadius: BorderRadius.circular(16),
                border: isSOS ? Border.all(color: Colors.red.withValues(alpha: 0.3)) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSOS ? Icons.emergency_share_rounded : Icons.info_outline_rounded, 
                    color: isSOS ? Colors.red : Colors.blue, 
                    size: 24
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['title']?.toString() ?? 'Alert', style: TextStyle(fontWeight: FontWeight.bold, color: isSOS ? Colors.red : Colors.black87)),
                        Text(a['body']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                  if (isSOS && a['booking_id'] != null && a['booking_id'] != "null" && a['booking_id'].toString().isNotEmpty)
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(bookingId: a['booking_id'].toString()))),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
                          child: const Text('TRACK', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                          onPressed: () async {
                            await ref.read(adminRepositoryProvider).resolveSOS(a['_id'].toString());
                            _loadData();
                          },
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
          Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickAction(Icons.campaign_rounded, 'Post Ad', () => setState(() => _selectedIndex = 6)),
              _quickAction(Icons.email_rounded, 'Blast Email', () => setState(() => _selectedIndex = 7)),
              _quickAction(Icons.verified_rounded, 'Verification', () => setState(() => _selectedIndex = 10)),
              _quickAction(Icons.settings_rounded, 'Settings', () => setState(() => _selectedIndex = 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: AppColors.primaryPink),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _userManagement() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primaryPink),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _filteredUsers.isEmpty 
            ? const Center(child: Text('No users found'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, i) {
                  final user = _filteredUsers[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${user.email}\nStatus: ${user.status.toUpperCase()}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${user.walletBalance.toInt()}'),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (val) {
                              if (val == 'verify' || val == 'unverify') {
                                _handleUserAction(user.id, val == 'verify' ? 'verify' : 'unverify');
                              } else {
                                _handleUserAction(user.id, val);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'active', child: Text('Active')),
                              const PopupMenuItem(value: 'suspended', child: Text('Suspend')),
                              const PopupMenuItem(value: 'banned', child: Text('Ban')),
                              PopupMenuItem(
                                value: user.accountType == 'verified' ? 'unverify' : 'verify',
                                child: Text(user.accountType == 'verified' ? 'Remove Badge' : 'Grant Verified Badge'),
                              ),
                              const PopupMenuItem(value: 'delete', child: Text('Delete Account', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _showUserDetails(user),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('User Profile', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _detailRow('Account ID', user.id),
              _detailRow('Full Name', user.fullName),
              _detailRow('Email Address', user.email),
              _detailRow('City', user.city),
              _detailRow('Date of Birth', user.dob),
              _detailRow('Gender', user.gender),
              _detailRow('Account Status', user.status.toUpperCase()),
              _detailRow('Wallet Balance', '₹${user.walletBalance}'),
              _detailRow('Companion Status', user.isCompanion ? 'Verified Partner' : 'Standard User'),
              if (user.bio != null) _detailRow('Bio', user.bio!),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(child: ElevatedButton(onPressed: () => _handleUserAction(user.id, 'suspended'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkNavy), child: const Text('Suspend'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () => _handleUserAction(user.id, 'delete'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Delete'))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUserAction(String id, String action) async {
    try {
      if (action == 'delete') {
        await ref.read(adminRepositoryProvider).deleteUser(id);
      } else if (action == 'verify' || action == 'unverify') {
        await ref.read(adminRepositoryProvider).verifyUserBadge(id, action == 'verify' ? 'verify' : 'remove');
      } else {
        await ref.read(adminRepositoryProvider).updateUserStatus(id, action);
      }
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }

  Widget _companionApplications() {
    if (_pendingApplications.isEmpty) return const Center(child: Text('No pending applications at the moment'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingApplications.length,
      itemBuilder: (context, i) {
        final app = _pendingApplications[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.softPink,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: ImageHelper.buildImage(
                  app.photos.isNotEmpty ? app.photos[0] : '',
                  width: 60, height: 60,
                ),
              ),
            ),
            title: Text(app.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Rate: ₹${app.hourlyRate.toInt()}/hr | ${app.availableCities.join(", ")}'),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryPink),
            onTap: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicationReviewScreen(application: app)));
              if (result == true) _loadData();
            },
          ),
        );
      },
    );
  }

  Widget _activeBookingsView() {
    if (_activeBookings.isEmpty) return const Center(child: Text('No active bookings currently'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeBookings.length,
      itemBuilder: (context, i) {
        final b = _activeBookings[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active ID: ${b.id.length > 6 ? b.id.substring(b.id.length - 6) : b.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
                  _statusChip(b.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.people_rounded, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text('${b.customerName} ↔ ${b.companionName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 20, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(b.companionLat != null ? '${b.companionLat!.toStringAsFixed(4)}, ${b.companionLng!.toStringAsFixed(4)}' : 'No location data'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bookingLogsView() {
    if (_bookingLogs.isEmpty) return const Center(child: Text('No past booking logs found'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookingLogs.length,
      itemBuilder: (context, i) {
        final b = _bookingLogs[i];
        return Card(
          child: ListTile(
            title: Text('${b.customerName} ↔ ${b.companionName}'),
            subtitle: Text('${b.date} | Total: ₹${b.totalAmount.toInt()}'),
            trailing: _statusChip(b.status),
          ),
        );
      },
    );
  }

  Widget _revenueAnalytics() {
    final topEarners = _performance?['top_earners'] as List? ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _statCard('Volume', '₹${(_performance?['total_revenue'] ?? 0).toInt()}', Icons.wallet, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _statCard('Commission', '₹${(_performance?['platform_commission'] ?? 0).toInt()}', Icons.pie_chart, Colors.blue)),
            ],
          ),
          const SizedBox(height: 32),
          Text('Top Performing Partners', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...topEarners.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.softPink, child: Icon(Icons.person, color: AppColors.primaryPink)),
              title: Text(e['name']?.toString() ?? 'Partner', style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('₹${(e['earnings'] ?? 0).toInt()}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          )),
          const SizedBox(height: 32),
          Text('Recent Transactions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._payments.take(10).map((p) => Card(
            child: ListTile(
              title: Text('₹${p.amount.toInt()}'),
              subtitle: Text('From ${p.userName} to ${p.companionName}'),
              trailing: _statusChip(p.status),
            ),
          )),
        ],
      ),
    );
  }

  Widget _bulkEmailView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Send Bulk Announcement', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(controller: _emailSubjectController, decoration: const InputDecoration(labelText: 'Email Subject', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _emailMessageController, maxLines: 8, decoration: const InputDecoration(labelText: 'Body Message', border: OutlineInputBorder())),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _sendEmails, child: const Text('Send To All Users'))),
        ],
      ),
    );
  }

  Future<void> _sendEmails() async {
    if (_emailSubjectController.text.isEmpty || _emailMessageController.text.isEmpty) return;
    try {
      final res = await ref.read(adminRepositoryProvider).sendBulkEmail(_emailSubjectController.text, _emailMessageController.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Blast Sent! ${res['sent']} Successful, ${res['failed']} Failed.')));
      _emailSubjectController.clear();
      _emailMessageController.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Blast Failed: $e')));
    }
  }

  Widget _verificationConfigView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(adminRepositoryProvider).getVerificationSettings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data ?? {};
        
        final priceController = TextEditingController(text: data['verification_price']?.toString() ?? '499');
        final descController = TextEditingController(text: data['description'] ?? 'Upgrade to get verified badge');
        final benefitController = TextEditingController();
        List<String> benefits = List<String>.from(data['benefits'] ?? []);

        return StatefulBuilder(
          builder: (context, setConfigState) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verification Badge Settings', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _infoCard([
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Verification Fee (₹)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                ]),
                const SizedBox(height: 32),
                Text('Verification Benefits', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...benefits.map((b) => ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(b),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {
                    setConfigState(() => benefits.remove(b));
                  }),
                )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: benefitController, decoration: const InputDecoration(hintText: 'Add new benefit'))),
                    const SizedBox(width: 12),
                    IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primaryPink), onPressed: () {
                      if (benefitController.text.isNotEmpty) {
                        setConfigState(() {
                          benefits.add(benefitController.text);
                          benefitController.clear();
                        });
                      }
                    }),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await ref.read(adminRepositoryProvider).updateVerificationSettings({
                          'verification_price': int.parse(priceController.text),
                          'description': descController.text,
                          'benefits': benefits,
                        });
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuration saved successfully!')));
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                      }
                    },
                    child: const Text('Save Configuration'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statementsView() {
    if (_statements.isEmpty) return const Center(child: Text('No system statements found'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _statements.length,
      itemBuilder: (context, i) {
        final s = _statements[i];
        final bool isFlagged = s['is_flagged'] ?? false;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: isFlagged ? Colors.red.shade50 : Colors.white, borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text('Ref: ${s['_id'].toString().substring(s['_id'].length > 8 ? s['_id'].length - 8 : 0)}'),
            subtitle: Text('${s['user_name'] ?? 'System'} | ${s['date']}\nStatus: ${s['status'] ?? 'Completed'}'),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.flag_rounded, color: isFlagged ? Colors.red : Colors.orange), onPressed: () => _flagStatement(s['_id'].toString())),
                IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent), onPressed: () => _deleteStatement(s['_id'].toString())),
              ],
            ),
            onTap: () => _viewStatementDetail(s),
          ),
        );
      },
    );
  }

  void _viewStatementDetail(Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transaction Details'),
        content: Text(s['content']?.toString() ?? 'No transaction description available.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
      ),
    );
  }

  Future<void> _flagStatement(String id) async {
    await ref.read(adminRepositoryProvider).flagStatement(id);
    _loadData();
  }

  Future<void> _deleteStatement(String id) async {
    await ref.read(adminRepositoryProvider).deleteStatement(id);
    _loadData();
  }

  Widget _reportsView() {
    if (_reports.isEmpty) return const Center(child: Text('No user reports currently'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, i) {
        final r = _reports[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: AppColors.softPink, child: Icon(Icons.report_gmailerrorred_rounded, color: Colors.red)),
            title: Text('Report against: ${r['reported_name']?.toString() ?? 'Unknown'}'),
            subtitle: Text('Reason: ${r['reason']?.toString() ?? 'N/A'}\nBy: ${r['reporter_name']?.toString() ?? 'Anonymous'}'),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'ban') _handleUserAction(r['reported_user_id'].toString(), 'ban');
                if (val == 'suspend') _handleUserAction(r['reported_user_id'].toString(), 'suspended');
                if (val == 'resolve') {
                  await ref.read(adminRepositoryProvider).resolveReport(r['_id'].toString());
                  _loadData();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'warn', child: Text('Warn User')),
                const PopupMenuItem(value: 'suspend', child: Text('Suspend User')),
                const PopupMenuItem(value: 'ban', child: Text('Ban User', style: TextStyle(color: Colors.red))),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'resolve', child: Text('Mark Resolved', style: TextStyle(color: Colors.green))),
              ],
            ),
            onTap: () => _showReportDetail(r),
          ),
        );
      },
    );
  }

  void _showReportDetail(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Detail'),
        content: Text(r['description']?.toString() ?? 'No additional details provided.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          TextButton(onPressed: () {}, child: const Text('Take Action', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _systemSettingsView() {
    final commissionController = TextEditingController(text: '25');
    final depositController = TextEditingController(text: '5');
    final withdrawalController = TextEditingController(text: '500');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Settings', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _settingEditField('Platform Commission (%)', commissionController),
          _settingEditField('Security Deposit (%)', depositController),
          _settingEditField('Minimum Withdrawal (₹)', withdrawalController),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(adminRepositoryProvider).updateSystemSettings({
                    'commission': commissionController.text,
                    'deposit': depositController.text,
                    'min_withdrawal': withdrawalController.text,
                  });
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('System settings updated!')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                }
              },
              child: const Text('Save System Config'),
            ),
          ),
          const SizedBox(height: 48),
          Text('Emergency Controls', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, elevation: 0),
            child: const Text('Maintenance Mode'),
          ),
        ],
      ),
    );
  }

  Widget _settingEditField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.edit, size: 16),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.orange;
    if (['captured', 'success', 'confirmed', 'completed', 'approved', 'active'].contains(status.toLowerCase())) color = Colors.green;
    if (['failed', 'cancelled', 'rejected', 'banned', 'suspended'].contains(status.toLowerCase())) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
            ),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    final displayValue = (value == null || value.trim().isEmpty || value == "null" || value == "N/A") ? "Not Provided" : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 24),
          Expanded(child: Text(displayValue, textAlign: TextAlign.right, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkNavy))),
        ],
      ),
    );
  }
}
