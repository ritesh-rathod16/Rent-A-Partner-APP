import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/companion.dart';

final companionRepositoryProvider = Provider((ref) => CompanionRepository(ref.read(apiClientProvider)));

final companionsProvider = FutureProvider<List<Companion>>((ref) async {
  return ref.read(companionRepositoryProvider).getCompanions();
});

class CompanionRepository {
  final ApiClient _apiClient;

  CompanionRepository(this._apiClient);

  Future<List<Companion>> getCompanions({String? city, String? category}) async {
    final response = await _apiClient.get('/companions/list', queryParameters: {
      if (city != null) 'city': city,
      if (category != null) 'category': category,
    });
    
    return (response.data as List).map((e) => Companion.fromJson(e)).toList();
  }

  Future<void> submitApplication(Map<String, dynamic> data) async {
    try {
      // 1. Upload photos if they are local paths
      final List<String> localPhotos = List<String>.from(data['photos']).where((p) => !p.startsWith('http')).toList();
      if (localPhotos.isNotEmpty) {
        final List<String> uploadedPhotoUrls = await uploadGallery(localPhotos);
        data['photos'] = uploadedPhotoUrls;
      }

      // 2. Upload ID Front
      if (data['id_url'] != null && data['id_url'].isNotEmpty && !data['id_url'].startsWith('http')) {
        data['id_url'] = await uploadCompanionPhoto(data['id_url']);
      }
      
      // 3. Upload ID Back
      if (data['id_back_url'] != null && data['id_back_url'].isNotEmpty && !data['id_back_url'].startsWith('http')) {
        data['id_back_url'] = await uploadCompanionPhoto(data['id_back_url']);
      }

      // 4. Upload Selfie
      if (data['live_selfie_url'] != null && data['live_selfie_url'].isNotEmpty && !data['live_selfie_url'].startsWith('http')) {
        data['live_selfie_url'] = await uploadCompanionPhoto(data['live_selfie_url']);
      }

      // 5. Upload QR
      if (data['payment_qr_url'] != null && data['payment_qr_url'].isNotEmpty && !data['payment_qr_url'].startsWith('http')) {
        data['payment_qr_url'] = await uploadCompanionPhoto(data['payment_qr_url']);
      }

      await _apiClient.post('/companions/apply', data: data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        final message = e.response?.data['detail'] ?? 'Failed to submit application';
        throw Exception(message);
      }
      rethrow;
    }
  }

  Future<Companion> getCompanionDetails(String id) async {
    final response = await _apiClient.get('/companions/profile/$id');
    return Companion.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getCompanionStats() async {
    final response = await _apiClient.get('/companions/stats');
    return response.data;
  }

  Future<Companion> getMyCompanionProfile() async {
    final response = await _apiClient.get('/companions/my-profile');
    return Companion.fromJson(response.data);
  }

  Future<void> toggleAvailability() async {
    await _apiClient.post('/companions/toggle-availability');
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await _apiClient.post('/companions/update-settings', data: settings);
  }

  Future<void> updateRates(double rate) async {
    await _apiClient.post('/companions/update-rates', data: {'hourly_rate': rate});
  }

  Future<void> setAvailability(String hours) async {
    await _apiClient.post('/companions/update-availability', data: {'availability_hours': hours});
  }

  Future<void> updateCompanionProfile(Map<String, dynamic> data) async {
    await _apiClient.patch('/companions/profile', data: data);
  }

  Future<String> uploadCompanionPhoto(String filePath) async {
    final response = await _apiClient.postMultipart('/companions/upload-photo', filePath, 'file');
    return response.data['photo_url'];
  }

  Future<List<String>> uploadGallery(List<String> filePaths) async {
    final res = await _apiClient.postMultipleFiles('/companions/upload-gallery', filePaths, 'files');
    if (res.data['urls'] != null) return List<String>.from(res.data['urls']);
    return [];
  }

  Future<void> removeGalleryPhoto(String url) async {
    await _apiClient.delete('/companions/gallery', data: {'url': url});
  }

  Future<void> updatePhotos(List<String> photos) async {
    await _apiClient.patch('/companions/profile', data: {'photos': photos});
  }
}
