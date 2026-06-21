import 'dart:io';
import 'package:flutter/material.dart';
import '../api/api_config.dart';

class ImageHelper {
  static const String baseUrl = ApiConfig.baseUrl; // Match your ApiClient baseUrl

  static ImageProvider getImageProvider(String path) {
    if (path.isEmpty) return const AssetImage('assets/images/placeholder.png');

    // Fix for legacy full URLs with old IPs
    if (path.startsWith('http') && path.contains('/uploads/')) {
      final parts = path.split('/uploads/');
      if (parts.length > 1) {
        path = parts[1]; // Convert back to relative
      }
    }

    if (path.startsWith('http')) {
      return NetworkImage(path);
    } 
    
    // Check if it's a known relative path pattern
    if (path.startsWith('profile/') || path.startsWith('companion/') || path.startsWith('gallery/') || path.startsWith('panic_recordings/') || path.startsWith('chat/')) {
      return NetworkImage('$baseUrl/uploads/$path');
    }

    if (path.startsWith('/') || path.contains(':')) {
      // Local path (absolute or with drive letter)
      return FileImage(File(path));
    }
    
    // Fallback relative path
    return NetworkImage('$baseUrl/uploads/$path');
  }

  static Widget buildImage(String path, {double? width, double? height, BoxFit fit = BoxFit.cover, Widget? errorWidget}) {
    if (path.isEmpty) {
      return errorWidget ?? _placeholder(width, height);
    }

    // Fix for legacy full URLs with old IPs
    if (path.startsWith('http') && path.contains('/uploads/')) {
      final parts = path.split('/uploads/');
      if (parts.length > 1) {
        path = parts[1]; // Convert back to relative
      }
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => errorWidget ?? _placeholder(width, height),
      );
    } else if (File(path).existsSync()) {
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => errorWidget ?? _placeholder(width, height),
      );
    } else {
      // Try serving from backend
      return Image.network(
        '$baseUrl/uploads/$path',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => errorWidget ?? _placeholder(width, height),
      );
    }
  }

  static Widget _placeholder(double? w, double? h) {
    return Container(
      width: w,
      height: h,
      color: const Color(0xFFFFE4EC),
      child: const Icon(Icons.person, color: Color(0xFFFF4D8D)),
    );
  }
}
