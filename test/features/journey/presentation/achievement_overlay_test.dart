import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thereandback/design/colors.dart';
import 'package:thereandback/features/achievements/data/achievement_catalog.dart';
import 'package:thereandback/features/achievements/domain/achievement.dart';
import 'package:thereandback/features/achievements/presentation/achievement_titles.dart';
import 'package:thereandback/features/journey/presentation/achievement_overlay.dart';
import 'package:thereandback/core/formatters.dart';
import 'package:thereandback/design/components/distance_text.dart';
import 'package:thereandback/l10n/app_localizations.dart';

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

final _firstStepsDef = achievementCatalog.firstWhere(
  (def) => def.id == 'first-steps',
);

void main() {
  group('AchievementMarkerOverlay (§6.2/§6.3)', () {
    testWidgets('a locked marker renders muted and outlined', (tester) async {
      await tester.pumpWidget(
        _app(
          AchievementMarkerOverlay(
            achievements: [
              VisibleAchievement(
                state: AchievementState(
                  def: _firstStepsDef,
                  unlocked: false,
                  remainingMeters: 500,
                ),
                x: 100,
              ),
            ],
            sceneHeight: 400,
            pixelsPerMeter: 0.04,
            terrainProfile: null,
            l10n: await AppLocalizations.delegate.load(const Locale('en')),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.emoji_events_outlined);
      expect(icon.color, AppColors.textSecondary);
    });

    testWidgets('an unlocked marker renders gold and filled', (tester) async {
      await tester.pumpWidget(
        _app(
          AchievementMarkerOverlay(
            achievements: [
              VisibleAchievement(
                state: AchievementState(
                  def: _firstStepsDef,
                  unlocked: true,
                  remainingMeters: 0,
                ),
                x: 100,
              ),
            ],
            sceneHeight: 400,
            pixelsPerMeter: 0.04,
            terrainProfile: null,
            l10n: await AppLocalizations.delegate.load(const Locale('en')),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.emoji_events);
      expect(icon.color, AppColors.gold);
    });

    testWidgets(
      'shows nothing until tapped, then opens a sheet with name and status',
      (tester) async {
        final l10n = await AppLocalizations.delegate.load(const Locale('en'));
        await tester.pumpWidget(
          _app(
            AchievementMarkerOverlay(
              achievements: [
                VisibleAchievement(
                  state: AchievementState(
                    def: _firstStepsDef,
                    unlocked: false,
                    remainingMeters: 500,
                  ),
                  x: 100,
                ),
              ],
              sceneHeight: 400,
              pixelsPerMeter: 0.04,
              terrainProfile: null,
              l10n: l10n,
            ),
          ),
        );

        final expectedTitle = achievementTitle(l10n, _firstStepsDef);
        final expectedStatus = l10n.achievementRemainingLabel(
          localizedDistanceInline(l10n, formatDistance(500)),
        );

        expect(find.text(expectedTitle), findsNothing);

        await tester.tap(
          find.byKey(Key('achievementMarker-${_firstStepsDef.id}')),
        );
        await tester.pumpAndSettle();

        expect(find.text(expectedTitle), findsOneWidget);
        expect(find.text(expectedStatus), findsOneWidget);
      },
    );

    testWidgets('paints a dotted guide line down to the horizon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 400,
            height: 400,
            child: AchievementMarkerOverlay(
              achievements: [
                VisibleAchievement(
                  state: AchievementState(
                    def: _firstStepsDef,
                    unlocked: false,
                    remainingMeters: 500,
                  ),
                  x: 100,
                ),
              ],
              sceneHeight: 400,
              pixelsPerMeter: 0.04,
              terrainProfile: null,
              l10n: await AppLocalizations.delegate.load(const Locale('en')),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint).first, paints..line());
    });
  });
}
