import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/journey.dart';
import 'journey_providers.dart';

/// The quest catalog (§6.1, §8): shown on the Путь tab when the user has
/// not started a quest yet. One card today — the Odyssey (§14).
class QuestPickerView extends ConsumerWidget {
  const QuestPickerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(journeyCatalogEntriesProvider);
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(l10n.journeyCatalogTitle, style: AppTypography.heading),
        const SizedBox(height: AppSpacing.md),
        for (final journey in catalog)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _JourneyCard(
              journey: journey,
              onStart: () {
                ref
                    .read(selectedJourneyProvider.notifier)
                    .start(journey.id, now: DateTime.now());
                // Starting a (possibly different) quest is always the way
                // out of browsing mode — same as picking one for the first
                // time, this always lands back on the path scene.
                ref.read(browsingCatalogProvider.notifier).exit();
              },
            ),
          ),
      ],
    );
  }
}

class _JourneyCard extends ConsumerWidget {
  const _JourneyCard({required this.journey, required this.onStart});

  final Journey journey;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final distance = formatDistance(journey.totalMeters);
    // `.value ?? 0`, not `.when(loading: ...)`: while the sum query is
    // still in flight (or the journey was never started, in which case the
    // sum simply resolves to 0) a plain 0% is already the right thing to
    // show, not a spinner over the badge (same idiom
    // `achievements_tab.dart`'s unlocks read uses).
    final fraction =
        ref.watch(journeyProgressFractionProvider(journey.id)).value ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Top-left percent-complete badge (this task's requirement —
              // "показывай процент пройденного пути для каждого маршрута").
              _ProgressBadge(fraction: fraction),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(journey.name, style: AppTypography.heading)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Point A/B are journey data, not translatable UI copy — the
          // arrow is a typographic separator, not sentence text (§11).
          Text(
            '${journey.pointA} → ${journey.pointB}',
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            localizedDistanceInline(l10n, distance),
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
              ),
              child: Text(l10n.journeyCatalogStartButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small "N%" pill (this task's requirement) — gold once there's real
/// progress to show, muted at 0% so an unstarted route doesn't read as
/// already begun.
class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final percent = (fraction * 100).round();
    final color = percent > 0 ? AppColors.gold : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceActive,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color, width: AppStroke.cardBorder),
      ),
      child: Text(
        '$percent%',
        style: AppTypography.bodySecondary.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
