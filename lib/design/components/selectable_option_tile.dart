import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

/// One row in a single-choice list (language, theme, and any future picker
/// alike), styled as a small badge/medal rather than a bare Material radio
/// dot (styling fix: "выбранные элементы... в виде стилизованных 'жетонов'
/// или 'наград', а не просто кружков" — reads as the game's own UI, not a
/// generic settings form).
///
/// [leading] is a small preview for the option itself — an icon standing in
/// for a theme's look, a flag for a language — shown *before* the user picks
/// it, not just implied by its label (styling fix: "пользователь должен
/// видеть, как выглядит тема, до того как выберет её").
///
/// Needs a `Material` ancestor for its ink splash — every call site so far
/// already has one (`SettingsTab`'s `_SectionCard` wraps its content in
/// `Material` for the same reason `ListTile`/`RadioListTile` used to need).
class SelectableOptionTile extends StatelessWidget {
  const SelectableOptionTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceActive : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? AppColors.gold : Colors.transparent,
            width: AppStroke.cardBorder,
          ),
        ),
        // Leading preview and title left-aligned, the selection badge
        // pinned to the trailing edge (styling fix: "текст... по левому...
        // переключатели и радио-кнопки... строго по правому краю").
        child: Row(
          children: [
            SizedBox(width: 28, child: Center(child: leading)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTypography.bodySecondary),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _SelectionBadge(selected: selected),
          ],
        ),
      ),
    );
  }
}

/// The "жетон" itself: a filled gold medallion with a check mark once
/// selected, a plain hollow ring otherwise — replaces the default Material
/// [Radio] dot everywhere [SelectableOptionTile] is used.
class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.gold : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.gold : AppColors.cardBorder,
          width: AppStroke.icon,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: AppColors.background)
          : null,
    );
  }
}
