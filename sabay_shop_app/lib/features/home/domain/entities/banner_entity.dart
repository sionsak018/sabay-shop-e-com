class BannerEntity {
  final int id;
  final String? title;
  final String imageUrl;
  final String? linkUrl;

  BannerEntity({
    required this.id,
    this.title,
    required this.imageUrl,
    this.linkUrl,
  });
}
