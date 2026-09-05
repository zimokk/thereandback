import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/journey_terrain_repository.dart';
import 'journey_providers.dart';

part 'journey_terrain_providers.g.dart';

/// The bundle a quest's terrain/prop content is read from. A provider of
/// its own so a widget test can hand the screen a small in-memory
/// `locations.json` instead of the real one — same pattern as
/// `journey_timing_providers.dart`'s `journeyTimingBundle`.
@riverpod
AssetBundle journeyTerrainBundle(Ref ref) => rootBundle;

/// The currently selected quest's terrain profile + anchored scene props
/// (§6.1) — `null` before a quest is picked, or when that quest ships no
/// `locations.json` content at all (today: any quest other than
/// `odyssey-ithaca`). `journey_flame_scene_view.dart` treats both cases the
/// same way: `terrain_layer.dart`'s placeholder sine wave, no anchored
/// props.
@riverpod
Future<JourneyTerrainContent?> selectedJourneyTerrainContent(Ref ref) async {
  final journey = ref.watch(selectedJourneyDetailsProvider);
  if (journey == null) return null;
  return tryLoadJourneyTerrainContent(
    ref.watch(journeyTerrainBundleProvider),
    journey.id,
  );
}
