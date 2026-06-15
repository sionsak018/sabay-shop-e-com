// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatController)
final chatControllerProvider = ChatControllerProvider._();

final class ChatControllerProvider
    extends $AsyncNotifierProvider<ChatController, List<MessageEntity>> {
  ChatControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'chatControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$chatControllerHash();

  @$internal
  @override
  ChatController create() => ChatController();
}

String _$chatControllerHash() => r'aee42823b00f827a403f85b651e1a26cff4d7226';

abstract class _$ChatController extends $AsyncNotifier<List<MessageEntity>> {
  FutureOr<List<MessageEntity>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<MessageEntity>>, List<MessageEntity>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<MessageEntity>>, List<MessageEntity>>,
        AsyncValue<List<MessageEntity>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
