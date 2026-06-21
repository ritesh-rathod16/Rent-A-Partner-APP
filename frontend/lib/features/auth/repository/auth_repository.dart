import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.read(apiClientProvider)));

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

class AuthRepository {
  final ApiClient _apiClient;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this._apiClient);

  Future<void> register(String name, String email, String phone, String city, String dob, String gender, String password) async {
    final response = await _apiClient.post('/auth/register', data: {
      'full_name': name,
      'email': email,
      'phone_number': phone,
      'city': city,
      'dob': dob,
      'gender': gender,
      'password': password,
    });

    if (response.data['success'] == false) {
      throw response.data['message'] ?? 'Registration failed';
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    final response = await _apiClient.post('/auth/verify-otp', data: {
      'email': email,
      'otp': otp,
    });
    
    if (response.data['success'] == false) {
      throw response.data['message'] ?? 'OTP verification failed';
    }

    String token = response.data['access_token'];
    await _storage.write(key: 'token', value: token);
    return true;
  }

  Future<Map<String, dynamic>> login(String email, {String? password}) async {
    final response = await _apiClient.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    
    if (response.data['success'] == false) {
      throw response.data['message'] ?? 'Login failed';
    }

    if (response.data['require_otp'] == false) {
      String token = response.data['access_token'];
      await _storage.write(key: 'token', value: token);
    }
    
    return response.data;
  }

  Future<UserModel?> getMe() async {
    try {
      final response = await _apiClient.get('/auth/me');
      return UserModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _apiClient.post('/auth/update-profile', data: data);
  }

  Future<void> uploadPhoto(String filePath) async {
    await _apiClient.postMultipart('/auth/update-photo', filePath, 'file');
  }

  Future<void> toggleFavorite(String companionId) async {
    await _apiClient.post('/auth/favorites/toggle', data: {'companion_id': companionId});
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }

  Future<bool> isLoggedIn() async {
    String? token = await _storage.read(key: 'token');
    return token != null;
  }
}
