// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomeBannerController)
final homeBannerControllerProvider = HomeBannerControllerProvider._();

final class HomeBannerControllerProvider
    extends $AsyncNotifierProvider<HomeBannerController, List<BannerEntity>> {
  HomeBannerControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'homeBannerControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$homeBannerControllerHash();

  @$internal
  @override
  HomeBannerController create() => HomeBannerController();
}

String _$homeBannerControllerHash() =>
    r'b78b6e70d33ad473043745e6bb3d23b9e4442701';

abstract class _$HomeBannerController
    extends $AsyncNotifier<List<BannerEntity>> {
  FutureOr<List<BannerEntity>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<BannerEntity>>, List<BannerEntity>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<BannerEntity>>, List<BannerEntity>>,
        AsyncValue<List<BannerEntity>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
