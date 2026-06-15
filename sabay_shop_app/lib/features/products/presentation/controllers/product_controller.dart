import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/features/products/domain/entities/product_entity.dart';
import 'package:sabay_shop_app/features/products/data/repositories/product_repository_impl.dart';

part 'product_controller.g.dart';

class LastToggledFavorite extends Notifier<({int id, bool status})?> {
  @override
  ({int id, bool status})? build() => null;

  void toggle(int id, bool status) => state = (id: id, status: status);
}

final lastToggledFavoriteProvider = NotifierProvider<LastToggledFavorite, ({int id, bool status})?>(LastToggledFavorite.new);

@riverpod
class ProductListController extends _$ProductListController {
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  FutureOr<List<ProductEntity>> build({
    String? categoryId,
    String? search,
    String? provinceId,
    String? districtId,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? userId,
    String? encodedAttributes, // Use String to ensure stable equality in family provider
  }) async {
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;

    // Listen for favorite updates from other pages/providers to keep this list in sync
    ref.listen<({int id, bool status})?>(lastToggledFavoriteProvider, (previous, next) {
      if (next != null) {
        _updateLocalStatus(next.id, next.status);
      }
    });

    return _fetchProducts();
  }

  void _updateLocalStatus(int productId, bool isFavorited) {
    if (state.hasValue) {
      final products = state.value!;
      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final product = products[index];
        if (product.isFavorited != isFavorited) {
          final updatedProduct = product.copyWith(isFavorited: isFavorited);
          final newList = List<ProductEntity>.from(products);
          newList[index] = updatedProduct;
          state = AsyncValue.data(newList);
        }
      }
    }
  }

  Future<List<ProductEntity>> _fetchProducts() async {
    final repository = ref.read(productRepositoryProvider);
    
    Map<String, String>? attributes;
    if (encodedAttributes != null) {
      attributes = Map<String, String>.from(jsonDecode(encodedAttributes!));
    }

    return await repository.getProducts(
      page: _page,
      categoryId: categoryId,
      search: search,
      provinceId: provinceId,
      districtId: districtId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sort: sort,
      userId: userId,
      attributes: attributes,
    );
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || state.isLoading) return;

    _isLoadingMore = true;
    try {
      _page++;
      final moreProducts = await _fetchProducts();
      
      if (moreProducts.isEmpty) {
        _hasMore = false;
      } else {
        final currentProducts = state.value ?? [];
        state = AsyncValue.data([...currentProducts, ...moreProducts]);
        // If we got less than expected, we might be at the end. 
        // Assuming default per_page is 15.
        if (moreProducts.length < 15) {
          _hasMore = false;
        }
      }
    } catch (e, st) {
      _page--;
      // Silent error for pagination, or we could handle it better
    } finally {
      _isLoadingMore = false;
    }
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> toggleFavorite(int productId, {bool? currentStatus}) async {
    bool? status = currentStatus;
    
    // If currentStatus not provided, try to find it in our current list
    if (status == null && state.hasValue) {
      final products = state.value!;
      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        status = products[index].isFavorited;
      }
    }

    if (status == null) return; // Can't toggle if we don't know the status

    final newStatus = !status;

    // 1. Optimistic Update locally
    _updateLocalStatus(productId, newStatus);
    
    // 2. Broadcast to other instances
    ref.read(lastToggledFavoriteProvider.notifier).toggle(productId, newStatus);

    try {
      final repository = ref.read(productRepositoryProvider);
      await repository.toggleFavorite(productId);
    } catch (e) {
      // 3. Rollback on failure
      _updateLocalStatus(productId, status);
      ref.read(lastToggledFavoriteProvider.notifier).toggle(productId, status);
      rethrow;
    }
  }
}

extension on ProductEntity {
  ProductEntity copyWith({bool? isFavorited}) {
    return ProductEntity(
      id: id,
      title: title,
      description: description,
      price: price,
      discountPrice: discountPrice,
      condition: condition,
      location: location,
      status: status,
      category: category,
      seller: seller,
      images: images,
      createdAt: createdAt,
      isFavorited: isFavorited ?? this.isFavorited,
      provinceId: provinceId,
      districtId: districtId,
      communeId: communeId,
      villageId: villageId,
      address: address,
      posterName: posterName,
      posterEmail: posterEmail,
      posterPhones: posterPhones,
      companyName: companyName,
      lat: lat,
      lng: lng,
      brandId: brandId,
      brandModelId: brandModelId,
      bodyTypeId: bodyTypeId,
      attributeValues: attributeValues,
    );
  }
}
