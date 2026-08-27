// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lock_screen_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single [AndroidLockScreenChannel] instance — kept alive so its
/// `flutter_local_notifications` plugin only initializes once per app run.
/// Exposed both under its concrete type (for
/// [AndroidLockScreenChannel.requestNotificationPermission], which isn't
/// part of the shared interface) and, via [lockScreenChannel] below, under
/// the platform-agnostic [LockScreenChannel] type everything else depends
/// on.

@ProviderFor(androidLockScreenChannel)
final androidLockScreenChannelProvider = AndroidLockScreenChannelProvider._();

/// The single [AndroidLockScreenChannel] instance — kept alive so its
/// `flutter_local_notifications` plugin only initializes once per app run.
/// Exposed both under its concrete type (for
/// [AndroidLockScreenChannel.requestNotificationPermission], which isn't
/// part of the shared interface) and, via [lockScreenChannel] below, under
/// the platform-agnostic [LockScreenChannel] type everything else depends
/// on.

final class AndroidLockScreenChannelProvider
    extends
        $FunctionalProvider<
          AndroidLockScreenChannel,
          AndroidLockScreenChannel,
          AndroidLockScreenChannel
        >
    with $Provider<AndroidLockScreenChannel> {
  /// The single [AndroidLockScreenChannel] instance — kept alive so its
  /// `flutter_local_notifications` plugin only initializes once per app run.
  /// Exposed both under its concrete type (for
  /// [AndroidLockScreenChannel.requestNotificationPermission], which isn't
  /// part of the shared interface) and, via [lockScreenChannel] below, under
  /// the platform-agnostic [LockScreenChannel] type everything else depends
  /// on.
  AndroidLockScreenChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'androidLockScreenChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$androidLockScreenChannelHash();

  @$internal
  @override
  $ProviderElement<AndroidLockScreenChannel> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AndroidLockScreenChannel create(Ref ref) {
    return androidLockScreenChannel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AndroidLockScreenChannel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AndroidLockScreenChannel>(value),
    );
  }
}

String _$androidLockScreenChannelHash() =>
    r'2ea0935ffc9b466feb63f72818cb6fb73fce46cd';

/// The seam the rest of the app (this controller, the background sync
/// callback) depends on. Android-only today — this provider is the one
/// line an iOS follow-up changes (`Platform.isAndroid ? ... : ...`), not
/// any of its callers.

@ProviderFor(lockScreenChannel)
final lockScreenChannelProvider = LockScreenChannelProvider._();

/// The seam the rest of the app (this controller, the background sync
/// callback) depends on. Android-only today — this provider is the one
/// line an iOS follow-up changes (`Platform.isAndroid ? ... : ...`), not
/// any of its callers.

final class LockScreenChannelProvider
    extends
        $FunctionalProvider<
          LockScreenChannel,
          LockScreenChannel,
          LockScreenChannel
        >
    with $Provider<LockScreenChannel> {
  /// The seam the rest of the app (this controller, the background sync
  /// callback) depends on. Android-only today — this provider is the one
  /// line an iOS follow-up changes (`Platform.isAndroid ? ... : ...`), not
  /// any of its callers.
  LockScreenChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockScreenChannelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockScreenChannelHash();

  @$internal
  @override
  $ProviderElement<LockScreenChannel> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LockScreenChannel create(Ref ref) {
    return lockScreenChannel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LockScreenChannel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LockScreenChannel>(value),
    );
  }
}

String _$lockScreenChannelHash() => r'9175aa2fcb87a28a66f9a646bf7eee4b9c91ff79';

@ProviderFor(androidBackgroundSync)
final androidBackgroundSyncProvider = AndroidBackgroundSyncProvider._();

final class AndroidBackgroundSyncProvider
    extends
        $FunctionalProvider<
          AndroidBackgroundSync,
          AndroidBackgroundSync,
          AndroidBackgroundSync
        >
    with $Provider<AndroidBackgroundSync> {
  AndroidBackgroundSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'androidBackgroundSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$androidBackgroundSyncHash();

  @$internal
  @override
  $ProviderElement<AndroidBackgroundSync> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AndroidBackgroundSync create(Ref ref) {
    return androidBackgroundSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AndroidBackgroundSync value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AndroidBackgroundSync>(value),
    );
  }
}

