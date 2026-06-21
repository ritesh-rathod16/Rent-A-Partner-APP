class Message {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String type; // text, image
  final DateTime timestamp;
  final bool isMe;
  final bool isRead;
  final bool isLiked;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.type = 'text',
    required this.timestamp,
    required this.isMe,
    this.isRead = false,
    this.isLiked = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      text: json['text'] ?? '',
      imageUrl: json['image_url'],
      type: json['type'] ?? 'text',
      timestamp: DateTime.parse(json['timestamp'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      isMe: json['is_me'] ?? false,
      isRead: json['is_read'] ?? false,
      isLiked: json['is_liked'] ?? false,
    );
  }
}
