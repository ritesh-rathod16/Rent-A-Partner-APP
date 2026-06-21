import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/advertisement.dart';

final adsRepositoryProvider = Provider((ref) => AdsRepository(ref.read(apiClientProvider)));

final activeAdsProvider = FutureProvider<List<Advertisement>>((ref) async {
  return ref.read(adsRepositoryProvider).getActiveAds();
});

class AdsRepository {
  final ApiClient _apiClient;

  AdsRepository(this._apiClient);

  Future<List<Advertisement>> getActiveAds() async {
    final response = await _apiClient.get('/ads/active');
    return (response.data as List).map((e) => Advertisement.fromJson(e)).toList();
  }

  Future<void> trackClick(String adId) async {
    await _apiClient.post('/ads/click/$adId');
  }
}
