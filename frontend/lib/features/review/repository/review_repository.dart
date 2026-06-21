import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final reviewRepositoryProvider = Provider((ref) => ReviewRepository(ref.read(apiClientProvider)));

class ReviewRepository {
  final ApiClient _apiClient;

  ReviewRepository(this._apiClient);

  Future<void> submitReview(Map<String, dynamic> reviewData) async {
    await _apiClient.post('/reviews/submit', data: reviewData);
  }
}
