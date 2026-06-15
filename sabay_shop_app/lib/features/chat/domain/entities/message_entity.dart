import 'package:equatable/equatable.dart';
import 'package:sabay_shop_app/features/auth/domain/entities/user_entity.dart';
import 'package:sabay_shop_app/features/products/domain/entities/product_entity.dart';

class MessageEntity extends Equatable {
  final int id;
  final int fromUserId;
  final int toUserId;
  final int? productId;
  final String content;
  final String type;
  final String? filePath;
  final bool isRead;
  final UserEntity? fromUser;
  final UserEntity? toUser;
  final ProductEntity? product;
  final List<MessageReactionEntity> reactions;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.productId,
    required this.content,
    this.type = 'text',
    this.filePath,
    required this.isRead,
    this.fromUser,
    this.toUser,
    this.product,
    this.reactions = const [],
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, content, isRead, type, reactions];
}

class MessageReactionEntity extends Equatable {
  final int id;
  final int messageId;
  final int userId;
  final String emoji;

  const MessageReactionEntity({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
  });

  @override
  List<Object?> get props => [id, messageId, userId, emoji];
}
