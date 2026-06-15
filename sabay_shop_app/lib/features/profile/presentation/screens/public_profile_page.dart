import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sabay_shop_app/core/router/route_name.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:sabay_shop_app/features/products/domain/entities/product_entity.dart';
import 'package:sabay_shop_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:sabay_shop_app/features/products/presentation/controllers/product_controller.dart';
import 'package:sabay_shop_app/features/products/presentation/widgets/product_card.dart';
import 'package:sabay_shop_app/features/products/presentation/screens/product_detail_page.dart';
import 'package:sabay_shop_app/core/network/api_endpoints.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:intl/intl.dart';

class PublicProfilePage extends ConsumerStatefulWidget {
  final int userId;
  const PublicProfilePage({super.key, required this.userId});

  @override
  ConsumerState<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends ConsumerState<PublicProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileControllerProvider(widget.userId));

    return profileAsync.when(
      data: (user) {
        final productsAsync = ref.watch(productListControllerProvider(userId: user.id.toString()));
        
        int currentCount = 0;
        switch (_tabController.index) {
          case 0: // STORE HOME
            if (productsAsync.hasValue) {
              currentCount = productsAsync.value!.where((p) => p.seller?.id == user.id).length;
            } else {
              currentCount = user.adsCount;
            }
            break;
          case 1: // ABOUT
            currentCount = 0; 
            break;
          case 2: // FOLLOWERS
            currentCount = user.followersCount;
            break;
          case 3: // FOLLOWING
            currentCount = user.followingCount;
            break;
        }
        
        bool canScroll = false;
        if (_tabController.index == 0) {
          canScroll = currentCount > 4; 
        } else if (_tabController.index == 1) {
          canScroll = false; 
        } else {
          canScroll = currentCount > 8; 
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF1F2F6),
          body: NestedScrollView(
            physics: canScroll
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(child: _buildWebStyleHeader(user, user.adsCount)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: AppTheme.primaryBlue,
                        unselectedLabelColor: Colors.grey[400],
                        indicatorColor: AppTheme.primaryBlue,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        tabs: const [
                          Tab(text: 'STORE HOME'),
                          Tab(text: 'ABOUT'),
                          Tab(text: 'FOLLOWERS'),
                          Tab(text: 'FOLLOWING'),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              physics: canScroll 
                  ? const ClampingScrollPhysics() 
                  : const NeverScrollableScrollPhysics(),
              children: [
                _StoreHomeTab(userId: user.id),
                _AboutTab(user: user),
                _UserListTab(userId: user.id, type: 'followers'),
                _UserListTab(userId: user.id, type: 'following'),
              ],
            ),
          ),
        );
      },
      loading: () => _PublicProfileSkeleton(),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildWebStyleHeader(UserEntity user, int adsCount) {
    final avatarUrl = user.avatar != null && user.avatar!.isNotEmpty ? ApiEndpoints.getImageUrl(user.avatar!) : '';
    final coverUrl = user.coverPhoto != null && user.coverPhoto!.isNotEmpty ? ApiEndpoints.getImageUrl(user.coverPhoto!) : '';

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: coverUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: coverUrl, 
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.black12),
                        errorWidget: (context, url, error) => const SizedBox.shrink(),
                      )
                    : null,
              ),
              Positioned(
                bottom: -35,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryBlue),
                    child: ClipOval(
                      child: avatarUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.white),
                              errorWidget: (context, url, error) => Center(child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white))),
                            )
                          : Center(child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white))),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 45),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name.toUpperCase(),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFDBEAFE))),
                            child: const Row(
                              children: [
                                Icon(Icons.verified, color: AppTheme.primaryBlue, size: 10),
                                SizedBox(width: 3),
                                Text('VERIFIED', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 8, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                (user.location ?? 'Cambodia').toUpperCase(),
                                style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'SINCE ${DateFormat('yyyy').format(user.createdAt ?? DateTime.now())}',
                                style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildWebStatItem('Ads', adsCount.toString(), () => _tabController.animateTo(0)),
                _buildStatDivider(),
                _buildWebStatItem('Followers', user.followersCount.toString(), () => _tabController.animateTo(2)),
                _buildStatDivider(),
                _buildWebStatItem('Following', user.followingCount.toString(), () => _tabController.animateTo(3)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                       final authState = ref.read(authControllerProvider);
                       if (authState.value == null && !authState.isLoading) {
                         context.push(RouteName.login);
                         return;
                       }
                       ref.read(userProfileControllerProvider(widget.userId).notifier).toggleFollow();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.isFollowing ? Colors.white : AppTheme.primaryBlue,
                      foregroundColor: user.isFollowing ? AppTheme.primaryBlue : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: user.isFollowing ? const BorderSide(color: AppTheme.primaryBlue, width: 1.5) : BorderSide.none,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      user.isFollowing ? 'FOLLOWING' : 'FOLLOW STORE', 
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF4B5563), size: 20),
                    onPressed: () {
                      final authState = ref.read(authControllerProvider);
                      if (authState.value == null && !authState.isLoading) {
                        context.push(RouteName.login);
                        return;
                      }
                      context.push(RouteName.chatDetail, extra: user);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWebStatItem(String label, String val, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() => Container(width: 1, height: 25, color: Colors.grey[100]);
}

class _PublicProfileSkeleton extends StatelessWidget {
  const _PublicProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(height: 180, width: double.infinity, color: Colors.white),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(width: 200, height: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(width: 150, height: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreHomeTab extends ConsumerWidget {
  final int userId;
  const _StoreHomeTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListControllerProvider(userId: userId.toString()));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productListControllerProvider(userId: userId.toString()));
      },
      child: productsAsync.when(
        data: (products) {
          final filteredProducts = products.where((p) => p.seller?.id == userId).toList();
          if (filteredProducts.isEmpty) {
            return const Center(child: Text('No listings yet.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) => ProductCard(
              product: filteredProducts[index],
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: filteredProducts[index]))),
              onFavoriteTap: () {
                final authState = ref.read(authControllerProvider);
                if (authState.value == null && !authState.isLoading) {
                  context.push(RouteName.login);
                } else {
                  ref.read(productListControllerProvider(userId: userId.toString()).notifier)
                      .toggleFavorite(filteredProducts[index].id, currentStatus: filteredProducts[index].isFavorited);
                }
              },
            ),
          );
        },
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(12),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
          ),
        ),
        error: (err, __) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  final UserEntity user;
  const _AboutTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildInfoCard('BIOGRAPHY', user.aboutMe ?? 'This user prefers to keep their bio a mystery.', Icons.notes_rounded),
          const SizedBox(height: 12),
          _buildInfoCard('CONTACT INFO', 'Email: ${user.email}\nPhone: ${user.phone ?? "N/A"}', Icons.contact_mail_outlined),
          const SizedBox(height: 12),
          _buildInfoCard('LOCATION', user.location ?? 'Cambodia', Icons.location_on_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 14, color: AppTheme.primaryBlue), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1.5))]),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF374151), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _UserListTab extends ConsumerWidget {
  final int userId;
  final String type;
  const _UserListTab({required this.userId, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = type == 'followers' 
      ? ref.watch(userFollowersControllerProvider(userId))
      : ref.watch(userFollowingControllerProvider(userId));

    return listAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(child: Text('No $type yet.', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final u = users[index];
            final avatarUrl = u.avatar != null && u.avatar!.isNotEmpty ? ApiEndpoints.getImageUrl(u.avatar!) : '';
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: ListTile(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PublicProfilePage(userId: u.id))),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFF3F4F6),
                  backgroundImage: avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                  child: avatarUrl.isEmpty ? Text(u.name[0].toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)) : null,
                ),
                title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1F2937))),
                subtitle: Text(u.accountType.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, letterSpacing: 0.5)),
                trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ),
            );
          },
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 70,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      error: (err, __) => Center(child: Text('Error: $err')),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final Widget _tabBar;
  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 44;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => _tabBar;
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
