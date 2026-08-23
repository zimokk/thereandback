import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../journey/domain/quest_progress.dart';
import '../../journey/presentation/journey_providers.dart';

/// Quest Stats (§6.2) — the "Progress" screen. No drawn map yet: that needs
/// `map.webp`/`map.json` (Phase 11), which don't exist. This shows the
/// header stats §6.2 describes and a placeholder panel where the map lands.
class QuestStatsTab extends ConsumerWidget {
  const QuestStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedJourneyProvider);
    final journey = ref.watch(selectedJourneyDetailsProvider);
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
    required this.l10n,
  });

  final DateTime startedAt;
  final int progressMeters;
  final int totalMeters;
  final String pointB;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final total = formatDistance(totalMeters);
    final eta = estimateArrival(
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
        const SizedBox(height: AppSpacing.lg),
        _StatRow(
          label: l10n.questStatsStartedLabel,
          value: formatDate(startedAt, localeName: locale),
        ),
        const SizedBox(height: AppSpacing.sm),
        _StatRow(label: l10n.questStatsEtaLabel, value: etaLabel),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.questStatsMapComingSoonTitle,
                style: AppTypography.label,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.questStatsMapComingSoonBody,
                style: AppTypography.bodySecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySecondary),
        Text(value, style: AppTypography.body),
      ],
    );
  }
}
