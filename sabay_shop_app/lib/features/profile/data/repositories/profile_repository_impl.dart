import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/core/network/repositories/base_repository.dart';
import 'package:sabay_shop_app/core/network/repositories/dio_provider.dart';
import 'package:sabay_shop_app/features/auth/data/models/user_model.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:sabay_shop_app/features/profile/domain/repositories/profile_repository.dart';

part 'profile_repository_impl.g.dart';

class ProfileRepositoryImpl extends BaseRepository implements ProfileRepository {
  final Dio dio;

  ProfileRepositoryImpl(this.dio);

  @override
  Future<UserEntity> getUserProfile(int id) async {
    return mapException(() async {
      final response = await dio.get('/profile/$id');
      final data = response.data;
      
      // Safety check for malformed responses
      if (data == null || data['user'] == null) {
        throw Exception('User data not found in response');
      }

      // Merge user, stats and is_following into one map for UserModel.fromJson
      final Map<String, dynamic> userMap = Map<String, dynamic>.from(data['user']);
      if (data['stats'] != null) {
        userMap.addAll(Map<String, dynamic>.from(data['stats']));
      }
      userMap['is_following'] = data['is_following'];
      
      return UserModel.fromJson(userMap);
    });
  }

  @override
  Future<UserEntity> updateProfile(Map<String, dynamic> data) async {
    return mapException(() async {
      final formData = FormData.fromMap(data);
      final response = await dio.post('/profile', data: formData);
      return UserModel.fromJson(response.data);
    });
  }

  @override
  Future<void> toggleFollow(int userId) async {
    return mapException(() async {
      await dio.post('/follow/$userId');
    });
  }

  @override
  Future<List<UserEntity>> getFollowers(int userId) async {
    return mapException(() async {
      final response = await dio.get('/followers/$userId');
      final List data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map<UserEntity>((json) => UserModel.fromJson(json)).toList();
    });
  }

  @override
  Future<List<UserEntity>> getFollowing(int userId) async {
    return mapException(() async {
      final response = await dio.get('/following/$userId');
      final List data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map<UserEntity>((json) => UserModel.fromJson(json)).toList();
    });
  }
}

@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(ref.watch(dioProvider));
}
