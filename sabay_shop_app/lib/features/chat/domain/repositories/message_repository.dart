import 'dart:io';
import 'package:sabay_shop_app/features/chat/domain/entities/message_entity.dart';

abstract class MessageRepository {
  Future<List<MessageEntity>> getMessages();
  Future<MessageEntity> sendMessage({
    required int toUserId,
    String? message,
    int? productId,
    String type = 'text',
    File? file,
  });
  Future<void> reactToMessage(int messageId, String emoji);
  Future<void> markAsRead(int messageId);
  Future<void> deleteMessage(int messageId);
}
