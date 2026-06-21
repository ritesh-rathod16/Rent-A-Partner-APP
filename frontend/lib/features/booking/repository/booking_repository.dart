import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/booking_model.dart';

final bookingRepositoryProvider = Provider((ref) => BookingRepository(ref.read(apiClientProvider)));

final myBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  return ref.read(bookingRepositoryProvider).getMyBookings();
});

final activeSessionProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(bookingRepositoryProvider).getActiveSession();
});

class BookingRepository {
  final ApiClient _apiClient;

  BookingRepository(this._apiClient);

  Future<Map<String, dynamic>> createBooking(String companionId, String date, String time, int duration, String activity, double amount, String customerId) async {
    final response = await _apiClient.post('/bookings/create', data: {
      'companion_id': companionId,
      'date': date,
      'time': time,
      'duration_hours': duration,
      'activity_type': activity,
      'total_amount': amount,
      'customer_id': customerId,
    });
    if (response.data['success'] == false) {
      throw response.data['message'] ?? 'Booking creation failed';
    }
    return response.data;
  }

  Future<void> confirmBooking(String bookingId, String paymentId, String signature) async {
    await _apiClient.post('/bookings/confirm', data: {
      'booking_id': bookingId,
      'payment_id': paymentId,
      'signature': signature,
    });
  }

  Future<List<Booking>> getMyBookings() async {
    final response = await _apiClient.get('/bookings/my-bookings');
    return (response.data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    final response = await _apiClient.get('/bookings/active-session');
    if (response.data == null) return null;
    return Map<String, dynamic>.from(response.data);
  }
}
