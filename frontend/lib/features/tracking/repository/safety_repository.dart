import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final safetyRepositoryProvider = Provider((ref) => SafetyRepository(ref.read(apiClientProvider)));

class SafetyRepository {
  final ApiClient _apiClient;
  SafetyRepository(this._apiClient);

  Future<void> triggerSOS(String? bookingId, {double lat = 0.0, double lng = 0.0}) async {
    await _apiClient.post('/safety/sos/trigger', data: {
      'booking_id': bookingId,
      'location': {'lat': lat, 'lng': lng},
    });
  }

  Future<void> fileReport(Map<String, dynamic> reportData) async {
    final reportedUserId = reportData['reported_user_id'];
    print("Reporting user: $reportedUserId");
    print('API_LOG: Filing report with payload: $reportData');
    final response = await _apiClient.post('/safety/report', data: reportData);
    print('API_LOG: Report response: ${response.data}');
  }

  Future<List<Map<String, dynamic>>> getTrustedContacts() async {
    final response = await _apiClient.get('/safety/contacts');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> addTrustedContact(Map<String, dynamic> contact) async {
    await _apiClient.post('/safety/contacts/add', data: contact);
  }

  Future<void> removeTrustedContact(String phone) async {
    await _apiClient.delete('/safety/contacts', data: {'phone': phone});
  }

  Future<void> sendCheckIn(String bookingId, String status) async {
    await _apiClient.post('/safety/session/check-in', data: {
      'booking_id': bookingId,
      'status': status,
    });
  }

  Future<void> uploadPanicRecording(String sosId, String filePath) async {
    await _apiClient.postMultipart('/safety/sos/$sosId/upload-recording', filePath, 'file');
  }
}
