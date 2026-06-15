import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatar,
    super.coverPhoto,
    super.aboutMe,
    required super.role,
    required super.accountType,
    super.isFollowing,
    super.followersCount,
    super.followingCount,
    super.adsCount,
    super.postLimit,
    super.location,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
      coverPhoto: json['cover_photo']?.toString(),
      aboutMe: json['about_me']?.toString(),
      role: json['role']?.toString() ?? 'user',
      accountType: json['account_type']?.toString() ?? 'private',
      isFollowing: json['is_following'] == 1 || json['is_following'] == true,
      followersCount: json['followers_count'] is int ? json['followers_count'] : (int.tryParse(json['followers_count']?.toString() ?? '') ?? 0),
      followingCount: json['following_count'] is int ? json['following_count'] : (int.tryParse(json['following_count']?.toString() ?? '') ?? 0),
      adsCount: json['ads_count'] is int ? json['ads_count'] : (int.tryParse(json['ads_count']?.toString() ?? '') ?? 0),
      postLimit: json['post_limit'] is int ? json['post_limit'] : (int.tryParse(json['post_limit']?.toString() ?? '') ?? 0),
      location: _buildLocationString(json),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  static String? _buildLocationString(Map<String, dynamic> json) {
    final province = json['province']?['name'];
    final district = json['district']?['name'];
    final commune = json['commune']?['name'];
    final village = json['village']?['name'];
    
    final parts = [village, commune, district, province].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'cover_photo': coverPhoto,
      'about_me': aboutMe,
      'role': role,
      'account_type': accountType,
    };
  }
}
