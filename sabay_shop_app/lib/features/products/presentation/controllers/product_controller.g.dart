// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProductListController)
final productListControllerProvider = ProductListControllerFamily._();

final class ProductListControllerProvider
    extends $AsyncNotifierProvider<ProductListController, List<ProductEntity>> {
  ProductListControllerProvider._(
      {required ProductListControllerFamily super.from,
      required ({
        String? categoryId,
        String? search,
        String? provinceId,
        String? districtId,
        double? minPrice,
        double? maxPrice,
        String? sort,
        String? userId,
        String? encodedAttributes,
      })
          super.argument})
      : super(
          retry: null,
          name: r'productListControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$productListControllerHash();

  @override
  String toString() {
    return r'productListControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ProductListController create() => ProductListController();

  @override
  bool operator ==(Object other) {
    return other is ProductListControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productListControllerHash() =>
    r'37e63b7ffd286d21b6595a97db1524da6a5661e3';

final class ProductListControllerFamily extends $Family
    with
        $ClassFamilyOverride<
            ProductListController,
            AsyncValue<List<ProductEntity>>,
            List<ProductEntity>,
            FutureOr<List<ProductEntity>>,
            ({
              String? categoryId,
              String? search,
              String? provinceId,
              String? districtId,
              double? minPrice,
              double? maxPrice,
              String? sort,
              String? userId,
              String? encodedAttributes,
            })> {
  ProductListControllerFamily._()
      : super(
          retry: null,
          name: r'productListControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ProductListControllerProvider call({
    String? categoryId,
    String? search,
    String? provinceId,
    String? districtId,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? userId,
    String? encodedAttributes,
  }) =>
      ProductListControllerProvider._(argument: (
        categoryId: categoryId,
        search: search,
        provinceId: provinceId,
        districtId: districtId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sort: sort,
        userId: userId,
        encodedAttributes: encodedAttributes,
      ), from: this);

  @override
  String toString() => r'productListControllerProvider';
}

abstract class _$ProductListController
    extends $AsyncNotifier<List<ProductEntity>> {
  late final _$args = ref.$arg as ({
    String? categoryId,
    String? search,
    String? provinceId,
    String? districtId,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? userId,
    String? encodedAttributes,
  });
  String? get categoryId => _$args.categoryId;
  String? get search => _$args.search;
  String? get provinceId => _$args.provinceId;
  String? get districtId => _$args.districtId;
  double? get minPrice => _$args.minPrice;
  double? get maxPrice => _$args.maxPrice;
  String? get sort => _$args.sort;
  String? get userId => _$args.userId;
  String? get encodedAttributes => _$args.encodedAttributes;

  FutureOr<List<ProductEntity>> build({
    String? categoryId,
    String? search,
    String? provinceId,
    String? districtId,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? userId,
    String? encodedAttributes,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ProductEntity>>, List<ProductEntity>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<ProductEntity>>, List<ProductEntity>>,
        AsyncValue<List<ProductEntity>>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              categoryId: _$args.categoryId,
              search: _$args.search,
              provinceId: _$args.provinceId,
              districtId: _$args.districtId,
              minPrice: _$args.minPrice,
              maxPrice: _$args.maxPrice,
              sort: _$args.sort,
              userId: _$args.userId,
              encodedAttributes: _$args.encodedAttributes,
            ));
  }
}
