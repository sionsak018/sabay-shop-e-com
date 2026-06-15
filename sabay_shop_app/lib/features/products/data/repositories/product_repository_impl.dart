import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/core/network/repositories/base_repository.dart';
import 'package:sabay_shop_app/core/network/repositories/dio_provider.dart';
import 'package:sabay_shop_app/features/products/data/models/product_model.dart';
import 'package:sabay_shop_app/features/products/data/models/category_model.dart';
import 'package:sabay_shop_app/features/products/data/models/attribute_model.dart';
import 'package:sabay_shop_app/features/products/domain/entities/product_entity.dart';
import 'package:sabay_shop_app/features/products/domain/entities/category_entity.dart';
import 'package:sabay_shop_app/features/products/domain/entities/attribute_entity.dart';
import 'package:sabay_shop_app/features/products/domain/repositories/product_repository.dart';

part 'product_repository_impl.g.dart';

class ProductRepositoryImpl extends BaseRepository implements ProductRepository {
  final Dio dio;

  ProductRepositoryImpl(this.dio);

  @override
  Future<List<ProductEntity>> getProducts({
    int page = 1,
    String? categoryId,
    String? search,
    String? provinceId,
    String? districtId,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? userId,
    Map<String, String>? attributes,
  }) async {
    return mapException(() async {
      final queryParams = {
        'page': page,
        if (categoryId != null) 'category_id': categoryId,
        if (search != null) 'keyword': search,
        if (provinceId != null) 'province_id': provinceId,
        if (districtId != null) 'district_id': districtId,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (sort != null) 'sort': sort,
        if (userId != null && userId != 'null') 'user_id': userId,
        if (attributes != null) ...attributes,
      };

      final response = await dio.get('/products', queryParameters: queryParams);
      final List data = response.data['data'] ?? [];
      return data.map<ProductEntity>((json) => ProductModel.fromJson(json)).toList();
    });
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    return mapException(() async {
      final response = await dio.get('/categories');
      final List data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map<CategoryEntity>((json) => CategoryModel.fromJson(json)).toList();
    });
  }

  @override
  Future<ProductEntity> getProductDetail(int id) async {
    return mapException(() async {
      final response = await dio.get('/products/$id');
      return ProductModel.fromJson(response.data);
    });
  }

  @override
  Future<List<CategoryAttributeEntity>> getCategoryAttributes(int categoryId) async {
    return mapException(() async {
      final response = await dio.get('/category-attributes/$categoryId');
      final List data = response.data is List ? response.data : [];
      return data.map<CategoryAttributeEntity>((json) => CategoryAttributeModel.fromJson(json)).toList();
    });
  }

  @override
  Future<ProductEntity> createProduct(Map<String, dynamic> data) async {
    return mapException(() async {
      final formData = FormData.fromMap(data);
      final response = await dio.post('/products', data: formData);
      return ProductModel.fromJson(response.data['data'] ?? response.data);
    });
  }

  @override
  Future<ProductEntity> updateProduct(int id, Map<String, dynamic> data) async {
    return mapException(() async {
      final formData = FormData.fromMap(data);
      // Laravel requires _method = PUT for multipart POST requests to act as PUT
      formData.fields.add(const MapEntry('_method', 'PUT'));
      final response = await dio.post('/products/$id', data: formData);
      return ProductModel.fromJson(response.data['data'] ?? response.data);
    });
  }

  @override
  Future<void> destroy(int id) async {
    return mapException(() async {
      await dio.delete('/products/$id');
    });
  }

  @override
  Future<void> toggleFavorite(int productId) async {
    return mapException(() async {
      await dio.post('/favorites/$productId');
    });
  }
}

@riverpod
ProductRepository productRepository(Ref ref) {
  return ProductRepositoryImpl(ref.watch(dioProvider));
}
