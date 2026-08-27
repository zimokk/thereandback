import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../journey/presentation/journey_providers.dart';
import '../data/quest_map_repository.dart';

part 'quest_map_providers.g.dart';

/// The bundle quest map assets are read from. A provider of its own so a
/// widget test can hand the screen a small in-memory `map.json` instead of
/// the real one (`testing` skill), the same way `appDatabaseProvider` keeps
/// drift out of tests.
@riverpod
AssetBundle questMapBundle(Ref ref) => rootBundle;

/// The drawn map (§6.2) of the currently selected quest: `null` before a
/// quest is picked, an error when that quest ships no usable `map.json` —
/// the Карта tab renders its own fallback for both.
@riverpod
Future<QuestMapAssets?> selectedQuestMap(Ref ref) async {
  final journey = ref.watch(selectedJourneyDetailsProvider);
  if (journey == null) return null;
  return loadQuestMap(ref.watch(questMapBundleProvider), journey.id);
}
