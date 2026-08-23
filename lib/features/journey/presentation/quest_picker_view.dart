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
              onStart: () => ref
                  .read(selectedJourneyProvider.notifier)
                  .start(journey.id, now: DateTime.now()),
            ),
          ),
      ],
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.journey, required this.onStart});

  final Journey journey;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final distance = formatDistance(journey.totalMeters);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(journey.name, style: AppTypography.heading),
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
