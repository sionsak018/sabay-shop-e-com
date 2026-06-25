import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/core/network/repositories/base_repository.dart';
import 'package:sabay_shop_app/core/network/repositories/dio_provider.dart';
import 'package:sabay_shop_app/core/services/storage_service.dart';
import 'package:sabay_shop_app/features/auth/data/models/login_request_model.dart';
import 'package:sabay_shop_app/features/auth/data/models/register_request_model.dart';
import 'package:sabay_shop_app/features/auth/data/models/user_model.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/login_request.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/register_request.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:sabay_shop_app/features/auth/domain/repositories/auth_repository.dart';

part 'auth_repository_impl.g.dart';

class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final Dio dio;
  final StorageService storageService;

  AuthRepositoryImpl(this.dio, this.storageService);

  @override
  Future<UserEntity> login(LoginRequest request) async {
    return mapException(() async {
      final requestModel = LoginRequestModel(email: request.email, password: request.password);
      final response = await dio.post('/login', data: requestModel.toJson());
      
      final token = response.data['token'];
      final userModel = UserModel.fromJson(response.data['user']);
      
      await storageService.saveToken(token);
      return userModel;
    });
  }

  @override
  Future<UserEntity> register(RegisterRequest request) async {
    return mapException(() async {
      final requestModel = RegisterRequestModel(
        name: request.name,
        email: request.email,
        phone: request.phone,
        password: request.password,
        passwordConfirmation: request.passwordConfirmation,
      );
      final response = await dio.post('/register', data: requestModel.toJson());

      final token = response.data['token'];
      final userModel = UserModel.fromJson(response.data['user']);

      await storageService.saveToken(token);
      return userModel;
    });
  }

  @override
  Future<void> logout() async {
    return mapException(() async {
      await dio.post('/logout');
      await storageService.deleteToken();
    });
  }

  @override
  Future<UserEntity?> getProfile() async {
    return mapException(() async {
      try {
        final token = await storageService.getToken();
        if (token == null) return null;
        
        final response = await dio.get('/profile');
        return UserModel.fromJson(response.data);
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 401) {
          await storageService.deleteToken();
          return null;
        }
        rethrow;
      }
    });
  }
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(storageServiceProvider),
  );
}
