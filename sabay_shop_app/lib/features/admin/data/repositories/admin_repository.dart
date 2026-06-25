import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/core/network/repositories/dio_provider.dart';
import 'package:sabay_shop_app/features/auth/data/models/role_model.dart';
import 'package:sabay_shop_app/features/auth/data/models/permission_model.dart';

part 'admin_repository.g.dart';

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  Future<List<RoleModel>> getRoles() async {
    final response = await _dio.get('/admin/roles');
    return (response.data as List).map((e) => RoleModel.fromJson(e)).toList();
  }

  Future<Map<String, List<PermissionModel>>> getPermissions() async {
    final response = await _dio.get('/admin/permissions');
    final data = response.data as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(
          key,
          (value as List).map((e) => PermissionModel.fromJson(e)).toList(),
        ));
  }

  Future<RoleModel> createRole(String name, String displayName, String? description, List<int> permissions) async {
    final response = await _dio.post('/admin/roles', data: {
      'name': name,
      'display_name': displayName,
      'description': description,
      'permissions': permissions,
    });
    return RoleModel.fromJson(response.data);
  }

  Future<RoleModel> updateRole(int id, String name, String displayName, String? description, List<int> permissions) async {
    final response = await _dio.put('/admin/roles/$id', data: {
      'name': name,
      'display_name': displayName,
      'description': description,
      'permissions': permissions,
    });
    return RoleModel.fromJson(response.data);
  }

  Future<void> deleteRole(int id) async {
    await _dio.delete('/admin/roles/$id');
  }

  Future<void> assignRoleToUser(int userId, List<int> roleIds) async {
    await _dio.put('/admin/users/$userId', data: {
      'roles': roleIds,
    });
  }
}

@riverpod
AdminRepository adminRepository(Ref ref) {
  return AdminRepository(ref.watch(dioProvider));
}
