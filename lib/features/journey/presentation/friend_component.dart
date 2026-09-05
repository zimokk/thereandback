import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart';

import '../../../design/colors.dart';
import '../../friends/domain/friend_progress.dart';
import '../../friends/presentation/friend_pin_color.dart';
import 'journey_scene_controller.dart';
import 'terrain_layer.dart';
import 'traveler_component.dart';

/// Font size of a friend's nickname label — matches the CustomPaint
/// placeholder's `_friendLabelFontSize` and `quest_map_view.dart`'s own
/// friend-label size (§6.2 visual parity).
const double friendLabelFontSize = 10;

/// Gap, in logical pixels, between a friend's figure and the bottom edge of
/// their nickname label above it.
const double friendLabelGap = 2;

/// One accepted friend's figure on the scene (§6.5, off by default) — the
/// same [TravelerComponent] glyph the player's own solid marker uses, in
/// the friend's stable pin color (`friendMarkerColor`), with an
/// **unconditionally shown** nickname above it (unlike the Карта tab's own
/// legend toggle, nothing hides this label here once the preference is on).
///
/// A thin wrapper composing [TravelerComponent] + a nickname [TextComponent]
/// rather than a from-scratch component: both children stay positioned in
/// this wrapper's own local space, which is world space as long as the
/// wrapper's own `position` never moves off `(0, 0)` — it doesn't, so a
/// child's `position` *is* its world position.
class FriendMarkerComponent extends PositionComponent {
  FriendMarkerComponent({required this.controller, required this.uid});

  final JourneySceneController controller;

  /// Which friend this component tracks — looked up in
  /// [JourneySceneController.friendRows] on every read (rather than
  /// snapshotted once) so a friend's progress update is reflected without
  /// [JourneyScene] having to recreate this component.
  final String uid;

  late final TravelerComponent _marker;
  late final TextComponent _label;

  /// The figure's own world position — exposed only for
  /// `friend_component_test.dart`; the wrapper's own `position` always
  /// stays `(0, 0)` (see the class doc comment), so tests need the child's
  /// position, not this component's own.
  @visibleForTesting
  Vector2 get markerPositionForTest => _marker.position;

  @visibleForTesting
  String get labelTextForTest => _label.text;

  @visibleForTesting
  Vector2 get labelPositionForTest => _label.position;

  FriendProgressRow? get _row {
    for (final row in controller.friendRows) {
      if (row.uid == uid) return row;
    }
    return null;
  }

  Color get _color {
    final row = _row;
    return row == null ? AppColors.textSecondary : friendMarkerColor(row);
  }

  @override
  Future<void> onLoad() async {
    _marker = TravelerComponent(
      controller: controller,
      metersProvider: () => (_row?.progressMeters ?? 0).toDouble(),
      color: _color,
    );
    await add(_marker);

    _label = TextComponent(
      text: _row?.nickname ?? '',
      anchor: Anchor.bottomCenter,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: friendLabelFontSize,
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    await add(_label);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final row = _row;
    if (row != null && _label.text != row.nickname) {
      _label.text = row.nickname;
    }
    // Computed independently from `_marker.position`, not read off it —
    // Flame updates a component before its children, so reading
    // `_marker.position` here would see last tick's value, one frame stale.
    // Same formula `TravelerComponent.update()` uses for this row's own
    // meters, so the two can never visibly drift apart either way.
    final meters = (row?.progressMeters ?? 0).toDouble();
    final pixelsPerMeter = controller.pixelsPerMeter;
    final worldX = worldXFor(meters, pixelsPerMeter);
    // `.setValues` on the existing Vector2 — no fresh allocation per tick.
    _label.position.setValues(
      worldX,
      terrainHeightAt(worldX, controller.terrainProfile, pixelsPerMeter) -
          travelerIconSize / 2 -
          friendLabelGap,
    );
  }
}
