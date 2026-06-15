import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity> getUserProfile(int id);
  Future<UserEntity> updateProfile(Map<String, dynamic> data);
  Future<void> toggleFollow(int userId);
  Future<List<UserEntity>> getFollowers(int userId);
  Future<List<UserEntity>> getFollowing(int userId);
}
