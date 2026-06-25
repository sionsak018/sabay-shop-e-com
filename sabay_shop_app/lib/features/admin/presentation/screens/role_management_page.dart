import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sabay_shop_app/features/admin/data/repositories/admin_repository.dart';
import 'package:sabay_shop_app/features/auth/data/models/role_model.dart';
import 'role_edit_page.dart';

class RoleManagementPage extends ConsumerWidget {
  const RoleManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoleEditPage()),
            ),
          ),
        ],
      ),
      body: rolesAsync.when(
        data: (roles) => ListView.builder(
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final role = roles[index];
            return ListTile(
              title: Text(role.displayName),
              subtitle: Text(role.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoleEditPage(role: role),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

final rolesProvider = FutureProvider.autoDispose<List<RoleModel>>((ref) async {
  return ref.watch(adminRepositoryProvider).getRoles();
});
