import 'package:sabay_shop_app/features/home/domain/entities/banner_entity.dart';

class BannerModel extends BannerEntity {
  BannerModel({
    required super.id,
    super.title,
    required super.imageUrl,
    super.linkUrl,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'] ?? '',
      linkUrl: json['link_url'],
    );
  }
}
