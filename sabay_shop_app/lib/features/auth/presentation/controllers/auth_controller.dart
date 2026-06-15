import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/login_request.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/register_request.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:sabay_shop_app/features/auth/data/repositories/auth_repository_impl.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  FutureOr<UserEntity?> build() async {
    final repository = ref.read(authRepositoryProvider);
    return await repository.getProfile();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.login(LoginRequest(email: email, password: password));
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.register(RegisterRequest(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      ));
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.logout();
      return null;
    });
  }
}
