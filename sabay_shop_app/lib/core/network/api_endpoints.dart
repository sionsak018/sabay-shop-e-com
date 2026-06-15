import 'package:sabay_shop_app/core/config/app_config.dart';

class ApiEndpoints {
  // Use values from AppConfig which are populated via --dart-define-from-file
  static String get baseUrl => AppConfig.baseUrl;
  static String get baseHost => AppConfig.baseHost;

  // Helper to get image URL (Handles both Cloudinary and Local Storage)
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    
    // If it's an absolute URL
    if (path.startsWith('http')) {
      // If it's pointing to localhost/127.0.0.1, replace it with our configured baseHost
      if (path.contains('localhost') || path.contains('127.0.0.1')) {
        try {
          final uri = Uri.parse(path);
          // Return baseHost + the path (e.g., http://10.0.2.2:8000/storage/...)
          return '$baseHost${uri.path}';
        } catch (_) {
          return path;
        }
      }
      return path; // Return external URLs as is
    }
    
    // Ensure the path doesn't start with a slash
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    
    // If the path already includes 'storage/', 'images/', or 'assets/' don't add 'storage/'
    if (cleanPath.startsWith('storage/') || 
        cleanPath.startsWith('images/') || 
        cleanPath.startsWith('assets/')) {
      return '$baseHost/$cleanPath';
    }

    // Fallback for local storage (prepend storage/)
    return '$baseHost/storage/$cleanPath';
  }
}
