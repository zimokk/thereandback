import 'package:flutter/material.dart' show Color;

import '../../../design/colors.dart';
import '../domain/friend_progress.dart';

/// The stable display color for [row]'s marker — same palette and
/// modulo-safety `challengers_tab.dart`'s `_FriendRow` already uses for the
/// Challengers table's own pin dot, so a friend reads as the same color on
/// every screen they're drawn on (§6.4: "цвет пина стабилен... совпадает
/// на карте и в таблице"), now extended to the Путь tab's figure and the
/// Карта tab's helmet as well.
Color friendMarkerColor(FriendProgressRow row) =>
    AppColors.friendPinPalette[row.pinColorIndex %
        AppColors.friendPinPalette.length];
