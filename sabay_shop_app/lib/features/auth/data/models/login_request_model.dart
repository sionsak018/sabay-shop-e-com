import 'package:sabay_shop_app/features/auth/domain/entities/login_request.dart';

class LoginRequestModel extends LoginRequest {
  LoginRequestModel({required super.email, required super.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}
