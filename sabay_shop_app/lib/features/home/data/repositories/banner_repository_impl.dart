import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/core/network/repositories/base_repository.dart';
import 'package:sabay_shop_app/core/network/repositories/dio_provider.dart';
import 'package:sabay_shop_app/features/home/data/models/banner_model.dart';
import 'package:sabay_shop_app/features/home/domain/entities/banner_entity.dart';
import 'package:sabay_shop_app/features/home/domain/repositories/banner_repository.dart';

part 'banner_repository_impl.g.dart';

class BannerRepositoryImpl extends BaseRepository implements BannerRepository {
  final Dio dio;

  BannerRepositoryImpl(this.dio);

  @override
  Future<List<BannerEntity>> getActiveBanners() async {
    return mapException(() async {
      final response = await dio.get('/sliders');
      final List data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map((json) => BannerModel.fromJson(json)).toList();
    });
  }
}

@riverpod
BannerRepository bannerRepository(Ref ref) {
  return BannerRepositoryImpl(ref.watch(dioProvider));
}
