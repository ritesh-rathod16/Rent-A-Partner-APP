import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.read(apiClientProvider)));

class SettingsRepository {
  final ApiClient _apiClient;
  SettingsRepository(this._apiClient);

  Future<Map<String, bool>> getPrivacySettings() async {
    final response = await _apiClient.get('/user/privacy-settings');
    return Map<String, bool>.from(response.data);
  }

  Future<void> updatePrivacySettings(Map<String, bool> settings) async {
    await _apiClient.patch('/user/privacy-settings', data: settings);
  }

  Future<void> changePassword(String current, String newPass) async {
    await _apiClient.post('/user/change-password', data: {
      'current_password': current,
      'new_password': newPass,
    });
  }

  Future<List<Map<String, dynamic>>> getConnectedDevices() async {
    final response = await _apiClient.get('/user/connected-devices');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> logoutDevice(String deviceId) async {
    await _apiClient.delete('/user/connected-devices/$deviceId');
  }

  Future<void> deactivateAccount() async {
    await _apiClient.post('/user/deactivate-account');
  }

  Future<void> enable2FA() async {
    await _apiClient.post('/user/2fa/enable');
  }

  Future<void> verify2FA(String otp) async {
    await _apiClient.post('/user/2fa/verify', data: {'otp': otp});
  }

  Future<void> disable2FA() async {
    await _apiClient.post('/user/2fa/disable');
  }
}
