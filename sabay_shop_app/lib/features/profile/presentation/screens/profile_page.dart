import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sabay_shop_app/core/router/route_name.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sabay_shop_app/core/network/api_endpoints.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sabay_shop_app/features/products/presentation/screens/favorites_page.dart';
import 'package:sabay_shop_app/features/profile/presentation/screens/edit_profile_page.dart';
import 'package:sabay_shop_app/features/products/presentation/screens/my_products_page.dart';
import 'package:sabay_shop_app/features/profile/presentation/screens/public_profile_page.dart';
import 'package:sabay_shop_app/features/profile/presentation/screens/store_dashboard_page.dart';
import 'package:sabay_shop_app/features/profile/presentation/screens/security_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      skipLoadingOnRefresh: false,
      data: (user) {
        if (user == null) {
          return _buildGuestView(context, ref);
        }
        return _ProfileView(user: user);
      },
      loading: () => _ProfileSkeleton(),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildGuestView(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(authControllerProvider);
          await ref.read(authControllerProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_pin_rounded, size: 100, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 32),
                const Text('Welcome to Sabay Shop', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF1F2937))),
                const SizedBox(height: 12),
                const Text(
                  'Join our community to start selling and buying products today!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push(RouteName.login),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('GET STARTED', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  final UserEntity user;
  const _ProfileView({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double coverHeight = 180.0;
    const double avatarSize = 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(authControllerProvider);
          await ref.read(authControllerProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          clipBehavior: Clip.none,
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Cover Photo
                  _buildCover(coverHeight),

                  // 2. White Content Container (starts at cover end)
                  Container(
                    margin: const EdgeInsets.only(top: coverHeight),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: avatarSize / 2 + 16), // Half of avatar + spacing
                        _buildUserInfo(context),
                        const SizedBox(height: 32),
                        _buildStatsRow(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // 3. Avatar (Floats perfectly in the middle of divider line)
                  Positioned(
                    top: coverHeight - (avatarSize / 2),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildAvatar(avatarSize),
                    ),
                  ),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildMenuSection(context, ref),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(color: AppTheme.primaryBlue),
      child: user.coverPhoto != null
          ? CachedNetworkImage(
              imageUrl: ApiEndpoints.getImageUrl(user.coverPhoto!), 
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: AppTheme.primaryBlue.withOpacity(0.1)),
              errorWidget: (context, url, error) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, Color(0xFF1E40AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
    );
  }

  Widget _buildAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipOval(
        child: user.avatar != null
            ? CachedNetworkImage(
                imageUrl: ApiEndpoints.getImageUrl(user.avatar!),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.white),
                errorWidget: (context, url, error) => Container(
                  color: Colors.white,
                  child: Center(
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', 
                        style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)),
                  ),
                ),
              )
            : Container(
                color: Colors.white,
                child: Center(
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', 
                      style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue)),
                ),
              ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      children: [
        Text(
          user.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        if (user.location != null && user.location!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  user.location!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: AppTheme.primaryBlue, size: 14),
              const SizedBox(width: 6),
              Text(
                '${user.accountType.toUpperCase()} • ADS: ${user.adsCount}/${user.postLimit}',
                style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(context, user.adsCount.toString(), 'MY ADS', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreDashboardPage()))),
        _buildStatDivider(),
        _buildStatItem(context, user.followersCount.toString(), 'FOLLOWERS', () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfilePage(userId: user.id)))),
        _buildStatDivider(),
        _buildStatItem(context, user.followingCount.toString(), 'FOLLOWING', () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfilePage(userId: user.id)))),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String val, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() => Container(width: 1, height: 25, color: const Color(0xFFF1F5F9));

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionCard(context, Icons.dashboard_customize_outlined, 'DASHBOARD', const Color(0xFF6366F1), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreDashboardPage()));
        }),
        const SizedBox(width: 16),
        _buildActionCard(context, Icons.favorite_rounded, 'FAVORITES', const Color(0xFFF43F5E), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
        }),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile(Icons.person_outline_rounded, 'Edit Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(user: user)))),
          _buildMenuTile(Icons.notifications_none_rounded, 'Notifications', () {}),
          _buildMenuTile(Icons.security_rounded, 'Security & Privacy', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityPage()))),
          _buildMenuTile(Icons.help_outline_rounded, 'Help & Support', () {}),
          const Divider(height: 1, color: Color(0xFFF8F9FD)),
          ListTile(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w900)),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authControllerProvider.notifier).logout();
                      },
                      child: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              );
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: const Color(0xFF4B5563), size: 24),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF374151))),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB), size: 20),
    );
  }
}

class _ProfileSkeleton extends ConsumerWidget {
  const _ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(authControllerProvider);
          await ref.read(authControllerProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(height: 180, width: double.infinity, color: Colors.white),
              ),
              Transform.translate(
                offset: const Offset(0, -50),
                child: Column(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(width: 150, height: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(3, (index) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(width: 80, height: 40, color: Colors.white),
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
