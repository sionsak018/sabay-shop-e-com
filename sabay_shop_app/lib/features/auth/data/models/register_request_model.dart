import 'package:sabay_shop_app/features/auth/domain/entities/register_request.dart';

class RegisterRequestModel extends RegisterRequest {
  RegisterRequestModel({
    required super.name,
    required super.email,
    required super.phone,
    required super.password,
    required super.passwordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}
