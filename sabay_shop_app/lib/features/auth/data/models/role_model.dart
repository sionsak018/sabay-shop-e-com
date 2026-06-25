import 'permission_model.dart';

class RoleModel {
  final int id;
  final String name;
  final String displayName;
  final String? description;
  final List<PermissionModel> permissions;

  RoleModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.permissions = const [],
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      description: json['description'],
      permissions: (json['permissions'] as List?)
              ?.map((p) => PermissionModel.fromJson(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'description': description,
      'permissions': permissions.map((p) => p.toJson()).toList(),
    };
  }
}
