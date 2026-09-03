import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/journey_timing_repository.dart';
import '../domain/fictional_time.dart';
import 'journey_providers.dart';

part 'journey_timing_providers.g.dart';

/// The bundle a quest's fictional-time content is read from. A provider of
/// its own so a widget test can hand the screen a small in-memory
/// `locations.json` instead of the real one — same pattern as
/// `quest_map_providers.dart`'s `questMapBundle`.
@riverpod
AssetBundle journeyTimingBundle(Ref ref) => rootBundle;

/// The currently selected quest's in-fiction segment timings (§6.1) —
/// `null` before a quest is picked, or when that quest ships no
/// `locations.json` timing content at all (today: any quest other than
/// `odyssey-ithaca`). `journey_flame_scene_view.dart` treats both cases the
/// same way: fall back to the real device clock for the sky.
@riverpod
Future<List<JourneySegmentTiming>?> selectedJourneySegmentTimings(
  Ref ref,
) async {
  final journey = ref.watch(selectedJourneyDetailsProvider);
  if (journey == null) return null;
  return tryLoadJourneySegmentTimings(
    ref.watch(journeyTimingBundleProvider),
    journey.id,
  );
}
