import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sabay_shop_app/features/products/domain/entities/product_entity.dart';
import 'package:sabay_shop_app/features/products/presentation/controllers/product_controller.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sabay_shop_app/core/network/api_endpoints.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';
import 'package:sabay_shop_app/features/products/presentation/screens/product_create_page.dart';
import 'package:sabay_shop_app/features/products/presentation/screens/product_edit_page.dart';
import 'package:sabay_shop_app/features/products/data/repositories/product_repository_impl.dart';

class MyProductsPage extends ConsumerWidget {
  const MyProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('MY LISTINGS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
        ),
        body: const _MyProductSkeletonList(),
      );
    }

    final productsProvider = productListControllerProvider(userId: user.id.toString(), sort: 'latest');
    final myProductsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('MY LISTINGS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductCreatePage()),
              );
              if (result == true) {
                ref.invalidate(productListControllerProvider);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productListControllerProvider);
          await ref.read(productsProvider.future);
        },
        child: myProductsAsync.when(
          skipLoadingOnRefresh: false,
          data: (products) {
            if (products.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 200,
                  child: _buildEmptyState(context, ref, user.id),
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductItem(context, ref, products[index], user.id);
              },
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: 8,
            itemBuilder: (context, index) => _buildMyProductSkeleton(),
          ),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildMyProductSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 110,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, int userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
              child: const Icon(Icons.storefront, size: 80, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 24),
            const Text('No Active Listings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1F2937))),
            const SizedBox(height: 12),
            const Text(
              'You haven\'t posted any ads yet. Start selling today!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductCreatePage()),
                  );
                  if (result == true) {
                    ref.invalidate(productListControllerProvider(userId: userId.toString()));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('POST YOUR FIRST AD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, WidgetRef ref, ProductEntity p, int userId) {
    final imageUrl = p.images.isNotEmpty ? ApiEndpoints.getImageUrl(p.images.first.imageUrl) : '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 90,
                height: 90,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl, 
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1F2937)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${p.price.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(p.status),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.grey),
              onPressed: () => _showActionSheet(context, ref, p, userId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'active') color = Colors.green;
    if (status == 'sold') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  void _showActionSheet(BuildContext context, WidgetRef ref, ProductEntity p, int userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('AD MANAGEMENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.blue),
                title: const Text('Edit Ad Details', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductEditPage(product: p)));
                  if (result == true) ref.invalidate(productListControllerProvider(userId: userId.toString()));
                },
              ),
              if (p.status == 'active') ...[
                ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.orange),
                  title: const Text('Mark as Item Sold', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    Navigator.pop(context);
                    // Update to Sold status
                    await ref.read(productRepositoryProvider).updateProduct(p.id, {'status': 'sold'});
                    // Instant Refresh
                    ref.invalidate(productListControllerProvider);
                    ref.invalidate(authControllerProvider); // Update Ads stats
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.pause_circle_outline, color: Colors.red),
                  title: const Text('Stop / Pause Ad', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    Navigator.pop(context);
                    // Update to Inactive status
                    await ref.read(productRepositoryProvider).updateProduct(p.id, {'status': 'inactive'});
                    // Instant Refresh
                    ref.invalidate(productListControllerProvider);
                    ref.invalidate(authControllerProvider);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.play_circle_outline, color: Colors.green),
                  title: const Text('Resume Ad', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    Navigator.pop(context);
                    // Update to Active status
                    await ref.read(productRepositoryProvider).updateProduct(p.id, {'status': 'active'});
                    // Instant Refresh
                    ref.invalidate(productListControllerProvider);
                    ref.invalidate(authControllerProvider);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Delete Ad Permanently', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, p, userId);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ProductEntity p, int userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ad?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to permanently delete this ad? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(productRepositoryProvider).destroy(p.id);
              ref.invalidate(productListControllerProvider(userId: userId.toString()));
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _MyProductSkeletonList extends StatelessWidget {
  const _MyProductSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 8,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 110,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
