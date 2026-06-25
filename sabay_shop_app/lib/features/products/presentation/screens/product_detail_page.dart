import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sabay_shop_app/core/router/route_name.dart';
import 'package:sabay_shop_app/features/products/domain/entities/product_entity.dart';
import 'package:sabay_shop_app/core/network/api_endpoints.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sabay_shop_app/features/products/presentation/controllers/product_controller.dart';
import 'package:sabay_shop_app/features/profile/presentation/screens/public_profile_page.dart';
import 'package:sabay_shop_app/features/profile/data/repositories/profile_repository_impl.dart';

import 'package:sabay_shop_app/features/products/presentation/screens/product_edit_page.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final ProductEntity product;

  const ProductDetailPage({super.key, required this.product});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  late bool _isFavorited;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.product.isFavorited;
  }

  Future<void> _openMap() async {
    final lat = widget.product.lat;
    final lng = widget.product.lng;
    if (lat == null || lng == null) return;

    // Open in external map application
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map app')),
        );
      }
    }
  }

  bool _checkAuth() {
    final authState = ref.read(authControllerProvider);
    if (authState.value != null) return true;
    
    if (!authState.isLoading) {
      context.push(RouteName.login);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for favorite sync from other pages
    ref.listen<({int id, bool status})?>(lastToggledFavoriteProvider, (previous, next) {
      if (next != null && next.id == widget.product.id) {
        if (mounted && _isFavorited != next.status) {
          setState(() => _isFavorited = next.status);
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          if (ref.watch(authControllerProvider).value?.id == widget.product.seller?.id)
            _buildAppBarAction(
              Icons.edit_outlined,
              Colors.white,
              () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductEditPage(product: widget.product)),
                );
                if (result == true) {
                  // Refresh គ្រប់បញ្ជី Product ទាំងអស់
                  ref.invalidate(productListControllerProvider);
                  // បើសិនជាមាន Detail Provider ត្រូវ Invalidate ដែរ (បើមាន)
                  
                  // បង្ហាញ Snack bar ជោគជ័យ
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product updated! Reloading...'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
            ),
          _buildAppBarAction(
            _isFavorited ? Icons.favorite : Icons.favorite_border,
            _isFavorited ? Colors.red : Colors.white,
            () {
              if (_checkAuth()) {
                final newStatus = !_isFavorited;
                setState(() => _isFavorited = newStatus);

                ref.read(productListControllerProvider().notifier)
                    .toggleFavorite(widget.product.id, currentStatus: !newStatus);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newStatus ? 'Added to favorites' : 'Removed from favorites'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          _buildAppBarAction(Icons.share_outlined, Colors.white, () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSlider(),
            _buildMainInfo(),
            _buildSpecifications(),
            _buildDescription(),
            _buildLocationSection(),
            _buildContactSection(),
            _buildSellerSection(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildAppBarAction(IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: CircleAvatar(
        backgroundColor: Colors.black26,
        child: IconButton(
          icon: Icon(icon, color: color, size: 20),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildImageSlider() {
    if (widget.product.images.isEmpty) {
      return Container(
        height: 350,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[100]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No images available', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 400,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemCount: widget.product.images.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: ApiEndpoints.getImageUrl(widget.product.images[index].imageUrl),
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[100],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text('Failed to load image', style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentImageIndex + 1} / ${widget.product.images.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfo() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      '\$${widget.product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue),
                    ),
                    if (widget.product.discountPrice != null)
                      Text(
                        '\$${widget.product.discountPrice!.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, color: Colors.grey, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildBadge(widget.product.condition?.toUpperCase() ?? 'USED', AppTheme.primaryBlue),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.product.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937), height: 1.3),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.product.location ?? 'Cambodia',
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, yyyy').format(widget.product.createdAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildSpecifications() {
    final Map<String, dynamic> specs = {};
    if (widget.product.category != null) specs['Category'] = widget.product.category!.name;
    
    final List<Widget> specWidgets = [];
    
    // Add Category first
    specWidgets.add(_buildSpecItem('Category', widget.product.category?.name ?? 'General'));

    // Add Dynamic Attributes with proper titles
    if (widget.product.attributeValues != null) {
      widget.product.attributeValues!.forEach((id, value) {
        // Use the label from attributeLabels if available, otherwise fallback to ID
        final String title = widget.product.attributeLabels?[id] ?? id;
        specWidgets.add(_buildSpecItem(title, value.toString()));
      });
    }

    if (specWidgets.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SPECIFICATIONS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 0,
            runSpacing: 0,
            children: specWidgets,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Container(
      width: (MediaQuery.of(context).size.width - 40) / 2,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(), 
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF374151)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text(
            widget.product.description,
            style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    if (widget.product.lat == null || widget.product.lng == null) {
      if (widget.product.address == null) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 1),
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LOCATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Text(widget.product.address!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LOCATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
              TextButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.map_outlined, size: 14, color: AppTheme.primaryBlue),
                label: const Text('VIEW ON MAP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.product.address != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(widget.product.address!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          InkWell(
            onTap: _openMap,
            child: Container(
              height: 180,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(widget.product.lat!, widget.product.lng!),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      tileProvider: NetworkTileProvider(
                        headers: {
                          'User-Agent': 'SabayShopApp/1.0.0 (com.sabay.shop; contact@sabay.com)',
                        },
                      ),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(widget.product.lat!, widget.product.lng!),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    final phoneData = widget.product.posterPhones;
    List<String> phones = [];
    if (phoneData != null) {
      try {
        final decoded = jsonDecode(phoneData);
        if (decoded is List) {
          phones = decoded.map((e) => e.toString()).toList();
        } else {
          phones = [phoneData];
        }
      } catch (e) {
        phones = [phoneData];
      }
    }

    if (phones.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONTACT SELLER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          ...phones.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.phone_in_talk, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    p, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => launchUrl(Uri.parse('tel:$p')),
                  child: const Text('CALL NOW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.green)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSellerSection() {
    final seller = widget.product.seller;
    if (seller == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFF3F4F6),
                backgroundImage: seller.avatar != null ? CachedNetworkImageProvider(ApiEndpoints.getImageUrl(seller.avatar)) : null,
                child: seller.avatar == null ? Text(seller.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seller.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1F2937))),
                    const SizedBox(height: 2),
                    Text(
                      seller.accountType.toUpperCase(),
                      style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_checkAuth()) {
                     final profileRepo = ref.read(profileRepositoryProvider);
                     profileRepo.toggleFollow(seller.id);
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Followed successfully!'), duration: Duration(seconds: 1)),
                     );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('FOLLOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('${RouteName.publicProfile}/${seller.id}');
                  },
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('VIEW STORE'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.product.seller != null) {
                  if (_checkAuth()) {
                    context.push(RouteName.chatDetail, extra: widget.product.seller!);
                  }
                }
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: const Text('CHAT WITH SELLER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
