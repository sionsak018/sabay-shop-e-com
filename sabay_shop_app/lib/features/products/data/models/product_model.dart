import 'package:sabay_shop_app/features/products/domain/entities/product_entity.dart';
import 'package:sabay_shop_app/features/products/data/models/category_model.dart';
import 'package:sabay_shop_app/features/auth/data/models/user_model.dart';

class ProductModel extends ProductEntity {
  ProductModel({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    super.discountPrice,
    super.condition,
    super.location,
    required super.status,
    super.category,
    super.seller,
    required super.images,
    required super.createdAt,
    super.isFavorited,
    super.provinceId,
    super.districtId,
    super.communeId,
    super.villageId,
    super.address,
    super.posterName,
    super.posterEmail,
    super.posterPhones,
    super.companyName,
    super.lat,
    super.lng,
    super.attributeValues,
    super.attributeLabels,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      discountPrice: json['discount_price'] != null ? double.tryParse(json['discount_price'].toString()) : null,
      condition: json['condition']?.toString(),
      location: json['location']?.toString() ?? _buildLocationString(json),
      status: json['status']?.toString() ?? 'active',
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
      seller: json['seller'] != null ? UserModel.fromJson(json['seller']) : null,
      images: (json['images'] as List? ?? [])
          .map((i) => ProductImageModel.fromJson(i))
          .toList(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      isFavorited: json['is_favorited'] == 1 || json['is_favorited'] == true,
      provinceId: json['province_id'] != null ? int.tryParse(json['province_id'].toString()) : null,
      districtId: json['district_id'] != null ? int.tryParse(json['district_id'].toString()) : null,
      communeId: json['commune_id'] != null ? int.tryParse(json['commune_id'].toString()) : null,
      villageId: json['village_id'] != null ? int.tryParse(json['village_id'].toString()) : null,
      address: json['address']?.toString(),
      posterName: json['poster_name']?.toString(),
      posterEmail: json['poster_email']?.toString(),
      posterPhones: json['poster_phones']?.toString(),
      companyName: json['company_name']?.toString(),
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      attributeValues: _parseAttributes(json),
      attributeLabels: _parseAttributeLabels(json),
    );
  }

  static Map<String, dynamic>? _parseAttributes(Map<String, dynamic> json) {
    // If it's already a map (from a previous update/local)
    if (json['attributes'] is Map) {
      return Map<String, dynamic>.from(json['attributes']);
    }
    
    // If it comes from Laravel relationship (attribute_values array)
    if (json['attribute_values'] is List) {
      final Map<String, dynamic> map = {};
      for (var item in json['attribute_values']) {
        if (item['attribute_id'] != null) {
          map[item['attribute_id'].toString()] = item['value'];
        }
      }
      return map;
    }
    
    return null;
  }

  static Map<String, String>? _parseAttributeLabels(Map<String, dynamic> json) {
    if (json['attribute_values'] is List) {
      final Map<String, String> labels = {};
      for (var item in json['attribute_values']) {
        if (item['attribute_id'] != null && item['attribute'] != null && item['attribute']['name'] != null) {
          labels[item['attribute_id'].toString()] = item['attribute']['name'].toString();
        }
      }
      return labels.isEmpty ? null : labels;
    }
    return null;
  }

  static String? _buildLocationString(Map<String, dynamic> json) {
    final province = json['province']?['name'];
    final district = json['district']?['name'];
    final commune = json['commune']?['name'];
    final village = json['village']?['name'];
    
    final parts = [village, commune, district, province].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}

class ProductImageModel extends ProductImageEntity {
  ProductImageModel({required super.id, required super.imageUrl});

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}
