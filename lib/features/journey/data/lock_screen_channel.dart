import '../domain/lock_screen_snapshot.dart';

/// Platform seam for the persistent progress display (§7 "постоянное
/// отображение прогресса на заблокированном экране") — the lock screen on
/// iOS, the lock screen + notification shade on Android.
///
/// Exactly one implementation per platform. Android's is
/// `android_lock_screen_channel.dart` (an ongoing notification via
/// `flutter_local_notifications`). iOS is deliberately not built yet — a
/// Live Activity needs a native Swift Widget Extension Xcode target, which
/// is its own follow-up (see the architecture plan this feature shipped
/// with). Nothing above this interface — `lock_screen_controller.dart`, the
/// background sync task, the domain snapshot — needs to change when that
/// follow-up adds an `ios_lock_screen_channel.dart` behind it.
abstract class LockScreenChannel {
  /// Starts showing [snapshot]. Called when the feature is turned on, or
  /// when a new quest starts while it's already on.
  Future<void> start(LockScreenSnapshot snapshot);

  /// Refreshes the currently shown display with a new [snapshot]. A no-op
  /// on a platform/implementation where nothing was started yet.
  Future<void> update(LockScreenSnapshot snapshot);

  /// Stops showing progress. Called on quest completion (§6.1: the scene
  /// goes static, no stale "in progress" display) or when the feature is
  /// turned off.
  Future<void> end();
}
