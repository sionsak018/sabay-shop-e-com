import 'package:sabay_shop_app/features/products/domain/entities/product_entity.dart';
import 'package:sabay_shop_app/features/products/domain/entities/category_entity.dart';
import 'package:sabay_shop_app/features/products/domain/entities/attribute_entity.dart';

abstract class ProductRepository {
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
  });
  Future<List<CategoryEntity>> getCategories();
  Future<ProductEntity> getProductDetail(int id);
  Future<List<CategoryAttributeEntity>> getCategoryAttributes(int categoryId);
  Future<ProductEntity> createProduct(Map<String, dynamic> data);
  Future<ProductEntity> updateProduct(int id, Map<String, dynamic> data);
  Future<void> destroy(int id);
  Future<void> toggleFavorite(int productId);
}
