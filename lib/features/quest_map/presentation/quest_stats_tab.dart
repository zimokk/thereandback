import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../journey/domain/quest_time_service.dart';
import '../../journey/presentation/journey_providers.dart';
import 'quest_map_view.dart';

/// Quest Stats (§6.2) — the "Progress" screen: the header stats, then the
/// drawn map of the route with the traveler's own position on its line
/// ([QuestMapView]).
class QuestStatsTab extends ConsumerWidget {
  const QuestStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedJourneyProvider);
    final journey = ref.watch(selectedJourneyDetailsProvider);
    // `.value ?? []`, not `.when(loading: ...)`: while the history is still
    // loading (or a quest just started, before any interval exists), an
    // empty list is already the right input — `QuestTimeService` treats
    // "no matching intervals yet" the same as "none exist", not as an error
    // state to show a spinner for. (This riverpod version's `AsyncValue`
    // has no `valueOrNull` — `.value` itself is already the nullable one.)
    final recentIntervals =
        ref.watch(recentMeteredIntervalsProvider).value ??
        const <MeteredInterval>[];
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: selected == null || journey == null
            ? _EmptyState(l10n: l10n)
            : _StatsBody(
                startedAt: selected.startedAt,
                progressMeters: selected.progressMeters,
                totalMeters: journey.totalMeters,
                pointB: journey.pointB,
                recentIntervals: recentIntervals,
                l10n: l10n,
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.questStatsEmptyTitle,
              style: AppTypography.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.questStatsEmptyBody,
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => context.go('/journey'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
              ),
              child: Text(l10n.questStatsEmptyCta),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({
    required this.startedAt,
    required this.progressMeters,
    required this.totalMeters,
    required this.pointB,
    required this.recentIntervals,
    required this.l10n,
  });

  final DateTime startedAt;
  final int progressMeters;
  final int totalMeters;
  final String pointB;
  final List<MeteredInterval> recentIntervals;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final total = formatDistance(totalMeters);
    final eta = questTimeService.estimateArrival(
      recentIntervals: recentIntervals,
      progressMeters: progressMeters,
      totalMeters: totalMeters,
      startedAt: startedAt,
      now: now,
    );
    final etaLabel = eta == null
        ? '—'
        : formatEtaDate(eta, localeName: locale) ?? '—';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // "Quest Started"/"Estimated Arrival" sit to the right of the
        // remaining-distance hero, not stacked below it (this task's
        // requirement — the whole tab must fit on screen without scrolling
        // past the header before reaching the map).
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(total.value, style: AppTypography.distanceHero),
                  Text(
                    localizedUnitLabel(l10n, total),
                    style: AppTypography.distanceUnit,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.questStatsToLabel(pointB),
                    style: AppTypography.bodySecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatColumn(
                    label: l10n.questStatsStartedLabel,
                    value: formatDate(startedAt, localeName: locale),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatColumn(label: l10n.questStatsEtaLabel, value: etaLabel),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.questMapSectionTitle, style: AppTypography.label),
        const SizedBox(height: AppSpacing.sm),
        QuestMapView(progressMeters: progressMeters, startedAt: startedAt),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySecondary),
        Text(value, style: AppTypography.body),
      ],
    );
  }
}
