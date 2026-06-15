import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sabay_shop_app/features/products/domain/entities/product_entity.dart';
import 'package:sabay_shop_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:sabay_shop_app/features/products/presentation/widgets/product_card.dart';
import 'package:sabay_shop_app/features/products/presentation/screens/product_detail_page.dart';

import 'package:sabay_shop_app/features/products/presentation/controllers/product_controller.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:sabay_shop_app/core/router/route_name.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    // Use the controller instead of raw repository call for better state management
    final productsProvider = productListControllerProvider(sort: 'latest');
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SAVED ADS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productListControllerProvider);
          await ref.read(productsProvider.future);
        },
        child: productsAsync.when(
          skipLoadingOnRefresh: false,
          data: (allProducts) {
            // Filter to only show favorited items
            final products = allProducts.where((p) => p.isFavorited).toList();
            
            if (products.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 200,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No saved ads yet', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Items you heart will appear here', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              );
            }

            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
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
                    if (authState.value == null && !authState.isLoading) {
                      context.push(RouteName.login);
                    } else {
                      // This will toggle the state and the list will update automatically
                      ref.read(productsProvider.notifier)
                          .toggleFavorite(products[index].id, currentStatus: products[index].isFavorited);
                    }
                  },
                );
              },
            );
          },
          loading: () => GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => _buildFavoriteSkeleton(),
          ),
          error: (err, __) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildFavoriteSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
