// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_music_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single [BackgroundMusicPlayer] instance for the app session — kept
/// alive so the underlying `audioplayers` player (and, once loaded, the
/// track's decoded buffer) is created once, not on every toggle. Mirrors
/// `lock_screen_controller.dart`'s `androidLockScreenChannelProvider`.

@ProviderFor(backgroundMusicPlayer)
final backgroundMusicPlayerProvider = BackgroundMusicPlayerProvider._();

/// The single [BackgroundMusicPlayer] instance for the app session — kept
/// alive so the underlying `audioplayers` player (and, once loaded, the
/// track's decoded buffer) is created once, not on every toggle. Mirrors
/// `lock_screen_controller.dart`'s `androidLockScreenChannelProvider`.

final class BackgroundMusicPlayerProvider
    extends
        $FunctionalProvider<
          BackgroundMusicPlayer,
          BackgroundMusicPlayer,
          BackgroundMusicPlayer
        >
    with $Provider<BackgroundMusicPlayer> {
  /// The single [BackgroundMusicPlayer] instance for the app session — kept
  /// alive so the underlying `audioplayers` player (and, once loaded, the
  /// track's decoded buffer) is created once, not on every toggle. Mirrors
  /// `lock_screen_controller.dart`'s `androidLockScreenChannelProvider`.
  BackgroundMusicPlayerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundMusicPlayerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundMusicPlayerHash();

  @$internal
  @override
  $ProviderElement<BackgroundMusicPlayer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackgroundMusicPlayer create(Ref ref) {
    return backgroundMusicPlayer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundMusicPlayer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundMusicPlayer>(value),
    );
  }
}

String _$backgroundMusicPlayerHash() =>
    r'882399b04d01320a46f6e0ef39dc50a7c392a6bd';

/// Whether the app's one background track (§6.5) is on. **Off by
/// default** — this task's own requirement — turning it on in Настройки
/// starts the track immediately (Настройки is only reachable while the app
/// is in the foreground, so there's no lifecycle gate to check first).
///
/// While on, this also follows [appLifecycleProvider]: the track pauses the
/// instant the app leaves the foreground and resumes the instant it
/// returns — "играть будет... когда пользователь находится в приложении"
/// is a standing lifecycle rule, not just an on/off switch checked once at
/// toggle time. `keepAlive: true` so that rule keeps applying for the whole
/// app session, not only while the Настройки tab happens to be mounted —
/// see `app_shell.dart`'s eager `ref.watch`, same reasoning as
/// `LockScreenController`.
///
/// Durable since §14 ("сохраняй настройки пользователя..."): [build] fires
/// the same "async check from a sync build()" idiom
/// `journey_providers.dart`'s `SelectedJourney.build()` uses — if the track
/// was on when the app was last closed, [_restore] resumes it through
/// [setEnabled] itself, so a restart gets the same guarantee a manual
/// toggle already has (state only reads "on" once playback actually
/// started).

@ProviderFor(BackgroundMusicController)
final backgroundMusicControllerProvider = BackgroundMusicControllerProvider._();

/// Whether the app's one background track (§6.5) is on. **Off by
/// default** — this task's own requirement — turning it on in Настройки
/// starts the track immediately (Настройки is only reachable while the app
/// is in the foreground, so there's no lifecycle gate to check first).
///
/// While on, this also follows [appLifecycleProvider]: the track pauses the
/// instant the app leaves the foreground and resumes the instant it
/// returns — "играть будет... когда пользователь находится в приложении"
/// is a standing lifecycle rule, not just an on/off switch checked once at
/// toggle time. `keepAlive: true` so that rule keeps applying for the whole
/// app session, not only while the Настройки tab happens to be mounted —
/// see `app_shell.dart`'s eager `ref.watch`, same reasoning as
/// `LockScreenController`.
///
/// Durable since §14 ("сохраняй настройки пользователя..."): [build] fires
/// the same "async check from a sync build()" idiom
/// `journey_providers.dart`'s `SelectedJourney.build()` uses — if the track
/// was on when the app was last closed, [_restore] resumes it through
/// [setEnabled] itself, so a restart gets the same guarantee a manual
/// toggle already has (state only reads "on" once playback actually
/// started).
final class BackgroundMusicControllerProvider
    extends $NotifierProvider<BackgroundMusicController, bool> {
  /// Whether the app's one background track (§6.5) is on. **Off by
  /// default** — this task's own requirement — turning it on in Настройки
  /// starts the track immediately (Настройки is only reachable while the app
  /// is in the foreground, so there's no lifecycle gate to check first).
  ///
  /// While on, this also follows [appLifecycleProvider]: the track pauses the
  /// instant the app leaves the foreground and resumes the instant it
  /// returns — "играть будет... когда пользователь находится в приложении"
  /// is a standing lifecycle rule, not just an on/off switch checked once at
  /// toggle time. `keepAlive: true` so that rule keeps applying for the whole
  /// app session, not only while the Настройки tab happens to be mounted —
  /// see `app_shell.dart`'s eager `ref.watch`, same reasoning as
  /// `LockScreenController`.
  ///
  /// Durable since §14 ("сохраняй настройки пользователя..."): [build]
  /// fires the same "async check from a sync build()" idiom
  /// `journey_providers.dart`'s `SelectedJourney.build()` uses — if the
  /// track was on when the app was last closed, [_restore] resumes it
  /// through [setEnabled] itself, so a restart gets the same guarantee a
  /// manual toggle already has (state only reads "on" once playback
  /// actually started).
  BackgroundMusicControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundMusicControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundMusicControllerHash();

  @$internal
  @override
  BackgroundMusicController create() => BackgroundMusicController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$backgroundMusicControllerHash() =>
    r'18663941843a154806dccff79a649a701dced160';

/// Whether the app's one background track (§6.5) is on. **Off by
/// default** — this task's own requirement — turning it on in Настройки
/// starts the track immediately (Настройки is only reachable while the app
/// is in the foreground, so there's no lifecycle gate to check first).
///
/// While on, this also follows [appLifecycleProvider]: the track pauses the
/// instant the app leaves the foreground and resumes the instant it
/// returns — "играть будет... когда пользователь находится в приложении"
/// is a standing lifecycle rule, not just an on/off switch checked once at
/// toggle time. `keepAlive: true` so that rule keeps applying for the whole
/// app session, not only while the Настройки tab happens to be mounted —
/// see `app_shell.dart`'s eager `ref.watch`, same reasoning as
/// `LockScreenController`.
///
/// Durable since §14 ("сохраняй настройки пользователя..."): [build] fires
/// the same "async check from a sync build()" idiom
/// `journey_providers.dart`'s `SelectedJourney.build()` uses — if the track
/// was on when the app was last closed, [_restore] resumes it through
/// [setEnabled] itself, so a restart gets the same guarantee a manual
/// toggle already has (state only reads "on" once playback actually
/// started).

abstract class _$BackgroundMusicController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
