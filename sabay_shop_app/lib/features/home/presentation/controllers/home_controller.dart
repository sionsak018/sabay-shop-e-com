import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/features/home/domain/entities/banner_entity.dart';
import 'package:sabay_shop_app/features/home/data/repositories/banner_repository_impl.dart';

part 'home_controller.g.dart';

@riverpod
class HomeBannerController extends _$HomeBannerController {
  @override
  FutureOr<List<BannerEntity>> build() async {
    final repository = ref.read(bannerRepositoryProvider);
    return await repository.getActiveBanners();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(bannerRepositoryProvider);
      return await repository.getActiveBanners();
    });
  }
}
