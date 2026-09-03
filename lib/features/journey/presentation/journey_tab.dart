import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/colors.dart';
import '../../steps/presentation/permission_gate.dart';
import 'journey_flame_scene_view.dart';
import 'journey_providers.dart';
import 'quest_picker_view.dart';

/// Root of the Путь tab (§6.1): the quest catalog when nothing is selected,
/// or the path scene once a quest is active.
class JourneyTab extends ConsumerWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedJourneyProvider);
    // Bug fix (2026-09-03): `selected != null` alone used to be enough to
    // commit to the scene branch below — but `selected.journeyId` is
    // whatever was last persisted to drift (`selectedQuestRows`), which can
    // outlive a catalog change (a stale/renamed id from an older build, or
    // hand-edited local data) and no longer resolve to any entry in the
    // *current* `journeyCatalog`. `journey_flame_scene_view.dart` already
    // guards that exact case by rendering nothing (`SizedBox.shrink()`),
    // which on this tab's near-black `AppColors.background` (§9) reads as a
    // silent black screen instead of a helpful "pick a quest" — `journey ==
    // null` is watched here too so this branch is skipped in favor of the
    // catalog, the same recovery `quest_stats_tab.dart`'s own `journey ==
    // null` check already gives its own "Начните поход" empty state.
    final journey = ref.watch(selectedJourneyDetailsProvider);
    // Browsing the catalog (this task's requirement — the Путь scene's
    // top-left "choose another quest" button) shows the same picker a
    // never-started quest does, without touching the active quest itself.
    final browsing = ref.watch(browsingCatalogProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: (selected == null || journey == null || browsing)
            ? const QuestPickerView()
            : const Column(
                children: [
                  StepsPermissionGate(),
                  Expanded(child: JourneyFlameSceneView()),
                ],
              ),
      ),
    );
  }
}
