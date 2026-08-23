import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import 'steps_providers.dart';
import 'steps_sync_state.dart';

/// The permission explanation / denied / Health-Connect-missing card for
/// the Путь tab (§7: never a dead end — always an explanation and a way
/// forward). Renders nothing once access is granted, and nothing before the
/// first status check resolves.
class StepsPermissionGate extends ConsumerWidget {
  const StepsPermissionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stepsSyncProvider);
    final l10n = AppLocalizations.of(context)!;

    switch (state.permissionStatus) {
      case StepsPermissionStatus.unknown:
      case StepsPermissionStatus.granted:
        return const SizedBox.shrink();

      case StepsPermissionStatus.notRequested:
        return _GateCard(
          title: l10n.stepsPermissionExplainTitle,
          body: l10n.stepsPermissionExplainBody,
          buttonLabel: l10n.stepsPermissionAllow,
          busy: state.isSyncing,
          onPressed: () =>
              ref.read(stepsSyncProvider.notifier).requestPermission(),
        );

      case StepsPermissionStatus.denied:
        return _GateCard(
          title: l10n.stepsPermissionDeniedTitle,
          body: l10n.stepsPermissionDeniedBody,
          buttonLabel: l10n.stepsPermissionRetry,
          busy: state.isSyncing,
          onPressed: () =>
              ref.read(stepsSyncProvider.notifier).requestPermission(),
        );

      case StepsPermissionStatus.healthConnectMissing:
        return _GateCard(
          title: l10n.stepsHealthConnectMissingTitle,
          body: l10n.stepsHealthConnectMissingBody,
          buttonLabel: l10n.stepsHealthConnectInstall,
          busy: state.isSyncing,
          onPressed: () =>
              ref.read(stepsSyncProvider.notifier).openHealthConnectInstall(),
        );
    }
  }
}

class _GateCard extends StatelessWidget {
  const _GateCard({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
    required this.busy,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.heading),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: AppTypography.bodySecondary),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: busy ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
