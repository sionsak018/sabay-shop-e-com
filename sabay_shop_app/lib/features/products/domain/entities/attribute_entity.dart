import 'package:equatable/equatable.dart';

class CategoryAttributeEntity extends Equatable {
  final int id;
  final String name;
  final String type;
  final List<AttributeOptionEntity> options;
  final bool isRequired;

  const CategoryAttributeEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.options,
    this.isRequired = false,
  });

  @override
  List<Object?> get props => [id, name, type, options, isRequired];
}

class AttributeOptionEntity extends Equatable {
  final int id;
  final String value;
  final String? imageUrl;

  const AttributeOptionEntity({
    required this.id,
    required this.value,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, value, imageUrl];
}
