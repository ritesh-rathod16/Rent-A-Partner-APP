import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../auth/repository/auth_repository.dart';
import '../models/message_model.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository(ref.read(apiClientProvider), ref));

final messagesProvider = StreamProvider.family<List<Message>, String>((ref, peerId) async* {
  while (true) {
    try {
      final msgs = await ref.read(chatRepositoryProvider).getMessages(peerId);
      yield msgs;
    } catch (e) {
      // Log error but keep stream alive
    }
    await Future.delayed(const Duration(seconds: 3));
  }
});

class ChatRepository {
  final ApiClient _apiClient;
  final Ref _ref;

  ChatRepository(this._apiClient, this._ref);

  Future<List<Message>> getMessages(String peerId) async {
    final response = await _apiClient.get('/chat/messages/$peerId');
    final currentUserId = _ref.read(currentUserProvider)?.id;
    
    return (response.data as List).map((e) {
      final map = Map<String, dynamic>.from(e);
      map['is_me'] = map['sender_id'] == currentUserId;
      // Map created_at to timestamp if needed by model
      map['timestamp'] = map['created_at']; 
      return Message.fromJson(map);
    }).toList();
  }

  Future<void> sendMessage(String peerId, String text, {String? imageUrl, String type = 'text'}) async {
    final response = await _apiClient.post('/chat/send', data: {
      'recipient_id': peerId,
      'text': text,
      'image_url': imageUrl,
      'type': type,
    });
    if (response.data['success'] == false) {
      throw response.data['message'] ?? 'Message failed to send';
    }
  }

  Future<String?> uploadImage(String filePath) async {
    final res = await _apiClient.postMultipart('/chat/upload-image', filePath, 'file');
    if (res.data['success'] == true) {
      return res.data['image_url'];
    }
    return null;
  }

  Future<void> toggleLike(String messageId) async {
    await _apiClient.post('/chat/message/$messageId/like');
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    final response = await _apiClient.get('/chat/conversations');
    return List<Map<String, dynamic>>.from(response.data);
  }
}

final conversationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(chatRepositoryProvider).getConversations();
});
