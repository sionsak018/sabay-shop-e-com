import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/core/router/route_name.dart';
import 'package:sabay_shop_app/features/home/presentation/screens/home_screen.dart';
import 'package:sabay_shop_app/features/products/presentation/screens/product_list_page.dart';
import 'package:sabay_shop_app/features/products/presentation/screens/product_create_page.dart';
import 'package:sabay_shop_app/features/chat/presentation/screens/inbox_page.dart';
import 'package:sabay_shop_app/features/profile/presentation/screens/profile_page.dart';
import 'package:sabay_shop_app/features/profile/presentation/screens/public_profile_page.dart';
import 'package:sabay_shop_app/features/auth/presentation/login_screen.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sabay_shop_app/features/chat/presentation/screens/chat_detail_page.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';

part 'app_router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: RouteName.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteName.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteName.products,
                builder: (context, state) {
                  final categoryId = state.uri.queryParameters['category_id'];
                  final search = state.uri.queryParameters['search'];
                  return ProductListPage(
                    initialCategoryId: categoryId,
                    initialSearch: search,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteName.sell,
                builder: (context, state) => const ProductCreatePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteName.messages,
                builder: (context, state) => const InboxPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteName.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteName.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteName.chatDetail,
        builder: (context, state) {
          final partner = state.extra as UserEntity;
          return ChatDetailPage(partner: partner);
        },
      ),
      GoRoute(
        path: '${RouteName.publicProfile}/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PublicProfilePage(userId: id);
        },
      ),
    ],
  );
}

class ScaffoldWithBottomNavBar extends ConsumerWidget {
  const ScaffoldWithBottomNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    if (index == 2 || index == 3) {
      final authState = ref.read(authControllerProvider);
      
      // If the auth state is still loading (e.g., after hot reload),
      // we don't want to redirect to login immediately because we might be logged in.
      if (authState.isLoading) {
        navigationShell.goBranch(index);
        return;
      }

      if (authState.value == null) {
        context.push(RouteName.login);
        return;
      }
    }
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.only(
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom > 0 
                ? MediaQuery.of(context).padding.bottom * 0.4 
                : 8, 
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, ref, 0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(context, ref, 1, Icons.menu, Icons.menu, 'Products'),
              _buildAddButton(context, ref, 2, 'Sell'),
              _buildNavItem(context, ref, 3, Icons.chat_bubble_outline, Icons.chat_bubble, 'Inbox'),
              _buildNavItem(context, ref, 4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, WidgetRef ref, int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = navigationShell.currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTap(context, ref, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? AppTheme.primaryBlue : Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                color: isSelected ? AppTheme.primaryBlue : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref, int index, String label) {
    final isSelected = navigationShell.currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTap(context, ref, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                color: isSelected ? AppTheme.primaryBlue : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
