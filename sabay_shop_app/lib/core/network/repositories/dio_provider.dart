import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/core/config/app_config.dart';
import 'package:sabay_shop_app/core/network/interceptors/security_interceptor.dart';
import 'package:sabay_shop_app/core/services/storage_service.dart';

part 'dio_provider.g.dart';

@riverpod
Dio dio(Ref ref) {
  final storageService = ref.watch(storageServiceProvider);
  
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(SecurityInterceptor(storageService));
  
  return dio;
}
