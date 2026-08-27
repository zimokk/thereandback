import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/lock_screen_snapshot.dart';
import 'lock_screen_channel.dart';

/// Android implementation of [LockScreenChannel]: an ongoing (non-swipeable
/// while the app has something to show, `autoCancel: false`) notification,
/// visible in the shade and — with [NotificationVisibility.public] — on the
/// lock screen.
///
/// Deliberately *not* a foreground service: `flutter_local_notifications`
/// can update this notification in place with a plain `show()` call any
/// time a new [LockScreenSnapshot] is available (foreground sync, or the
/// `workmanager` background task in `android_background_sync.dart`) — an
/// ongoing notification doesn't need a live foreground service keeping it
/// alive, and running one continuously would add its own always-on status
/// bar indicator, which nobody asked for here.
///
/// Android's stock notification chrome doesn't expose a font-weight knob,
/// so "thin app name" (the design ask) is approximated by convention
/// instead of styling: the app name is the small system-rendered title,
/// [BigTextStyleInformation.bigText] carries the prominent progress line,
/// and `summaryText` carries the position line at the bottom — the same
/// three-line shape the design calls for, built from what the platform's
/// notification template actually offers (there is no custom RemoteViews
/// layout support in this package version).
class AndroidLockScreenChannel implements LockScreenChannel {
  AndroidLockScreenChannel([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Arbitrary but stable — the same notification is shown/updated/
  /// cancelled by id across the whole lifetime of the feature.
  static const _notificationId = 7301;
  static const _channelId = 'lock_screen_progress';

  /// `res/drawable-{density}/ic_notification_status.png` — an alpha-mask
  /// silhouette per Android's notification-icon guidelines (the full-color
  /// launcher icon can't be used there; the OS re-tints whatever's opaque
  /// to solid white/accent regardless of source color, so only the alpha
  /// channel matters). Source art: `assets/branding/notification_icon_source.jpg`.
  /// The launcher icon is reused as [DrawableResourceAndroidBitmap] for the
  /// *large* icon instead, which is what actually renders on the right
  /// ("иконку приложения справа").
  static const _statusBarIcon = 'ic_notification_status';

  /// `res/drawable/ic_launcher_notification.xml` — a `drawable`-type alias
  /// for `@mipmap/ic_launcher`. `flutter_local_notifications` resolves
  /// bitmap/icon names under the `drawable` resource type only, so the
  /// mipmap launcher icon needs this alias to be reachable by name here.
  static const _launcherIconResource = 'ic_launcher_notification';

  bool _initialized = false;

  /// Requests Android 13+'s `POST_NOTIFICATIONS` permission — a no-op that
  /// resolves `true` on API levels where none is needed. Not part of
  /// [LockScreenChannel]: permission flows are platform-specific setup, not
  /// something the shared start/update/end display contract needs to carry
  /// for an eventual iOS implementation.
  Future<bool> requestNotificationPermission() async {
    await _ensureInitialized();
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return granted ?? true;
  }

  /// Whether `POST_NOTIFICATIONS` is currently held, *without* prompting.
  /// Separate from [requestNotificationPermission] because the user can
  /// grant or revoke it outside the app (Android settings) while it is
  /// backgrounded — the toggle has to be able to re-read the truth rather
  /// than trust whatever the last request returned. Resolves `true` on API
  /// levels that have no such permission, matching the request path.
  Future<bool> hasNotificationPermission() async {
    await _ensureInitialized();
    final enabled = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
    return enabled ?? true;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings(_statusBarIcon);
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
    _initialized = true;
  }

  @override
  Future<void> start(LockScreenSnapshot snapshot) => update(snapshot);

  @override
  Future<void> update(LockScreenSnapshot snapshot) async {
    await _ensureInitialized();
    final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);

    // "There and Back" — the fixed brand name (CLAUDE.md §14), not
    // translated, same literal used for the MaterialApp title in
    // `app/app.dart`.
    const appName = 'There and Back';
    final progressLine = _progressLine(snapshot, l10n);

    final details = AndroidNotificationDetails(
      _channelId,
      l10n.lockScreenChannelName,
      channelDescription: l10n.lockScreenChannelDescription,
      icon: _statusBarIcon,
      largeIcon: const DrawableResourceAndroidBitmap(_launcherIconResource),
      // Low priority/importance: this is a standing status display, not an
      // alert — it must never make a sound or pop a heads-up banner.
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        progressLine,
        contentTitle: appName,
        summaryText: snapshot.positionLabel,
      ),
    );

    await _plugin.show(
      id: _notificationId,
      title: appName,
      body: progressLine,
      notificationDetails: NotificationDetails(android: details),
    );
  }

  @override
  Future<void> end() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _notificationId);
  }

  String _progressLine(LockScreenSnapshot snapshot, AppLocalizations l10n) {
    final distance = formatDistance(snapshot.progressMeters);
    final unitLabel = switch (distance.unit) {
      DistanceUnit.meters => l10n.unitMeters(int.parse(distance.value)),
      DistanceUnit.kilometers => l10n.unitKilometers(num.parse(distance.value)),
    };
    return l10n.lockScreenBody(
      l10n.journeyDayCounter(snapshot.questDay),
      '${distance.value} $unitLabel',
    );
  }
}
