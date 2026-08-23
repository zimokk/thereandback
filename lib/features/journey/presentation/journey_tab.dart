import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/colors.dart';
import '../../steps/presentation/permission_gate.dart';
import 'journey_path_view.dart';
import 'journey_providers.dart';
import 'quest_picker_view.dart';

/// Root of the Путь tab (§6.1): the quest catalog when nothing is selected,
/// or the path scene once a quest is active.
class JourneyTab extends ConsumerWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedJourneyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: selected == null
            ? const QuestPickerView()
            : const Column(
                children: [
                  StepsPermissionGate(),
                  Expanded(child: JourneyPathView()),
                ],
              ),
      ),
    );
  }
}
