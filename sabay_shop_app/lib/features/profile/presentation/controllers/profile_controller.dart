import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:sabay_shop_app/features/profile/data/repositories/profile_repository_impl.dart';

part 'profile_controller.g.dart';

@riverpod
class UserProfileController extends _$UserProfileController {
  @override
  FutureOr<UserEntity> build(int userId) async {
    final repository = ref.read(profileRepositoryProvider);
    return await repository.getUserProfile(userId);
  }

  Future<void> toggleFollow() async {
    final repository = ref.read(profileRepositoryProvider);
    await repository.toggleFollow(userId);
    
    // Refresh the profile and lists
    ref.invalidateSelf();
    ref.invalidate(userFollowersControllerProvider(userId));
    ref.invalidate(userFollowingControllerProvider(userId));
  }
}

@riverpod
class UserFollowersController extends _$UserFollowersController {
  @override
  FutureOr<List<UserEntity>> build(int userId) async {
    final repository = ref.read(profileRepositoryProvider);
    return await repository.getFollowers(userId);
  }
}

@riverpod
class UserFollowingController extends _$UserFollowingController {
  @override
  FutureOr<List<UserEntity>> build(int userId) async {
    final repository = ref.read(profileRepositoryProvider);
    return await repository.getFollowing(userId);
  }
}
