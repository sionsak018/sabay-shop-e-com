import 'dart:async';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sabay_shop_app/features/chat/domain/entities/message_entity.dart';
import 'package:sabay_shop_app/features/chat/data/repositories/message_repository_impl.dart';

part 'chat_controller.g.dart';

@riverpod
class ChatController extends _$ChatController {
  Timer? _timer;

  @override
  FutureOr<List<MessageEntity>> build() async {
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    _startPolling();
    return _fetchMessages();
  }

  Future<List<MessageEntity>> _fetchMessages() async {
    final repository = ref.read(messageRepositoryProvider);
    return await repository.getMessages();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final messages = await _fetchMessages();
      state = AsyncData(messages);
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchMessages());
  }

  Future<void> sendMessage({
    required int toUserId,
    String? message,
    int? productId,
    String type = 'text',
    File? file,
  }) async {
    final repository = ref.read(messageRepositoryProvider);
    await repository.sendMessage(
      toUserId: toUserId,
      message: message,
      productId: productId,
      type: type,
      file: file,
    );
    // After sending, we might want to refresh immediately
    final messages = await _fetchMessages();
    state = AsyncData(messages);
  }

  Future<void> markAsRead(int messageId) async {
    try {
      final repository = ref.read(messageRepositoryProvider);
      await repository.markAsRead(messageId);
    } catch (e) {
      // Ignore 404s for read markers
    }
  }

  Future<void> react(int messageId, String emoji) async {
    final repository = ref.read(messageRepositoryProvider);
    await repository.reactToMessage(messageId, emoji);
    final messages = await _fetchMessages();
    state = AsyncData(messages);
  }

  Future<void> delete(int messageId) async {
    final repository = ref.read(messageRepositoryProvider);
    await repository.deleteMessage(messageId);
    final messages = await _fetchMessages();
    state = AsyncData(messages);
  }
}
