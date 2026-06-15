import 'package:dio/dio.dart';
import 'package:sabay_shop_app/core/services/storage_service.dart';

class SecurityInterceptor extends Interceptor {
  final StorageService storageService;

  SecurityInterceptor(this.storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storageService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // Add other headers like language, app id if needed
    options.headers['Accept'] = 'application/json';
    
    return handler.next(options);
  }
}
