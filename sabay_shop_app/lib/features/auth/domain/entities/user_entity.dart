import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String? coverPhoto;
  final String? aboutMe;
  final String role;
  final String accountType;
  final bool isFollowing;
  final int followersCount;
  final int followingCount;
  final int adsCount;
  final int postLimit;
  final String? location;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.coverPhoto,
    this.aboutMe,
    required this.role,
    required this.accountType,
    this.isFollowing = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.adsCount = 0,
    this.postLimit = 0,
    this.location,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        avatar,
        role,
        isFollowing,
        followersCount,
        followingCount,
        adsCount,
        postLimit,
        location,
        createdAt
      ];
}
