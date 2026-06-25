class PermissionModel {
  final int id;
  final String name;
  final String displayName;
  final String group;

  PermissionModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.group,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      group: json['group'] ?? 'Other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'group': group,
    };
  }
}
