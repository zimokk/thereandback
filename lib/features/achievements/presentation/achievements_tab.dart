import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme_id.dart';
import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../journey/domain/progress_fraction.dart';
import '../../journey/presentation/journey_providers.dart';
import '../../profile/presentation/theme_provider.dart';
import '../data/achievement_catalog.dart';
import '../domain/achievement.dart';
import '../domain/achievement_unlocks.dart' show currentStreak, longestStreak;
import '../domain/daily_achievement.dart';
import 'achievement_illustrations.dart';
import 'achievement_titles.dart';
import 'achievements_providers.dart';

/// Трофеи (§6.3, extended by the daily-trophies task): two sections in
/// their own sub-tabs, sharing one grid look — "Поход" (`achievementCatalog`,
/// driven by `evaluateAchievements` against live progress, as before) and
/// "Каждый день" (`dailyAchievementCatalog`, driven entirely by persisted
/// `AchievementRepository.loadUnlocks` — a day's total isn't live progress
/// state anywhere else in the app). Adding a trophy to either section means
/// editing `achievement_catalog.dart`, never this widget.
class AchievementsTab extends ConsumerWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedJourneyProvider);
    final theme = ref.watch(effectiveThemeProvider);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    // `.value ?? {}`, not `.when(loading: ...)`: while unlocks are still
    // loading (or none have ever been recorded), an empty map is already
    // the right input — every tile just reads as "not yet earned", not an
    // error state to show a spinner for (same idiom
    // `quest_stats_tab.dart` uses for `recentMeteredIntervalsProvider`).
    final unlocks =
        ref.watch(achievementUnlocksProvider).value ??
        const <String, List<DateTime>>{};
    // Same `.value ?? 0` idiom as `unlocks` above — while today's total is
    // still loading, 0 is already the right input for every daily tile's
    // progress line, not a state worth a spinner over.
    final todayMeters = ref.watch(todayAllQuestsMetersProvider).value ?? 0;

    final journeyStates = evaluateAchievements(
      progressMeters: selected?.progressMeters ?? 0,
      catalog: achievementCatalog,
    );
    final dailyStates = buildDailyAchievementStates(
      catalog: dailyAchievementCatalog,
      unlocks: unlocks,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                labelColor: AppColors.gold,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.gold,
                tabs: [
                  Tab(text: l10n.achievementsJourneyTabLabel),
                  Tab(text: l10n.achievementsDailyTabLabel),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _JourneyGrid(
                      states: journeyStates,
                      unlocks: unlocks,
                      l10n: l10n,
                      localeName: locale,
                      theme: theme,
                    ),
                    _DailyGrid(
                      states: dailyStates,
                      todayMeters: todayMeters,
                      l10n: l10n,
                      localeName: locale,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyGrid extends StatelessWidget {
  const _JourneyGrid({
    required this.states,
    required this.unlocks,
    required this.l10n,
    required this.localeName,
    required this.theme,
  });

  final List<AchievementState> states;
  final Map<String, List<DateTime>> unlocks;
  final AppLocalizations l10n;
  final String localeName;
  final AppThemeId theme;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.95,
      ),
      itemCount: states.length,
      itemBuilder: (context, index) {
        final state = states[index];
        return _AchievementTile(
          state: state,
          l10n: l10n,
          theme: theme,
          onTap: () => _showAchievementDetailsSheet(
            context,
            l10n: l10n,
            title: achievementTitle(l10n, state.def),
            statusLine: state.unlocked
                ? l10n.achievementUnlockedLabel
                : l10n.achievementRemainingLabel(
                    localizedDistanceInline(
                      l10n,
                      formatDistance(state.remainingMeters),
                    ),
                  ),
            unlockedDates: unlocks[state.def.id] ?? const [],
            localeName: localeName,
          ),
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.state,
    required this.l10n,
    required this.onTap,
    required this.theme,
  });

  final AchievementState state;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final AppThemeId theme;

  @override
  Widget build(BuildContext context) {
    final unlocked = state.unlocked;
    final iconColor = unlocked ? AppColors.gold : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: _trophyTileDecoration(unlocked: unlocked),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 40, color: iconColor),
            const SizedBox(height: AppSpacing.sm),
            _AchievementTitleRow(
              def: state.def,
              theme: theme,
              l10n: l10n,
              color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
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
            const SizedBox(height: AppSpacing.sm),
            _AchievementProgressBar(
              fraction: progressFraction(
                progressMeters:
                    state.def.thresholdMeters - state.remainingMeters,
                totalMeters: state.def.thresholdMeters,
              ),
              showPercent: !unlocked,
            ),
          ],
        ),
      ),
    );
  }
}

