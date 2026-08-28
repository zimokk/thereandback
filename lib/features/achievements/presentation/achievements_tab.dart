import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../journey/presentation/journey_providers.dart';
import '../data/achievement_catalog.dart';
import '../domain/achievement.dart';
import 'achievement_titles.dart';

/// Трофеи (§6.3): a grid driven entirely by `evaluateAchievements` — adding
/// a trophy means editing `achievement_catalog.dart`, never this widget.
class AchievementsTab extends ConsumerWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedJourneyProvider);
    final l10n = AppLocalizations.of(context)!;
    final states = evaluateAchievements(
      progressMeters: selected?.progressMeters ?? 0,
      catalog: achievementCatalog,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.95,
          ),
          itemCount: states.length,
          itemBuilder: (context, index) =>
              _AchievementTile(state: states[index], l10n: l10n),
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.state, required this.l10n});

  final AchievementState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final unlocked = state.unlocked;
    final iconColor = unlocked ? AppColors.gold : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: unlocked
            ? Border.all(color: AppColors.gold, width: AppStroke.icon)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 40, color: iconColor),
          const SizedBox(height: AppSpacing.sm),
          Text(
            achievementTitle(l10n, state.def),
            style: AppTypography.body.copyWith(
              color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            unlocked
                ? l10n.achievementUnlockedLabel
                : l10n.achievementRemainingLabel(
                    localizedDistanceInline(
                      l10n,
                      formatDistance(state.remainingMeters),
                    ),
                  ),
            style: AppTypography.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
