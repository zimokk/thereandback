import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/journey.dart';
import '../domain/journey_asset_status.dart';
import 'journey_asset_providers.dart';
import 'journey_providers.dart';

/// The quest catalog (§6.1, §8): shown on the Путь tab when the user has
/// not started a quest yet. Two cards today — the Odyssey and "The Road to
/// the Skyfire" (§14).
class QuestPickerView extends ConsumerWidget {
  const QuestPickerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(journeyCatalogEntriesProvider);
    final l10n = AppLocalizations.of(context)!;
    // The currently active quest's id, if any — a card whose journey
    // matches this one is already underway, not merely selectable (bug fix:
    // the button used to say and act as "Start" even for this card, which
    // reset progress back to zero on tap; see `_JourneyCard`/
    // `_JourneyCardAction` below and `SelectedJourney.start()`'s own guard).
    final activeJourneyId = ref.watch(selectedJourneyProvider)?.journeyId;

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
              isActive: journey.id == activeJourneyId,
              onStart: () {
                // Starting a (possibly different) quest is always the way
                // out of browsing mode — same as picking one for the first
                // time, this always lands back on the path scene. Re-tapping
                // the already-active quest's card takes this same path
                // (`SelectedJourney.start()` no-ops on it, see its own doc
                // comment) so the tap still does the one thing it should:
                // return to the path scene, without resetting anything.
                ref
                    .read(selectedJourneyProvider.notifier)
                    .start(journey.id, now: DateTime.now());
                ref.read(browsingCatalogProvider.notifier).exit();
              },
            ),
          ),
        // The stub this task asked for (§8, §14): the download machinery
        // (`journey_asset_providers.dart`, `_JourneyCardAction` below) is
        // fully wired end to end, but `journeyAssetManifests` has no
        // entries yet — nothing in the real catalog exercises it today.
        // This card is purely informational, not a fake `Journey` a user
        // could tap into `selectedJourneyProvider.start()`: it never
        // touches the domain model this screen otherwise drives.
        const _ComingSoonCard(),
      ],
    );
  }
}

/// Non-interactive placeholder at the end of the catalog, announcing that
/// future quests will download on demand rather than grow this build
/// (§8, §14) — see [QuestPickerView]'s own comment on why this stays
/// separate from the real catalog loop above it.
class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.cardBorder,
          width: AppStroke.cardBorder,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_download_outlined,
            color: AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.journeyCatalogComingSoonTitle,
                  style: AppTypography.heading.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.journeyCatalogComingSoonSubtitle,
                  style: AppTypography.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends ConsumerWidget {
  const _JourneyCard({
    required this.journey,
    required this.isActive,
    required this.onStart,
  });

  final Journey journey;

  /// Whether this card's journey is the one the user already has underway
  /// (`selectedJourneyProvider`), as opposed to one they could start fresh —
  /// swaps the action button to "Continue" (§14 bug fix) instead of "Start".
  final bool isActive;
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
          _JourneyCardAction(
            status: ref.watch(journeyAssetStatusControllerProvider(journey.id)),
            isActive: isActive,
            onStart: onStart,
            onDownload: () => ref
                .read(journeyAssetStatusControllerProvider(journey.id).notifier)
                .download(),
          ),
        ],
      ),
    );
  }
}

/// The bottom-right action of a catalog card — switches on
/// [JourneyAssetStatus] (§8, §14) rather than always showing "Start quest":
/// today every quest resolves straight to [JourneyAssetReady] (nothing in
/// `journeyAssetManifests` yet, §14), so this reads as dead code until the
/// first downloadable quest lands in the catalog — that's the point, the
/// branch is ready and unit-testable ahead of that content existing.
class _JourneyCardAction extends StatelessWidget {
  const _JourneyCardAction({
    required this.status,
    required this.isActive,
    required this.onStart,
    required this.onDownload,
  });

  final JourneyAssetStatus status;
  final bool isActive;
  final VoidCallback onStart;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return switch (status) {
      JourneyAssetReady() => Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: onStart,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.background,
          ),
          child: Text(
            isActive
                ? l10n.journeyCatalogContinueButton
                : l10n.journeyCatalogStartButton,
          ),
        ),
      ),
      JourneyAssetNotDownloaded() => Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.cloud_download_outlined, size: 18),
          label: Text(l10n.journeyCatalogDownloadButton),
        ),
      ),
      JourneyAssetDownloading(:final progress) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.surfaceActive,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.journeyCatalogDownloadingLabel((progress * 100).round()),
            style: AppTypography.bodySecondary,
          ),
        ],
      ),
      JourneyAssetFailed() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              l10n.journeyCatalogDownloadFailedMessage,
              style: AppTypography.bodySecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton(
            onPressed: onDownload,
            child: Text(l10n.journeyCatalogRetryDownloadButton),
          ),
        ],
      ),
    };
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
