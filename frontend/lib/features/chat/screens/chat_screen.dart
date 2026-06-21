import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rent_a_partner/core/theme/app_theme.dart';
import 'package:rent_a_partner/features/booking/models/booking_model.dart';
import 'package:rent_a_partner/features/chat/models/message_model.dart';
import 'package:rent_a_partner/features/chat/repository/chat_repository.dart';
import '../../../core/utils/image_helper.dart';
import '../../auth/repository/auth_repository.dart';
import 'chat_settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String peerName;
  final String peerId;
  final String? peerPhoto;
  final Booking? booking;
  const ChatScreen({super.key, required this.peerName, required this.peerId, this.peerPhoto, this.booking});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;
    final text = _msgController.text.trim();
    _msgController.clear();
    
    final user = ref.read(currentUserProvider);
    if (user?.email != 'riteshrathod016@gmail.com') {
      final phoneRegex = RegExp(r'\d{10}');
      if (phoneRegex.hasMatch(text) || text.toLowerCase().contains('pay') || text.toLowerCase().contains('upi')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ Contact/Payment info sharing is blocked for safety.'),
          backgroundColor: Colors.red,
        ));
        return;
      }
    }

    try {
      await ref.read(chatRepositoryProvider).sendMessage(widget.peerId, text);
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      try {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Uploading image...'),
          duration: Duration(seconds: 2),
        ));
        
        final imageUrl = await ref.read(chatRepositoryProvider).uploadImage(image.path);
        
        if (imageUrl != null) {
          await ref.read(chatRepositoryProvider).sendMessage(widget.peerId, '', imageUrl: imageUrl, type: 'image');
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.peerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leadingWidth: 40,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18, 
              backgroundColor: AppColors.softPink, 
              backgroundImage: (widget.peerPhoto != null && widget.peerPhoto!.isNotEmpty)
                ? ImageHelper.getImageProvider(widget.peerPhoto!)
                : null,
              child: (widget.peerPhoto == null || widget.peerPhoto!.isEmpty) 
                ? const Icon(Icons.person, color: AppColors.primaryPink, size: 20) 
                : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(widget.peerName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkNavy), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 14),
                    ],
                  ),
                  const Text('Online', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.booking != null) ...[
            IconButton(
              icon: const Icon(Icons.call_outlined, color: AppColors.darkNavy), 
              onPressed: () => _showCallPlaceholder('Voice'),
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined, color: AppColors.darkNavy), 
              onPressed: () => _showCallPlaceholder('Video'),
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.darkNavy),
            onSelected: (v) {
              if (v == 'report') _showReportDialog();
              if (v == 'settings') Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatSettingsScreen()));
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'settings', child: Text('Chat Settings')),
              const PopupMenuItem(value: 'report', child: Text('Report User', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.booking != null) _buildPinnedBookingCard(),
          Expanded(
            child: messagesAsync.when(
              data: (msgs) => ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(20),
                itemCount: msgs.length,
                itemBuilder: (ctx, i) => _buildMessageBubble(msgs[msgs.length - 1 - i]),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildPinnedBookingCard() {
    final b = widget.booking!;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Booking #${b.id.substring(b.id.length - 6).toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(b.status.toUpperCase(), style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bookingMiniInfo(Icons.calendar_today, b.date),
              _bookingMiniInfo(Icons.access_time, b.time),
              _bookingMiniInfo(Icons.star_outline, b.activity),
            ],
          )
        ],
      ),
    );
  }

  Widget _bookingMiniInfo(IconData i, String t) {
    return Row(
      children: [
        Icon(i, color: Colors.white60, size: 14),
        const SizedBox(width: 6),
        Text(t, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  Widget _buildMessageBubble(Message msg) {
    final timeStr = DateFormat('hh:mm a').format(msg.timestamp);
    final bool isImage = msg.type == 'image';
    
    return GestureDetector(
      onDoubleTap: () => ref.read(chatRepositoryProvider).toggleLike(msg.id),
      child: Align(
        alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(isImage ? 4 : 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: msg.isMe ? AppColors.primaryPink : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: msg.isMe ? const Radius.circular(20) : Radius.zero,
              bottomRight: msg.isMe ? Radius.zero : const Radius.circular(20),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ImageHelper.buildImage(msg.imageUrl ?? '', width: double.infinity, fit: BoxFit.cover),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(msg.text, style: GoogleFonts.inter(color: msg.isMe ? Colors.white : Colors.black87, height: 1.4)),
                    ),
                  if (msg.isLiked)
                    Positioned(
                      bottom: isImage ? 8 : -8,
                      right: isImage ? 8 : -8,
                      child: const CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.favorite, color: Colors.red, size: 10),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 4, right: isImage ? 8 : 0, bottom: isImage ? 4 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(timeStr, style: TextStyle(color: msg.isMe ? (isImage ? Colors.white70 : Colors.white60) : Colors.grey, fontSize: 9)),
                    if (msg.isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        msg.isRead ? Icons.done_all : Icons.done, 
                        color: msg.isRead ? (isImage ? Colors.white : Colors.blue) : (isImage ? Colors.white54 : Colors.white60), 
                        size: 12
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.grey), 
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primaryPink,
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: _sendMessage),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Harassment', 'Fraud', 'Inappropriate Behavior', 'Safety Concern']
              .map((reason) => ListTile(title: Text(reason), onTap: () { Navigator.pop(ctx); }))
              .toList(),
        ),
      ),
    );
  }

  void _showCallPlaceholder(String type) {
    final bool isSessionActive = widget.booking?.status.toLowerCase() == 'active';
    
    if (isSessionActive) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Starting $type call with ${widget.peerName}...'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚠️ $type calling will be active once both partners join the session.'),
        backgroundColor: AppColors.primaryPink,
      ));
    }
  }
}
