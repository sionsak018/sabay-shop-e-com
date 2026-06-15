import 'dart:io';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/core/network/repositories/base_repository.dart';
import 'package:sabay_shop_app/core/network/repositories/dio_provider.dart';
import 'package:sabay_shop_app/features/chat/data/models/message_model.dart';
import 'package:sabay_shop_app/features/chat/domain/entities/message_entity.dart';
import 'package:sabay_shop_app/features/chat/domain/repositories/message_repository.dart';

part 'message_repository_impl.g.dart';

class MessageRepositoryImpl extends BaseRepository implements MessageRepository {
  final Dio dio;

  MessageRepositoryImpl(this.dio);

  @override
  Future<List<MessageEntity>> getMessages() async {
    return mapException(() async {
      final response = await dio.get('/messages');
      final List data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map((json) => MessageModel.fromJson(json)).toList();
    });
  }

  @override
  Future<MessageEntity> sendMessage({
    required int toUserId,
    String? message,
    int? productId,
    String type = 'text',
    File? file,
  }) async {
    return mapException(() async {
      final Map<String, dynamic> data = {
        'to_user_id': toUserId,
        if (message != null) 'message': message,
        if (productId != null) 'product_id': productId,
        'type': type,
      };

      if (file != null) {
        data['file'] = await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        );
      }

      final formData = FormData.fromMap(data);
      final response = await dio.post('/messages', data: formData);
      
      // The backend might return { data: { ... } } or just { ... }
      final json = response.data is Map<String, dynamic> && response.data.containsKey('data') 
          ? response.data['data'] 
          : response.data;
          
      return MessageModel.fromJson(json);
    });
  }

  @override
  Future<void> reactToMessage(int messageId, String emoji) async {
    return mapException(() async {
      await dio.post('/messages/$messageId/react', data: {'emoji': emoji});
    });
  }

  @override
  Future<void> markAsRead(int messageId) async {
    return mapException(() async {
      await dio.post('/messages/$messageId/read', data: {'_method': 'PUT'});
    });
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    return mapException(() async {
      await dio.delete('/messages/$messageId');
    });
  }
}

@riverpod
MessageRepository messageRepository(Ref ref) {
  return MessageRepositoryImpl(ref.watch(dioProvider));
}
