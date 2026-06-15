// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserProfileController)
final userProfileControllerProvider = UserProfileControllerFamily._();

final class UserProfileControllerProvider
    extends $AsyncNotifierProvider<UserProfileController, UserEntity> {
  UserProfileControllerProvider._(
      {required UserProfileControllerFamily super.from,
      required int super.argument})
      : super(
          retry: null,
          name: r'userProfileControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userProfileControllerHash();

  @override
  String toString() {
    return r'userProfileControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserProfileController create() => UserProfileController();

  @override
  bool operator ==(Object other) {
    return other is UserProfileControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userProfileControllerHash() =>
    r'f267a5e0c430168f5d52ac129043b2c34741baee';

final class UserProfileControllerFamily extends $Family
    with
        $ClassFamilyOverride<UserProfileController, AsyncValue<UserEntity>,
            UserEntity, FutureOr<UserEntity>, int> {
  UserProfileControllerFamily._()
      : super(
          retry: null,
          name: r'userProfileControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  UserProfileControllerProvider call(
    int userId,
  ) =>
      UserProfileControllerProvider._(argument: userId, from: this);

  @override
  String toString() => r'userProfileControllerProvider';
}

abstract class _$UserProfileController extends $AsyncNotifier<UserEntity> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  FutureOr<UserEntity> build(
    int userId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserEntity>, UserEntity>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<UserEntity>, UserEntity>,
        AsyncValue<UserEntity>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

@ProviderFor(UserFollowersController)
final userFollowersControllerProvider = UserFollowersControllerFamily._();

final class UserFollowersControllerProvider
    extends $AsyncNotifierProvider<UserFollowersController, List<UserEntity>> {
  UserFollowersControllerProvider._(
      {required UserFollowersControllerFamily super.from,
      required int super.argument})
      : super(
          retry: null,
          name: r'userFollowersControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userFollowersControllerHash();

  @override
  String toString() {
    return r'userFollowersControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserFollowersController create() => UserFollowersController();

  @override
  bool operator ==(Object other) {
    return other is UserFollowersControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userFollowersControllerHash() =>
    r'7a56d41ac2f76c795c565bdd520e0fc4c9726f02';

final class UserFollowersControllerFamily extends $Family
    with
        $ClassFamilyOverride<
            UserFollowersController,
            AsyncValue<List<UserEntity>>,
            List<UserEntity>,
            FutureOr<List<UserEntity>>,
            int> {
  UserFollowersControllerFamily._()
      : super(
          retry: null,
          name: r'userFollowersControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  UserFollowersControllerProvider call(
    int userId,
  ) =>
      UserFollowersControllerProvider._(argument: userId, from: this);

  @override
  String toString() => r'userFollowersControllerProvider';
}

abstract class _$UserFollowersController
    extends $AsyncNotifier<List<UserEntity>> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  FutureOr<List<UserEntity>> build(
    int userId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<UserEntity>>, List<UserEntity>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<UserEntity>>, List<UserEntity>>,
        AsyncValue<List<UserEntity>>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

@ProviderFor(UserFollowingController)
final userFollowingControllerProvider = UserFollowingControllerFamily._();

final class UserFollowingControllerProvider
    extends $AsyncNotifierProvider<UserFollowingController, List<UserEntity>> {
  UserFollowingControllerProvider._(
      {required UserFollowingControllerFamily super.from,
      required int super.argument})
      : super(
          retry: null,
          name: r'userFollowingControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userFollowingControllerHash();

  @override
  String toString() {
    return r'userFollowingControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserFollowingController create() => UserFollowingController();

  @override
  bool operator ==(Object other) {
    return other is UserFollowingControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userFollowingControllerHash() =>
    r'd364ba02299bc06a1f1dfbd98c7cb7081e219e6a';

final class UserFollowingControllerFamily extends $Family
    with
        $ClassFamilyOverride<
            UserFollowingController,
            AsyncValue<List<UserEntity>>,
            List<UserEntity>,
            FutureOr<List<UserEntity>>,
            int> {
  UserFollowingControllerFamily._()
      : super(
          retry: null,
          name: r'userFollowingControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  UserFollowingControllerProvider call(
    int userId,
  ) =>
      UserFollowingControllerProvider._(argument: userId, from: this);

  @override
  String toString() => r'userFollowingControllerProvider';
}

abstract class _$UserFollowingController
    extends $AsyncNotifier<List<UserEntity>> {
  late final _$args = ref.$arg as int;
  int get userId => _$args;

  FutureOr<List<UserEntity>> build(
    int userId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<UserEntity>>, List<UserEntity>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<UserEntity>>, List<UserEntity>>,
        AsyncValue<List<UserEntity>>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
