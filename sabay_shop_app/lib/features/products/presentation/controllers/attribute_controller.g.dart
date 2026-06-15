// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attribute_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CategoryAttributeController)
final categoryAttributeControllerProvider =
    CategoryAttributeControllerFamily._();

final class CategoryAttributeControllerProvider extends $AsyncNotifierProvider<
    CategoryAttributeController, List<CategoryAttributeEntity>> {
  CategoryAttributeControllerProvider._(
      {required CategoryAttributeControllerFamily super.from,
      required int super.argument})
      : super(
          retry: null,
          name: r'categoryAttributeControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$categoryAttributeControllerHash();

  @override
  String toString() {
    return r'categoryAttributeControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CategoryAttributeController create() => CategoryAttributeController();

  @override
  bool operator ==(Object other) {
    return other is CategoryAttributeControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categoryAttributeControllerHash() =>
    r'd51facbee8711ea7912d55c1473e4abb9bf5294a';

final class CategoryAttributeControllerFamily extends $Family
    with
        $ClassFamilyOverride<
            CategoryAttributeController,
            AsyncValue<List<CategoryAttributeEntity>>,
            List<CategoryAttributeEntity>,
            FutureOr<List<CategoryAttributeEntity>>,
            int> {
  CategoryAttributeControllerFamily._()
      : super(
          retry: null,
          name: r'categoryAttributeControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  CategoryAttributeControllerProvider call(
    int categoryId,
  ) =>
      CategoryAttributeControllerProvider._(argument: categoryId, from: this);

  @override
  String toString() => r'categoryAttributeControllerProvider';
}

abstract class _$CategoryAttributeController
    extends $AsyncNotifier<List<CategoryAttributeEntity>> {
  late final _$args = ref.$arg as int;
  int get categoryId => _$args;

  FutureOr<List<CategoryAttributeEntity>> build(
    int categoryId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<CategoryAttributeEntity>>,
        List<CategoryAttributeEntity>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<CategoryAttributeEntity>>,
            List<CategoryAttributeEntity>>,
        AsyncValue<List<CategoryAttributeEntity>>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
