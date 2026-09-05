import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../profile/presentation/locale_provider.dart';
import '../data/journey_narrative_repository.dart';
import '../domain/narrative_beat.dart';
import 'journey_providers.dart';

part 'journey_narrative_providers.g.dart';

/// The bundle a quest's narrative content is read from — a provider of its
/// own so a widget test can hand the screen a small in-memory
/// `locations.json` instead of the real one, same pattern as
/// `journey_timing_providers.dart`'s `journeyTimingBundle`.
@riverpod
AssetBundle journeyNarrativeBundle(Ref ref) => rootBundle;

/// The currently selected quest's narrative beats (§5, §6.1) — `null`
/// before a quest is picked, or when that quest ships no `locations.json`
/// content at all. `journey_flame_scene_view.dart` falls back to its
/// placeholder narrative line in both cases, and again when the scrolled-to
/// position sits before the first beat (`narrativeBeatFor`'s own `null`).
///
/// Re-reads whenever [appLocaleProvider] changes, so switching the app's
/// language in Настройки swaps in the translated overlay (today: `ru` on
/// `tower-of-lights`) without needing to leave and reopen the tab.
@riverpod
Future<List<NarrativeBeat>?> selectedJourneyNarrativeBeats(Ref ref) async {
  final journey = ref.watch(selectedJourneyDetailsProvider);
  if (journey == null) return null;
  final languageCode = ref.watch(appLocaleProvider).languageCode;
  return tryLoadJourneyNarrativeBeats(
    ref.watch(journeyNarrativeBundleProvider),
    journey.id,
    languageCode,
  );
}
