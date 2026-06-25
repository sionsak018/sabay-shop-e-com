import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sabay_shop_app/core/router/route_name.dart';
import 'package:sabay_shop_app/core/network/api_endpoints.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';
import 'package:sabay_shop_app/features/products/presentation/controllers/product_controller.dart';
import 'package:sabay_shop_app/features/products/presentation/controllers/category_controller.dart';
import 'package:sabay_shop_app/features/home/presentation/controllers/home_controller.dart';
import 'package:sabay_shop_app/features/products/presentation/widgets/product_card.dart';
import 'package:sabay_shop_app/features/products/presentation/screens/product_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sabay_shop_app/features/products/domain/entities/category_entity.dart';
import 'package:sabay_shop_app/features/home/domain/entities/banner_entity.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(homeBannerControllerProvider);
    final categoriesAsync = ref.watch(categoryControllerProvider);
    
    final productsAsync = ref.watch(productListControllerProvider());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F6),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeBannerControllerProvider);
            ref.invalidate(categoryControllerProvider);
            ref.invalidate(productListControllerProvider());
            
            // Wait for all to finish
            await Future.wait([
              ref.read(homeBannerControllerProvider.future),
              ref.read(categoryControllerProvider.future),
              ref.read(productListControllerProvider().future),
            ]);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Home Slider (Banner)
              SliverToBoxAdapter(
                child: bannersAsync.when(
                  skipLoadingOnRefresh: false,
                  data: (banners) => _buildBannerSlider(banners),
                  loading: () => _buildBannerSkeleton(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ),

              // Browse By Category Section
              SliverToBoxAdapter(
                child: categoriesAsync.when(
                  skipLoadingOnRefresh: false,
                  data: (categories) => _buildCategorySection(categories),
                  loading: () => _buildCategorySkeleton(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ),

              // Results Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'RECENT ADS',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F2937),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Product Grid
              productsAsync.when(
                skipLoadingOnRefresh: false,
                data: (products) {
                  if (products.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Text(
                            'No items found.',
                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }
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
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailPage(product: product),
                                ),
                              );
                            },
                            onFavoriteTap: () {
                              final authState = ref.read(authControllerProvider);
                              if (authState.value != null) {
                                ref.read(productListControllerProvider().notifier)
                                    .toggleFavorite(product.id, currentStatus: product.isFavorited);
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
                },
                loading: () => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
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
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $err')),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSlider(List<BannerEntity> banners) {
    if (banners.isEmpty) return const SizedBox();
    return ImageSlideshow(
      width: double.infinity,
      height: 240,
      initialPage: 0,
      indicatorColor: AppTheme.primaryBlue,
      indicatorBackgroundColor: Colors.white70,
      autoPlayInterval: 6000,
      isLoop: true,
      children: banners.map<Widget>((banner) {
        return Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: ApiEndpoints.getImageUrl(banner.imageUrl),
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(color: Colors.white),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Text(
                banner.title?.toUpperCase() ?? 'FEATURED',
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 0.5,
                  height: 1.1,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCategorySection(List<CategoryEntity> categories) {
    final filteredCategories = categories.where((c) => c.parentId == null && c.slug != 'uncategorized').toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'BROWSE BY CATEGORY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF374151),
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final cat = filteredCategories[index];

                return InkWell(
                  onTap: () {
                    context.go('${RouteName.products}?category_id=${cat.id}');
                  },
                  child: Container(
                    width: 85,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: cat.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: ApiEndpoints.getImageUrl(cat.imageUrl!),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(color: Colors.white, width: 52, height: 52),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(Icons.category_outlined, size: 22, color: Colors.grey),
                                  )
                                : const Icon(Icons.category_outlined, size: 22, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
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

  Widget _buildBannerSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 240,
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCategorySkeleton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 120,
                height: 12,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
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
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 40,
                          height: 8,
                          color: Colors.white,
                        ),
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
              height: 160,
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
}
