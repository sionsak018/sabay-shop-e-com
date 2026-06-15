// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banner_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bannerRepository)
final bannerRepositoryProvider = BannerRepositoryProvider._();

final class BannerRepositoryProvider extends $FunctionalProvider<
    BannerRepository,
    BannerRepository,
    BannerRepository> with $Provider<BannerRepository> {
  BannerRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'bannerRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$bannerRepositoryHash();

  @$internal
  @override
  $ProviderElement<BannerRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BannerRepository create(Ref ref) {
    return bannerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BannerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BannerRepository>(value),
    );
  }
}

String _$bannerRepositoryHash() => r'48178df602b8056e691149f6888d90c2dc0a70ba';
