// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(messageRepository)
final messageRepositoryProvider = MessageRepositoryProvider._();

final class MessageRepositoryProvider extends $FunctionalProvider<
    MessageRepository,
    MessageRepository,
    MessageRepository> with $Provider<MessageRepository> {
  MessageRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'messageRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$messageRepositoryHash();

  @$internal
  @override
  $ProviderElement<MessageRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MessageRepository create(Ref ref) {
    return messageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageRepository>(value),
    );
  }
}

String _$messageRepositoryHash() => r'5698a7cd7b3190f4130362607cec303465c21473';