String _$androidBackgroundSyncHash() =>
    r'65f2817e15280159347bc757cfe357da671e1114';

/// Whether the lock-screen/notification-shade feature has an implementation
/// on this platform — Android only today (see the architecture plan: iOS
/// needs a native Live Activity Widget Extension, a separate follow-up).
/// `settings_tab.dart` reads this to decide whether to show the toggle at
/// all; a seam rather than a raw `Platform.isAndroid` check inline so a
/// widget test can override it.

@ProviderFor(lockScreenSupported)
final lockScreenSupportedProvider = LockScreenSupportedProvider._();

/// Whether the lock-screen/notification-shade feature has an implementation
/// on this platform — Android only today (see the architecture plan: iOS
/// needs a native Live Activity Widget Extension, a separate follow-up).
/// `settings_tab.dart` reads this to decide whether to show the toggle at
/// all; a seam rather than a raw `Platform.isAndroid` check inline so a
/// widget test can override it.

final class LockScreenSupportedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the lock-screen/notification-shade feature has an implementation
  /// on this platform — Android only today (see the architecture plan: iOS
  /// needs a native Live Activity Widget Extension, a separate follow-up).
  /// `settings_tab.dart` reads this to decide whether to show the toggle at
  /// all; a seam rather than a raw `Platform.isAndroid` check inline so a
  /// widget test can override it.
  LockScreenSupportedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockScreenSupportedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockScreenSupportedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return lockScreenSupported(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$lockScreenSupportedHash() =>
    r'cf8f318ec19d515e52b24c697e7a5fa36a166c0b';

/// Durable store for [LockScreenState.enabled] — see
/// `LockScreenPreferenceRows` (`data/drift/database.dart`) for why the
/// in-memory flag alone isn't enough. Overridden with an in-memory
/// `AppDatabase` in tests via
/// `appDatabaseProvider` (`testing` skill), same as every other
/// drift-backed repository provider in this app.

@ProviderFor(lockScreenPreferenceRepository)
final lockScreenPreferenceRepositoryProvider =
    LockScreenPreferenceRepositoryProvider._();

/// Durable store for [LockScreenState.enabled] — see
/// `LockScreenPreferenceRows` (`data/drift/database.dart`) for why the
/// in-memory flag alone isn't enough. Overridden with an in-memory
/// `AppDatabase` in tests via
/// `appDatabaseProvider` (`testing` skill), same as every other
/// drift-backed repository provider in this app.

final class LockScreenPreferenceRepositoryProvider
    extends
        $FunctionalProvider<
          LockScreenPreferenceRepository,
          LockScreenPreferenceRepository,
          LockScreenPreferenceRepository
        >
    with $Provider<LockScreenPreferenceRepository> {
  /// Durable store for [LockScreenState.enabled] — see
  /// `LockScreenPreferenceRows` (`data/drift/database.dart`) for why the
  /// in-memory flag alone isn't enough. Overridden with an in-memory
  /// `AppDatabase` in tests via
  /// `appDatabaseProvider` (`testing` skill), same as every other
  /// drift-backed repository provider in this app.
  LockScreenPreferenceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockScreenPreferenceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockScreenPreferenceRepositoryHash();

  @$internal
  @override
  $ProviderElement<LockScreenPreferenceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LockScreenPreferenceRepository create(Ref ref) {
    return lockScreenPreferenceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LockScreenPreferenceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LockScreenPreferenceRepository>(
        value,
      ),
    );
  }
}

String _$lockScreenPreferenceRepositoryHash() =>
    r'21e9af391e0919aeabb30faf99da3e2071745e31';

/// Drives the persistent lock-screen / notification-shade display (§7).
///
/// Off by default — turning it on requests two permissions
/// (`POST_NOTIFICATIONS` and Health Connect's background-read permission)
/// through [enable], mirroring the explanation-then-request shape
/// `steps/presentation/permission_gate.dart` already uses for the health
/// permission (§7: never request without explaining first).
///
/// While enabled, this listens to [selectedJourneyProvider] and keeps the
/// display in sync with it — on quest start/switch, on every progress
/// update (foreground sync drives this the same way it always has; the
/// `workmanager` background task drives it independently, straight through
/// [lockScreenChannelProvider], without going through this controller at
/// all), and on quest completion (§6.1: the scene goes static, so this
/// stops showing "in progress" too).
///
/// `keepAlive: true` (unlike `StepsSync`, which is autoDispose): this
/// controller must go on reconciling itself against the platform for the
/// whole app session, not just while the Настройки tab happens to be
/// mounted — see [build]'s restore step.

