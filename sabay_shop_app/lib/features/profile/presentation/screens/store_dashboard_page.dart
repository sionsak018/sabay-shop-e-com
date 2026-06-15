import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sabay_shop_app/core/theme/app_theme.dart';
import 'package:sabay_shop_app/features/products/presentation/screens/my_products_page.dart';
import 'package:sabay_shop_app/features/auth/presentation/controllers/auth_controller.dart';

class StoreDashboardPage extends ConsumerWidget {
  const StoreDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('STORE DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(authControllerProvider);
          await ref.read(authControllerProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(user?.name ?? 'Seller'),
              const SizedBox(height: 24),
              _buildStatsOverview(user),
              const SizedBox(height: 32),
              _buildSectionTitle('AD MANAGEMENT'),
              const SizedBox(height: 16),
              _buildDashboardMenu(
                context,
                Icons.storefront_outlined,
                'Manage My Ads',
                '${user?.adsCount ?? 0} Active Listings',
                Colors.blue,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProductsPage())),
              ),
              const SizedBox(height: 12),
              _buildDashboardMenu(
                context,
                Icons.analytics_outlined,
                'View Insights',
                'Performance and views',
                Colors.orange,
                () {},
              ),
              const SizedBox(height: 12),
              _buildDashboardMenu(
                context,
                Icons.stars_outlined,
                'Store Reviews',
                'See what buyers say',
                Colors.purple,
                () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hello, $name 👋', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Welcome to your store control center.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(dynamic user) {
    return Row(
      children: [
        _buildMiniStat('Active Ads', user?.adsCount.toString() ?? '0', Colors.blue),
        const SizedBox(width: 16),
        _buildMiniStat('Followers', user?.followersCount.toString() ?? '0', Colors.green),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1F2937), letterSpacing: 1));
  }

  Widget _buildDashboardMenu(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1F2937))),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
