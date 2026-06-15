import 'package:sabay_shop_app/features/home/domain/entities/banner_entity.dart';

abstract class BannerRepository {
  Future<List<BannerEntity>> getActiveBanners();
}
