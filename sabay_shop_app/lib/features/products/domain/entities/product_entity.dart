import 'package:equatable/equatable.dart';
import 'package:sabay_shop_app/features/products/domain/entities/category_entity.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';

class ProductEntity extends Equatable {
  final int id;
  final String title;
  final String description;
  final double price;
  final double? discountPrice;
  final String? condition;
  final String? location;
  final String status;
  final CategoryEntity? category;
  final UserEntity? seller;
  final List<ProductImageEntity> images;
  final DateTime createdAt;
  final bool isFavorited;
  
  // Location and Contact Info
  final int? provinceId;
  final int? districtId;
  final int? communeId;
  final int? villageId;
  final String? address;
  final String? posterName;
  final String? posterEmail;
  final String? posterPhones;
  final String? companyName;
  
  // Map Location
  final double? lat;
  final double? lng;
  
  // Dynamic Attributes
  final int? brandId;
  final int? brandModelId;
  final int? bodyTypeId;
  final Map<String, dynamic>? attributeValues;
  final Map<String, String>? attributeLabels; // Added to store display names

  const ProductEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.discountPrice,
    this.condition,
    this.location,
    required this.status,
    this.category,
    this.seller,
    required this.images,
    required this.createdAt,
    this.isFavorited = false,
    this.provinceId,
    this.districtId,
    this.communeId,
    this.villageId,
    this.address,
    this.posterName,
    this.posterEmail,
    this.posterPhones,
    this.companyName,
    this.lat,
    this.lng,
    this.brandId,
    this.brandModelId,
    this.bodyTypeId,
    this.attributeValues,
    this.attributeLabels,
  });

  @override
  List<Object?> get props => [id, title, price, status, isFavorited, lat, lng];
}

class ProductImageEntity extends Equatable {
  final int id;
  final String imageUrl;

  const ProductImageEntity({required this.id, required this.imageUrl});

  @override
  List<Object?> get props => [id, imageUrl];
}
