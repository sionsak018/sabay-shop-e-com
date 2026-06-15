import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final int id;
  final String name;
  final String? imageUrl;
  final String slug;
  final int? parentId;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.slug,
    this.parentId,
  });

  @override
  List<Object?> get props => [id, name, slug, parentId, imageUrl];
}
