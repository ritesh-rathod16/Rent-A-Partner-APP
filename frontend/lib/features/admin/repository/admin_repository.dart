import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rent_a_partner/core/api/api_client.dart';
import 'package:rent_a_partner/features/companion/models/companion.dart';
import 'package:rent_a_partner/features/auth/models/user_model.dart'; 
import 'package:rent_a_partner/features/admin/models/payment_model.dart';
import 'package:rent_a_partner/features/booking/models/booking_model.dart';
import 'package:rent_a_partner/features/home/models/advertisement.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository(ref.read(apiClientProvider)));

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository(this._apiClient);

  Future<Map<String, dynamic>> getStats() async {
    final response = await _apiClient.get('/admin/stats');
    return response.data ?? {};
  }

  Future<List<Companion>> getPendingApplications() async {
    final response = await _apiClient.get('/admin/applications');
    if (response.data == null) return [];
    return (response.data as List).map((e) => Companion.fromJson(e)).toList();
  }

  Future<Companion> getApplicationDetails(String id) async {
    final response = await _apiClient.get('/admin/applications/$id');
    return Companion.fromJson(response.data);
  }

  Future<void> approveApplication(String id) async {
    await _apiClient.post('/admin/applications/$id/approve');
  }

  Future<void> rejectApplication(String id, String reason) async {
    await _apiClient.post('/admin/applications/$id/reject', data: {'reason': reason});
  }

  Future<void> deleteApplication(String id) async {
    await _apiClient.delete('/admin/applications/$id');
  }

  Future<List<UserModel>> getUsers() async {
    final response = await _apiClient.get('/admin/users');
    if (response.data == null) return [];
    return (response.data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> updateUserStatus(String id, String status) async {
    await _apiClient.post('/admin/users/$id/status', data: {'status': status});
  }

  Future<void> deleteUser(String id) async {
    await _apiClient.delete('/admin/users/$id');
  }

  Future<void> banUser(String id) async {
    await _apiClient.post('/admin/users/$id/ban');
  }

  Future<void> suspendUser(String id) async {
    await _apiClient.post('/admin/users/$id/suspend');
  }

  Future<List<Payment>> getPayments() async {
    final response = await _apiClient.get('/admin/payments');
    if (response.data == null) return [];
    return (response.data as List).map((e) => Payment.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getPerformanceData() async {
    final response = await _apiClient.get('/admin/performance');
    return response.data ?? {};
  }

  Future<List<Booking>> getActiveBookings() async {
    final response = await _apiClient.get('/admin/bookings/active');
    if (response.data == null) return [];
    return (response.data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<List<Booking>> getBookingLogs() async {
    final response = await _apiClient.get('/admin/bookings/logs');
    if (response.data == null) return [];
    return (response.data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getSOSAlerts() async {
    final response = await _apiClient.get('/admin/sos/alerts');
    if (response.data == null) return [];
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> resolveSOS(String id) async {
    await _apiClient.post('/admin/sos/$id/resolve');
  }

  Future<void> resolveReport(String id) async {
    await _apiClient.post('/admin/reports/$id/resolve');
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    final response = await _apiClient.get('/admin/reports');
    if (response.data == null) return [];
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getStatements() async {
    final response = await _apiClient.get('/admin/statements');
    if (response.data == null) return [];
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> deleteStatement(String id) async {
    await _apiClient.delete('/admin/statements/$id');
  }

  Future<void> flagStatement(String id) async {
    await _apiClient.post('/admin/statements/$id/flag');
  }

  Future<Map<String, dynamic>> getVerificationSettings() async {
    final response = await _apiClient.get('/admin/settings/verification');
    return response.data ?? {};
  }

  Future<void> updateVerificationSettings(Map<String, dynamic> data) async {
    await _apiClient.patch('/admin/settings/verification', data: data);
  }

  Future<List<Map<String, dynamic>>> getDetailedSOSAlerts() async {
    final response = await _apiClient.get('/safety/sos/all'); // Need this backend endpoint
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> sendNotification(Map<String, dynamic> data) async {
    await _apiClient.post('/admin/notifications/send', data: data); 
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    final response = await _apiClient.get('/admin/notifications/history');
    if (response.data == null) return [];
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> verifyUserBadge(String userId, String action) async {
    await _apiClient.post('/admin/users/$userId/verify', data: {'action': action});
  }

  Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    await _apiClient.post('/admin/settings/update', data: settings);
  }

  Future<Map<String, dynamic>> sendBulkEmail(String subject, String message) async {
    final response = await _apiClient.post('/admin/send-email-all', data: {
      'subject': subject,
      'message': message,
    });
    return response.data ?? {};
  }

  Future<Booking> getBookingById(String id) async {
    final response = await _apiClient.get('/admin/bookings/$id');
    if (response.data == null) throw Exception('Booking not found');
    return Booking.fromJson(response.data);
  }

  // Advertisement Management
  Future<List<Advertisement>> getAdvertisements() async {
    final response = await _apiClient.get('/ads/all');
    if (response.data == null) return [];
    return (response.data as List).map((e) => Advertisement.fromJson(e)).toList();
  }

  Future<void> createAdvertisement(Map<String, dynamic> data) async {
    await _apiClient.post('/ads/create', data: data);
  }

  Future<void> deleteAdvertisement(String id) async {
    await _apiClient.delete('/ads/$id');
  }
}