/// A trophy's title, with a small themed illustration leading it (this
/// task's requirement — "на каждое достижение добавь небольшую иллюстрацию
/// в стиле выбранной темы") — shared by both grids so a given achievement
/// id always renders the same illustration wherever it's shown.
class _AchievementTitleRow extends StatelessWidget {
  const _AchievementTitleRow({
    required this.def,
    required this.theme,
    required this.l10n,
    required this.color,
  });

  final AchievementDef def;
  final AppThemeId theme;
  final AppLocalizations l10n;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(achievementIllustration(def, theme), size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            achievementTitle(l10n, def),
            style: AppTypography.body.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Styling fix: a plain grey rounded rectangle read as generic Material
/// design. Locked reads as a dim, bordered stone plaque; unlocked steps up
/// to [AppColors.surfaceActive] with a full-strength gold edge — "становится
/// золотой при разблокировке" — rather than only the icon/text changing
/// color.
BoxDecoration _trophyTileDecoration({required bool unlocked}) {
  return BoxDecoration(
    color: unlocked ? AppColors.surfaceActive : AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border: Border.all(
      color: unlocked ? AppColors.gold : AppColors.cardBorder,
      width: unlocked ? AppStroke.icon : AppStroke.cardBorder,
    ),
  );
}

/// A thin gold progress line at the bottom of every trophy tile (this task's
/// requirement — "нетолстую линию прогресса для каждого достижения... линия
/// должна заполняться золотым цветом по мере прогресса"), replacing the
/// earlier "thread" that only appeared on locked journey trophies. Now shown
/// unconditionally on every tile in both grids — [fraction] is already `1.0`
/// for an unlocked/completed one, so the line simply reads as fully filled
/// rather than disappearing.
///
/// [fraction] is `progress_fraction.dart`'s pure `0..1` value — this widget
/// only draws it, no math of its own. [showPercent] gates the small "N%"
/// label above the filled end (this task's requirement — "процент пропадает
/// когда достижение выполнено"): callers pass `false` once the achievement
/// this fraction belongs to is complete (the journey trophy itself for
/// [_AchievementTile], today's threshold for [_DailyAchievementTile]).
class _AchievementProgressBar extends StatelessWidget {
  const _AchievementProgressBar({
    required this.fraction,
    required this.showPercent,
  });

  final double fraction;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    const lineHeight = 3.0;
    const labelHeight = 14.0;

    return SizedBox(
      height: showPercent ? labelHeight + AppSpacing.xs + lineHeight : lineHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: SizedBox(
                height: lineHeight,
                child: Stack(
                  children: [
                    const ColoredBox(color: AppColors.cardBorder),
                    FractionallySizedBox(
                      widthFactor: fraction,
                      child: const ColoredBox(color: AppColors.gold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Positioned above the filled end of the line, not at a fixed
          // spot — `Align`'s `-1..1` range naturally keeps the label inside
          // the tile's width at both ends (0% and 100%) rather than letting
          // it overflow past either edge.
          if (showPercent)
            Positioned.fill(
              bottom: lineHeight,
              child: Align(
                alignment: Alignment(fraction * 2 - 1, 1),
                child: Text(
                  '${(fraction * 100).round()}%',
                  style: AppTypography.bodySecondary.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DailyGrid extends StatelessWidget {
  const _DailyGrid({
    required this.states,
    required this.todayMeters,
    required this.l10n,
    required this.localeName,
    required this.theme,
  });

  final List<DailyAchievementState> states;

  /// Today's total distance across every quest (this task's requirement —
  /// a daily trophy's progress line shows "today's progress", not the
  /// forever-cumulative unlock count [states] itself carries).
  final int todayMeters;
  final AppLocalizations l10n;
  final String localeName;
  final AppThemeId theme;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.95,
      ),
      itemCount: states.length,
      itemBuilder: (context, index) {
        final state = states[index];
        return _DailyAchievementTile(
          state: state,
          todayMeters: todayMeters,
          l10n: l10n,
          theme: theme,
          onTap: () => _showAchievementDetailsSheet(
            context,
            l10n: l10n,
            title: achievementTitle(l10n, state.def),
            statusLine: state.unlocked
                ? (state.unlockedCount > 1
                      ? l10n.achievementUnlockedCountLabel(state.unlockedCount)
                      : l10n.achievementUnlockedLabel)
                : l10n.achievementNeverUnlockedLabel,
            unlockedDates: state.unlockedDates,
            localeName: localeName,
            showStreak: true,
          ),
        );
      },
    );
  }
}

/// Diameter-ish padding of the small count badge on a daily tile earned on
/// more than one day (this task's requirement — "если получено больше 1 —
/// показывать число полученных"). `×N` rather than a translated phrase: a
/// compact numeral badge, the same kind of non-linguistic notation as the
/// existing em dash `quest_stats_tab.dart` renders for a zero-pace ETA — not
/// UI copy that needs an l10n key.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '×$count',
        style: AppTypography.bodySecondary.copyWith(
          color: AppColors.background,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DailyAchievementTile extends StatelessWidget {
  const _DailyAchievementTile({
    required this.state,
    required this.todayMeters,
    required this.l10n,
    required this.onTap,
    required this.theme,
  });

  final DailyAchievementState state;

  /// Today's total distance across every quest — see `_DailyGrid`'s own
  /// doc comment on this same field.
  final int todayMeters;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final AppThemeId theme;

  @override
  Widget build(BuildContext context) {
    final unlocked = state.unlocked;
    final iconColor = unlocked ? AppColors.gold : AppColors.textSecondary;
    final streak = currentStreak(state.unlockedDates);
    // Today's own fraction, not `unlocked` above (whether this trophy was
    // *ever* earned on some past day) — this task's requirement is "прогресс
    // за сегодняшний день", so the bar and its "N%" label answer "how close
    // is today", and the label disappears once today itself clears the
    // threshold, whether or not this trophy already has earlier unlock
    // dates.
    final todayFraction = progressFraction(
      progressMeters: todayMeters,
      totalMeters: state.def.thresholdMeters,
    );
    final unlockedToday = todayFraction >= 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: _trophyTileDecoration(unlocked: unlocked),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 40, color: iconColor),
                const SizedBox(height: AppSpacing.sm),
                _AchievementTitleRow(
                  def: state.def,
                  theme: theme,
                  l10n: l10n,
                  color: unlocked
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  unlocked
                      ? l10n.achievementUnlockedLabel
                      : l10n.achievementNeverUnlockedLabel,
                  style: AppTypography.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                _AchievementProgressBar(
                  fraction: todayFraction,
                  showPercent: !unlockedToday,
                ),
              ],
            ),
            if (state.unlockedCount > 1)
              Positioned(
                top: 0,
                right: 0,
                child: _CountBadge(count: state.unlockedCount),
              ),
            if (streak > 1)
              Positioned(top: 0, left: 0, child: _StreakBadge(streak: streak)),
          ],
        ),
      ),
    );
  }
}

/// The current unlock streak (this task's requirement — "стрик... добавь
/// стильный огонёк"), top-left so it never collides with [_CountBadge]'s
/// top-right corner — the two answer different questions ("how many times
/// total" vs "how many days in a row right now") and can both apply to the
/// same tile at once. Only rendered while the streak is more than one day,
/// same threshold `_CountBadge` already uses for its own count.
///
/// Gold rather than a separate "fire" hue — §9 keeps gold as the app's one
/// accent color; a flame icon reads as festive on its own without also
/// introducing a second accent color the rest of the design system doesn't
/// have.
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceActive,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.gold, width: AppStroke.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 12,
            color: AppColors.gold,
          ),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: AppTypography.bodySecondary.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a trophy's name, current status, and — once earned at least once —
/// every local calendar date it was earned on (this task's requirement:
/// "по клику — дни когда получен каждый трофей в обеих секциях"). Shared by
/// both grids so the two sections can never disagree on how this looks,
/// following the same bottom-sheet shape every other sheet in this app uses
/// (`settings_tab.dart`'s `_showLockScreenTroubleshootSheet`,
/// `journey_path_view.dart`'s own achievement-details sheet).
///
/// [showStreak] gates the longest-streak line (this task's requirement —
/// "в попапе... показывать так же самый долгий стрик"): only the Daily
/// grid passes `true`. A journey achievement unlocks at most once, so
/// [longestStreak] on its single-or-empty `unlockedDates` would only ever
/// read 0 or 1 — a line worth showing for a repeatable daily trophy, not
/// noise to add to a one-shot journey milestone.
void _showAchievementDetailsSheet(
  BuildContext context, {
  required AppLocalizations l10n,
  required String title,
  required String statusLine,
  required List<DateTime> unlockedDates,
  required String localeName,
  bool showStreak = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.heading),
          const SizedBox(height: AppSpacing.sm),
          Text(statusLine, style: AppTypography.bodySecondary),
          if (showStreak && unlockedDates.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.achievementLongestStreakLabel(longestStreak(unlockedDates)),
              style: AppTypography.bodySecondary.copyWith(
                color: AppColors.gold,
              ),
            ),
          ],
          if (unlockedDates.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.achievementUnlockDatesSheetTitle,
              style: AppTypography.label,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final date in unlockedDates)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  formatDate(date, localeName: localeName),
                  style: AppTypography.body,
                ),
              ),
          ],
        ],
      ),
    ),
  );
}
