import 'package:sabay_shop_app/features/chat/domain/entities/message_entity.dart';
import 'package:sabay_shop_app/features/auth/data/models/user_model.dart';
import 'package:sabay_shop_app/features/products/data/models/product_model.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.fromUserId,
    required super.toUserId,
    super.productId,
    required super.content,
    super.type = 'text',
    super.filePath,
    required super.isRead,
    super.fromUser,
    super.toUser,
    super.product,
    super.reactions = const [],
    required super.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      fromUserId: json['from_user_id'] is int ? json['from_user_id'] : (int.tryParse(json['from_user_id']?.toString() ?? '') ?? 0),
      toUserId: json['to_user_id'] is int ? json['to_user_id'] : (int.tryParse(json['to_user_id']?.toString() ?? '') ?? 0),
      productId: json['product_id'] != null ? (json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id'].toString())) : null,
      content: json['message'] ?? '', 
      type: json['type'] ?? 'text',
      filePath: json['file_path'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      fromUser: json['from_user'] != null ? UserModel.fromJson(json['from_user']) : null,
      toUser: json['to_user'] != null ? UserModel.fromJson(json['to_user']) : null,
      product: json['product'] != null ? ProductModel.fromJson(json['product']) : null,
      reactions: (json['reactions'] as List? ?? [])
          .map((r) => MessageReactionModel.fromJson(r))
          .toList(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class MessageReactionModel extends MessageReactionEntity {
  const MessageReactionModel({
    required super.id,
    required super.messageId,
    required super.userId,
    required super.emoji,
  });

  factory MessageReactionModel.fromJson(Map<String, dynamic> json) {
    return MessageReactionModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      messageId: json['message_id'] is int ? json['message_id'] : (int.tryParse(json['message_id']?.toString() ?? '') ?? 0),
      userId: json['user_id'] is int ? json['user_id'] : (int.tryParse(json['user_id']?.toString() ?? '') ?? 0),
      emoji: json['emoji'] ?? '',
    );
  }
}
