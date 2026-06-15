import 'package:sabay_shop_app/features/products/domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  CategoryModel({
    required super.id,
    required super.name,
    super.imageUrl,
    required super.slug,
    super.parentId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      slug: json['slug']?.toString() ?? '',
      parentId: json['parent_id'] != null ? (json['parent_id'] is int ? json['parent_id'] : int.tryParse(json['parent_id'].toString())) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'slug': slug,
      'parent_id': parentId,
    };
  }
}
