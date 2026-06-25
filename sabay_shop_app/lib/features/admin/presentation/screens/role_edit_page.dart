import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sabay_shop_app/features/admin/data/repositories/admin_repository.dart';
import 'package:sabay_shop_app/features/auth/data/models/role_model.dart';
import 'package:sabay_shop_app/features/auth/data/models/permission_model.dart';
import 'role_management_page.dart';

class RoleEditPage extends ConsumerStatefulWidget {
  final RoleModel? role;

  const RoleEditPage({super.key, this.role});

  @override
  ConsumerState<RoleEditPage> createState() => _RoleEditPageState();
}

class _RoleEditPageState extends ConsumerState<RoleEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _displayNameController;
  late TextEditingController _descriptionController;
  List<int> _selectedPermissions = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.name);
    _displayNameController = TextEditingController(text: widget.role?.displayName);
    _descriptionController = TextEditingController(text: widget.role?.description);
    _selectedPermissions = widget.role?.permissions.map((p) => p.id).toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (widget.role == null) {
        await ref.read(adminRepositoryProvider).createRole(
              _nameController.text,
              _displayNameController.text,
              _descriptionController.text,
              _selectedPermissions,
            );
      } else {
        await ref.read(adminRepositoryProvider).updateRole(
              widget.role!.id,
              _nameController.text,
              _displayNameController.text,
              _descriptionController.text,
              _selectedPermissions,
            );
      }
      ref.invalidate(rolesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving role: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionsAsync = ref.watch(permissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role == null ? 'Create Role' : 'Edit Role'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Internal Name (e.g. manager)'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              readOnly: widget.role?.name == 'admin',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 24),
            const Text('Permissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            permissionsAsync.when(
              data: (groupedPermissions) {
                return Column(
                  children: groupedPermissions.entries.map((entry) {
                    return ExpansionTile(
                      title: Text(entry.key),
                      initiallyExpanded: true,
                      children: entry.value.map((permission) {
                        return CheckboxListTile(
                          title: Text(permission.displayName),
                          value: _selectedPermissions.contains(permission.id),
                          onChanged: widget.role?.name == 'admin' 
                            ? null 
                            : (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedPermissions.add(permission.id);
                                  } else {
                                    _selectedPermissions.remove(permission.id);
                                  }
                                });
                              },
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading permissions: $err'),
            ),
          ],
        ),
      ),
    );
  }
}

final permissionsProvider = FutureProvider.autoDispose<Map<String, List<PermissionModel>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getPermissions();
});
