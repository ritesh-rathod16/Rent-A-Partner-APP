import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final trackingRepositoryProvider = Provider((ref) => TrackingRepository(ref.read(apiClientProvider)));

class TrackingRepository {
  final ApiClient _apiClient;
  TrackingRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> getBookingPath(String bookingId) async {
    final response = await _apiClient.get('/tracking/booking/$bookingId');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> updateLocation(String userId, String bookingId, double lat, double lng) async {
    await _apiClient.post('/tracking/update', data: {
      'user_id': userId,
      'booking_id': bookingId,
      'lat': lat,
      'lng': lng,
    });
  }
}
