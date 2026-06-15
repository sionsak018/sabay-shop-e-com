import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/login_request.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/register_request.dart';

abstract class AuthRepository {
  Future<UserEntity> login(LoginRequest request);
  Future<UserEntity> register(RegisterRequest request);
  Future<void> logout();
  Future<UserEntity?> getProfile();
}
