import 'package:dio/dio.dart';

class ApiErrorHandler {
  static String handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "The server is taking too long to respond. Please try again.";
        
        case DioExceptionType.connectionError:
          return "Unable to connect to server. Please check your internet or try again later.";
        
        case DioExceptionType.badResponse:
          final data = error.response?.data;
          if (data is Map) {
            if (data.containsKey('message')) {
              return data['message'];
            }
            if (data.containsKey('detail')) {
              final detail = data['detail'];
              if (detail is String) return detail;
              if (detail is List && detail.isNotEmpty) {
                // Handle standard FastAPI validation error format
                final firstError = detail[0];
                if (firstError is Map && firstError.containsKey('msg')) {
                  return "Validation Error: ${firstError['msg']}";
                }
              }
            }
          }
          return "Server returned an error (${error.response?.statusCode}). Please try again.";
          
        case DioExceptionType.cancel:
          return "Request was cancelled.";
          
        case DioExceptionType.unknown:
          if (error.message != null && error.message!.contains("SocketException")) {
            return "No internet connection detected. Please check your network.";
          }
          return "An unexpected error occurred. Please try again.";
          
        default:
          return "Something went wrong. Please try again later.";
      }
    } else if (error is String) {
      return error;
    } else {
      return "An unexpected error occurred.";
    }
  }
}