@ProviderFor(LockScreenController)
final lockScreenControllerProvider = LockScreenControllerProvider._();

/// Drives the persistent lock-screen / notification-shade display (§7).
///
/// Off by default — turning it on requests two permissions
/// (`POST_NOTIFICATIONS` and Health Connect's background-read permission)
/// through [enable], mirroring the explanation-then-request shape
/// `steps/presentation/permission_gate.dart` already uses for the health
/// permission (§7: never request without explaining first).
///
/// While enabled, this listens to [selectedJourneyProvider] and keeps the
/// display in sync with it — on quest start/switch, on every progress
/// update (foreground sync drives this the same way it always has; the
/// `workmanager` background task drives it independently, straight through
/// [lockScreenChannelProvider], without going through this controller at
/// all), and on quest completion (§6.1: the scene goes static, so this
/// stops showing "in progress" too).
///
/// `keepAlive: true` (unlike `StepsSync`, which is autoDispose): this
/// controller must go on reconciling itself against the platform for the
/// whole app session, not just while the Настройки tab happens to be
/// mounted — see [build]'s restore step.
final class LockScreenControllerProvider
    extends $NotifierProvider<LockScreenController, LockScreenState> {
  /// Drives the persistent lock-screen / notification-shade display (§7).
  ///
  /// Off by default — turning it on requests two permissions
  /// (`POST_NOTIFICATIONS` and Health Connect's background-read permission)
  /// through [enable], mirroring the explanation-then-request shape
  /// `steps/presentation/permission_gate.dart` already uses for the health
  /// permission (§7: never request without explaining first).
  ///
  /// While enabled, this listens to [selectedJourneyProvider] and keeps the
  /// display in sync with it — on quest start/switch, on every progress
  /// update (foreground sync drives this the same way it always has; the
  /// `workmanager` background task drives it independently, straight through
  /// [lockScreenChannelProvider], without going through this controller at
  /// all), and on quest completion (§6.1: the scene goes static, so this
  /// stops showing "in progress" too).
  ///
  /// `keepAlive: true` (unlike `StepsSync`, which is autoDispose): this
  /// controller must go on reconciling itself against the platform for the
  /// whole app session, not just while the Настройки tab happens to be
  /// mounted — see [build]'s restore step.
  LockScreenControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockScreenControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockScreenControllerHash();

  @$internal
  @override
  LockScreenController create() => LockScreenController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LockScreenState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LockScreenState>(value),
    );
  }
}

String _$lockScreenControllerHash() =>
    r'9ab07400aa550f07214501bcc8c8bf0ce6eadeed';

/// Drives the persistent lock-screen / notification-shade display (§7).
///
/// Off by default — turning it on requests two permissions
/// (`POST_NOTIFICATIONS` and Health Connect's background-read permission)
/// through [enable], mirroring the explanation-then-request shape
/// `steps/presentation/permission_gate.dart` already uses for the health
/// permission (§7: never request without explaining first).
///
/// While enabled, this listens to [selectedJourneyProvider] and keeps the
/// display in sync with it — on quest start/switch, on every progress
/// update (foreground sync drives this the same way it always has; the
/// `workmanager` background task drives it independently, straight through
/// [lockScreenChannelProvider], without going through this controller at
/// all), and on quest completion (§6.1: the scene goes static, so this
/// stops showing "in progress" too).
///
/// `keepAlive: true` (unlike `StepsSync`, which is autoDispose): this
/// controller must go on reconciling itself against the platform for the
/// whole app session, not just while the Настройки tab happens to be
/// mounted — see [build]'s restore step.

abstract class _$LockScreenController extends $Notifier<LockScreenState> {
  LockScreenState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LockScreenState, LockScreenState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LockScreenState, LockScreenState>,
              LockScreenState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
