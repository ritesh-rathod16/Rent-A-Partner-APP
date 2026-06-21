import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

final apiClientProvider = Provider((ref) => ApiClient());

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  final _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('API_LOG: $obj'),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await _dio.delete(path, data: data);
  }

  Future<Response> postMultipart(String path, String filePath, String fieldName) async {
    try {
      final file = await MultipartFile.fromFile(filePath);
      final formData = FormData.fromMap({
        fieldName: file,
      });
      print('API_LOG: Sending multipart request to $path with file $filePath');
      return await _dio.post(path, data: formData);
    } catch (e) {
      print('API_LOG: Multipart error: $e');
      rethrow;
    }
  }

  Future<Response> postMultipleFiles(String path, List<String> filePaths, String fieldName) async {
    try {
      final Map<String, dynamic> data = {};
      final List<MultipartFile> files = [];
      for (var p in filePaths) {
        files.add(await MultipartFile.fromFile(p));
      }
      data[fieldName] = files;
      final formData = FormData.fromMap(data);
      print('API_LOG: Sending multi-file request to $path');
      return await _dio.post(path, data: formData);
    } catch (e) {
      print('API_LOG: Multi-file error: $e');
      rethrow;
    }
  }
}
