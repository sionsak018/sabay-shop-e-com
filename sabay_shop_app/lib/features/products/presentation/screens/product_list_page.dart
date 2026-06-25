import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sabay_shop_app/core/network/api_endpoints.dart';
import 'package:sabay_shop_app/features/products/domain/entities/product_entity.dart';
import 'package:sabay_shop_app/features/products/domain/entities/category_entity.dart';
import 'package:sabay_shop_app/features/products/domain/entities/attribute_entity.dart';
import 'package:sabay_shop_app/features/products/presentation/controllers/product_controller.dart';
import 'package:sabay_shop_app/features/products/presentation/controllers/category_controller.dart';
import 'package:sabay_shop_app/features/products/presentation/controllers/attribute_controller.dart';
import 'package:sabay_shop_app/features/products/presentation/widgets/product_card.dart';
import 'package:sabay_shop_app/features/products/presentation/screens/product_detail_page.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';
import 'package:sabay_shop_app/features/profile/domain/entities/location_entity.dart';
import 'package:sabay_shop_app/features/profile/presentation/widgets/location_picker_sheet.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sabay_shop_app/core/router/route_name.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ProductListPage extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  final String? initialSearch;

  const ProductListPage({super.key, this.initialCategoryId, this.initialSearch});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String? _categoryId;
  String? _search;
  ProvinceEntity? _province;
  DistrictEntity? _district;
  double? _minPrice;
  double? _maxPrice;
  String _sort = 'latest';
  final Map<String, String> _selectedAttributes = {};
  bool _isGridView = true;

  ProductListControllerProvider get _productsProvider {
    final sortedAttr = Map.fromEntries(_selectedAttributes.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    final encodedAttributes = sortedAttr.isEmpty ? null : jsonEncode(sortedAttr);

    return productListControllerProvider(
      categoryId: _categoryId,
      search: _search,
      provinceId: _province?.id.toString(),
      districtId: _district?.id.toString(),
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      sort: _sort,
      encodedAttributes: encodedAttributes,
    );
  }

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _search = widget.initialSearch;
    _searchController.text = _search ?? '';
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      setState(() {
        _search = query.isEmpty ? null : query;
      });
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(_productsProvider.notifier).loadMore();
    }
  }

  @override
  void didUpdateWidget(ProductListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      setState(() {
        _categoryId = widget.initialCategoryId;
        _selectedAttributes.clear();
      });
    }
    if (widget.initialSearch != oldWidget.initialSearch) {
      setState(() {
        _search = widget.initialSearch;
        _searchController.text = _search ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryControllerProvider);
    final productsProvider = _productsProvider;
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = null);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onSubmitted: (v) => setState(() => _search = v.isEmpty ? null : v),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: AppTheme.primaryBlue),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.primaryBlue),
            onPressed: () => _showFilterModal(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productListControllerProvider);
          ref.invalidate(categoryControllerProvider);
          
          await Future.wait([
            ref.read(_productsProvider.future),
            ref.read(categoryControllerProvider.future),
          ]);
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Breadcrumbs Trail
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                skipLoadingOnRefresh: false,
                data: (categories) => _buildBreadcrumbs(categories),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ),

            // Category Selection (Browse By)
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                skipLoadingOnRefresh: false,
                data: (categories) => _buildCategorySection(categories),
                loading: () => _buildCategorySkeleton(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ),

            // Dynamic Attributes
            if (_categoryId != null)
              _buildDynamicAttributeSlivers(int.parse(_categoryId!)),

            // Product Grid Header (Results count or title)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'RESULTS',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1F2937), letterSpacing: 0.5),
                        ),
                        if (_categoryId != null || _search != null || _province != null || _selectedAttributes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _categoryId = null;
                                  _search = null;
                                  _searchController.clear();
                                  _province = null;
                                  _district = null;
                                  _minPrice = null;
                                  _maxPrice = null;
                                  _selectedAttributes.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'CLEAR ALL',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${_isGridView ? "Grid" : "List"} View',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            // Product List/Grid
            productsAsync.when(
              skipLoadingOnRefresh: false,
              data: (products) {
                if (products.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          'No items found matching your criteria.',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }

                if (_isGridView) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ProductCard(
                            product: products[index],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailPage(product: products[index]),
                              ),
                            ),
                            onFavoriteTap: () {
                              final authState = ref.read(authControllerProvider);
                              if (authState.value != null) {
                                ref.read(productsProvider.notifier)
                                    .toggleFavorite(products[index].id, currentStatus: products[index].isFavorited);
                              } else if (!authState.isLoading) {
                                context.push(RouteName.login);
                              }
                            },
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  );
                } else {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildProductListItem(products[index], productsProvider),
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  );
                }
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: _isGridView
                    ? SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProductSkeleton(),
                          childCount: 6,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildProductListSkeleton(),
                          ),
                          childCount: 6,
                        ),
                      ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $err')),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Loading more indicator
            if (productsAsync.hasValue)
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, child) {
                    final notifier = ref.watch(productsProvider.notifier);
                    
                    if (notifier.isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    if (!notifier.hasMore && (productsAsync.value?.isNotEmpty ?? false)) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Text(
                            'You have reached the end',
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 10);
                  },
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(List<CategoryEntity> categories) {
    final List<Widget> items = [];

    // Root Level
    items.add(_buildBreadcrumbItem('All Categories', () {
      setState(() {
        _categoryId = null;
        _selectedAttributes.clear();
      });
    }, isLast: _categoryId == null));

    // Category Level
    if (_categoryId != null && categories.isNotEmpty) {
      final matchingCats = categories.where((c) => c.id.toString() == _categoryId);
      if (matchingCats.isNotEmpty) {
        final cat = matchingCats.first;
        items.add(_buildBreadcrumbItem(cat.name, () {
          setState(() {
            _selectedAttributes.clear();
          });
        }, isLast: _selectedAttributes.isEmpty));
      }
    }

    // Attributes Level
    final attrEntries = _selectedAttributes.entries.toList();
    for (int i = 0; i < attrEntries.length; i++) {
      final entry = attrEntries[i];
      final isLast = i == attrEntries.length - 1;
      items.add(_buildBreadcrumbItem(entry.value, () {
        _removeAttributesFrom(entry.key);
      }, isLast: isLast));
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: items),
      ),
    );
  }

  Widget _buildBreadcrumbItem(String label, VoidCallback onTap, {required bool isLast}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isLast ? null : onTap,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isLast ? FontWeight.w900 : FontWeight.bold,
              color: isLast ? Colors.grey[600] : AppTheme.primaryBlue,
            ),
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ),
      ],
    );
  }

  void _removeAttributesFrom(String key) {
    setState(() {
      final keys = _selectedAttributes.keys.toList();
      final index = keys.indexOf(key);
      if (index != -1) {
        for (int i = keys.length - 1; i >= index; i--) {
          _selectedAttributes.remove(keys[i]);
        }
      }
    });
  }

  Widget _buildCategorySection(List<CategoryEntity> categories) {
    final List<CategoryEntity> displayCategories;
    String sectionTitle;

    if (_categoryId == null) {
      displayCategories = categories.where((c) => c.parentId == null && c.slug != 'uncategorized').toList();
      sectionTitle = 'BROWSE BY CATEGORY';
    } else {
      final subCats = categories.where((c) => c.parentId.toString() == _categoryId).toList();
      if (subCats.isEmpty) return const SizedBox.shrink();
      displayCategories = subCats;
      final parentCat = categories.firstWhere((c) => c.id.toString() == _categoryId);
      sectionTitle = 'BROWSE IN ${parentCat.name.toUpperCase()}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              sectionTitle,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF9CA3AF),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: displayCategories.length,
              itemBuilder: (context, index) {
                final cat = displayCategories[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _categoryId = cat.id.toString();
                      _selectedAttributes.clear();
                    });
                  },
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: ClipOval(
                            child: cat.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: ApiEndpoints.getImageUrl(cat.imageUrl!),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(color: Colors.white, width: 48, height: 48),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(Icons.category_outlined, size: 20, color: Colors.grey),
                                  )
                                : const Icon(Icons.category_outlined, size: 20, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4B5563),
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicAttributeSlivers(int categoryId) {
    final attributesAsync = ref.watch(categoryAttributeControllerProvider(categoryId));

    return attributesAsync.when(
      skipLoadingOnRefresh: false,
      data: (attributes) {
        final selectAttributes = attributes.where((a) => a.type == 'select').toList();
        if (selectAttributes.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        final brandAttr = selectAttributes.cast<CategoryAttributeEntity?>().firstWhere(
          (a) => a?.name == 'Brand', 
          orElse: () => null,
        );
        
        final isBrandSelected = brandAttr != null && _selectedAttributes.containsKey('attr_${brandAttr.id}');

        List<CategoryAttributeEntity> visibleAttributes = [];

        if (brandAttr != null) {
          if (!isBrandSelected) {
            visibleAttributes = [brandAttr];
          } else {
            visibleAttributes = selectAttributes.where((a) {
               final key = 'attr_${a.id}';
               return a.name != 'Brand' && !_selectedAttributes.containsKey(key);
            }).toList();
          }
        } else {
          visibleAttributes = selectAttributes.where((a) => !_selectedAttributes.containsKey('attr_${a.id}')).toList();
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final attr = visibleAttributes[index];
              return _buildAttributeSection(attr);
            },
            childCount: visibleAttributes.length,
          ),
        );
      },
      loading: () => SliverToBoxAdapter(child: _buildAttributeSkeleton()),
      error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _buildCategorySkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(width: 120, height: 10, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(width: 40, height: 8, color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(width: 100, height: 10, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 80,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 12, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 60, height: 12, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: double.infinity, height: 14, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 80, height: 14, color: Colors.white),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 60, height: 10, color: Colors.white),
                        Container(width: 60, height: 10, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListItem(ProductEntity product, dynamic provider) {
    final imageUrl = product.images.isNotEmpty ? product.images.first.imageUrl : '';
    final hasDiscount = product.discountPrice != null && product.discountPrice! > 0;
    
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(product: product),
        ),
      ),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ApiEndpoints.getImageUrl(imageUrl),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(color: Colors.white),
                            ),
                          )
                        : Container(color: Colors.grey[100], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: const Text('SALE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                          final authState = ref.read(authControllerProvider);
                          if (authState.value != null) {
                            ref.read(provider.notifier)
                                .toggleFavorite(product.id, currentStatus: product.isFavorited);
                          } else if (!authState.isLoading) {
                            context.push(RouteName.login);
                          }
                        },
                          child: Icon(
                            product.isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: product.isFavorited ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '\$${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '\$${product.discountPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  product.location ?? 'Cambodia',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('M/d/yyyy').format(product.createdAt),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeSection(CategoryAttributeEntity attr) {
    final isCircleStyle = ['Brand', 'Body Type', 'Make', 'Model'].contains(attr.name);
    final key = 'attr_${attr.id}';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              attr.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF9CA3AF),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: isCircleStyle ? 85 : 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: attr.options.length,
              itemBuilder: (context, index) {
                final opt = attr.options[index];

                if (isCircleStyle) {
                  return _buildCircleOption(opt, () => setState(() => _selectedAttributes[key] = opt.value));
                } else {
                  return _buildBoxOption(opt, () => setState(() => _selectedAttributes[key] = opt.value));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleOption(AttributeOptionEntity opt, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: ClipOval(
                child: opt.imageUrl != null && opt.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ApiEndpoints.getImageUrl(opt.imageUrl!),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white, width: 48, height: 48),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            opt.value.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          opt.value.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              opt.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5563),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxOption(AttributeOptionEntity opt, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(opt.value),
        selected: false,
        onSelected: (_) => onTap(),
        backgroundColor: const Color(0xFFF9FAFB),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.1),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('FILTERS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _sort = 'latest';
                        _province = null;
                        _district = null;
                        _minPrice = null;
                        _maxPrice = null;
                        _selectedAttributes.clear();
                      });
                      setModalState(() {});
                    },
                    child: const Text('CLEAR ALL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                isExpanded: true,
                value: _sort,
                items: const [
                  DropdownMenuItem(value: 'latest', child: Text('Newest First')),
                  DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                  DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _sort = v);
                    setModalState(() {});
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                title: Text(
                  _province == null ? 'All Cambodia' : '${_district?.name ?? ""}, ${_province!.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final res = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => const LocationPickerSheet(),
                  );
                  if (res != null) {
                    setState(() { _province = res['province']; _district = res['district']; });
                    setModalState(() {});
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text('Price Range', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _minPrice?.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Min',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (v) => _minPrice = double.tryParse(v),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('-'),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: _maxPrice?.toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Max',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (v) => _maxPrice = double.tryParse(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue, 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('APPLY FILTERS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
