import 'package:sabay_shop_app/features/products/domain/entities/attribute_entity.dart';

class CategoryAttributeModel extends CategoryAttributeEntity {
  const CategoryAttributeModel({
    required super.id,
    required super.name,
    required super.type,
    required super.options,
    super.isRequired,
  });

  factory CategoryAttributeModel.fromJson(Map<String, dynamic> json) {
    return CategoryAttributeModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name'] ?? '',
      type: json['type'] ?? 'text',
      isRequired: json['pivot'] != null ? (json['pivot']['is_required'] == 1) : false,
      options: (json['options'] as List? ?? [])
          .map((o) => AttributeOptionModel.fromJson(o))
          .toList(),
    );
  }
}

class AttributeOptionModel extends AttributeOptionEntity {
  const AttributeOptionModel({
    required super.id,
    required super.value,
    super.imageUrl,
  });

  factory AttributeOptionModel.fromJson(Map<String, dynamic> json) {
    return AttributeOptionModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      value: json['value'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}
