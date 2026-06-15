// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CategoryController)
final categoryControllerProvider = CategoryControllerProvider._();

final class CategoryControllerProvider
    extends $AsyncNotifierProvider<CategoryController, List<CategoryEntity>> {
  CategoryControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'categoryControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$categoryControllerHash();

  @$internal
  @override
  CategoryController create() => CategoryController();
}

String _$categoryControllerHash() =>
    r'25891900d04113dd3862b2296af95fa0c723d7a7';

abstract class _$CategoryController
    extends $AsyncNotifier<List<CategoryEntity>> {
  FutureOr<List<CategoryEntity>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<List<CategoryEntity>>, List<CategoryEntity>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<CategoryEntity>>, List<CategoryEntity>>,
        AsyncValue<List<CategoryEntity>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
