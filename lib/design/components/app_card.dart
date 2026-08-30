import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';

/// The one card chrome every feature widget should reach for instead of
/// hand-rolling `Container(decoration: BoxDecoration(color: AppColors
/// .surface, ...))` (§9 — "разные уровни поверхности: фон → карточка →
/// активный элемент", plus a thin border and a shorter card than the old
/// plain grey rectangles).
///
/// [highlighted] steps up one rung to [AppColors.surfaceActive] with a full
/// [AppColors.gold] border — the "активный элемент" rung, for the one row/
/// tile on a screen that is currently selected, pinned, or otherwise the
/// odd one out (e.g. the signed-in user's own row in the Challengers table).
/// Everything else gets the plain [AppColors.surface] fill with a hairline
/// [AppColors.cardBorder].
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.highlighted = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    this.margin,
  });

  final Widget child;
  final bool highlighted;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: highlighted ? AppColors.surfaceActive : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: highlighted ? AppColors.gold : AppColors.cardBorder,
          width: AppStroke.cardBorder,
        ),
      ),
      child: child,
    );
  }
}
