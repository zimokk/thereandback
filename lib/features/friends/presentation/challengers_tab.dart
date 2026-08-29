import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/friend_progress.dart';
import 'friends_providers.dart';

/// Друзья / Challengers (§6.4): a passive comparison table, plus the
/// pending-request sections and the add-by-nickname flow. No group quests,
/// no teams — every row is one person's own quest, on their own pace.
class ChallengersTab extends ConsumerWidget {
  const ChallengersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bootstraps the signed-in user's own profile the first time a uid
    // exists — fire-and-forget, this screen doesn't block on it.
    ref.watch(ensureFriendProfileProvider);

    final l10n = AppLocalizations.of(context)!;
    final view = ref.watch(friendsViewProvider).value ?? FriendsViewData.empty;
    final myMeters = view.rows
        .firstWhere(
          (r) => r.isSelf,
          orElse: () => const FriendProgressRow(
            uid: '',
            nickname: '',
            progressMeters: 0,
            isSelf: true,
          ),
        )
        .progressMeters;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(l10n.friendsTitle, style: AppTypography.heading),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.gold),
            tooltip: l10n.friendsAddButton,
            onPressed: () => _showAddFriendDialog(context, ref, l10n),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (view.incoming.isNotEmpty) ...[
              Text(
                l10n.friendsPendingIncomingTitle,
                style: AppTypography.label,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final request in view.incoming)
                _PendingRequestTile(
                  label: l10n.friendsIncomingRequestLabel(
                    request.otherNickname,
                  ),
                  primaryLabel: l10n.friendsAcceptButton,
                  onPrimary: () => ref
                      .read(friendsControllerProvider.notifier)
                      .acceptRequest(request.pairId),
                  secondaryLabel: l10n.friendsDeclineButton,
                  onSecondary: () => ref
                      .read(friendsControllerProvider.notifier)
                      .removeOrDecline(request.pairId),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (view.outgoing.isNotEmpty) ...[
              Text(
                l10n.friendsPendingOutgoingTitle,
                style: AppTypography.label,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final request in view.outgoing)
                _PendingRequestTile(
                  label: l10n.friendsOutgoingRequestLabel(
                    request.otherNickname,
                  ),
                  primaryLabel: l10n.friendsCancelRequestButton,
                  onPrimary: () => ref
                      .read(friendsControllerProvider.notifier)
                      .removeOrDecline(request.pairId),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (view.rows.length <= 1 &&
                view.incoming.isEmpty &&
                view.outgoing.isEmpty)
              _EmptyState(l10n: l10n)
            else
              for (final row in view.rows)
                _FriendRow(
                  row: row,
                  l10n: l10n,
                  myMeters: myMeters,
                  onRemove: row.pairId == null
                      ? null
                      : () => ref
                            .read(friendsControllerProvider.notifier)
                            .removeOrDecline(row.pairId!),
                ),
          ],
        ),
      ),
    );
  }
}

void _showAddFriendDialog(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.friendsAddDialogTitle, style: AppTypography.heading),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: AppTypography.body,
        decoration: InputDecoration(labelText: l10n.friendsAddNicknameLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            l10n.friendsAddCancel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () async {
            final nickname = controller.text.trim();
            if (nickname.isEmpty) return;
            Navigator.of(dialogContext).pop();

            final outcome = await ref
                .read(friendsControllerProvider.notifier)
                .addFriendByNickname(nickname);

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_outcomeMessage(outcome, l10n))),
            );
          },
          child: Text(
            l10n.friendsAddSubmit,
            style: const TextStyle(color: AppColors.gold),
          ),
        ),
      ],
    ),
  );
}

String _outcomeMessage(AddFriendOutcome outcome, AppLocalizations l10n) {
  return switch (outcome) {
    AddFriendOutcome.sent => l10n.friendsOutcomeSent,
    AddFriendOutcome.nicknameNotFound => l10n.friendsOutcomeNicknameNotFound,
    AddFriendOutcome.cannotAddSelf => l10n.friendsOutcomeCannotAddSelf,
    AddFriendOutcome.alreadyExists => l10n.friendsOutcomeAlreadyExists,
    AddFriendOutcome.notSignedIn => l10n.friendsOutcomeNotSignedIn,
    AddFriendOutcome.googleUpgradeCancelled =>
      l10n.friendsOutcomeUpgradeCancelled,
    AddFriendOutcome.googleUpgradeAlreadyLinked =>
      l10n.friendsOutcomeUpgradeAlreadyLinked,
  };
}

class _PendingRequestTile extends StatelessWidget {
  const _PendingRequestTile({
    required this.label,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String label;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.body)),
          if (secondaryLabel != null)
            TextButton(
              onPressed: onSecondary,
              child: Text(
                secondaryLabel!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          TextButton(
            onPressed: onPrimary,
            child: Text(
              primaryLabel,
              style: const TextStyle(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.row,
    required this.l10n,
    required this.myMeters,
    required this.onRemove,
  });

  final FriendProgressRow row;
  final AppLocalizations l10n;
  final int myMeters;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final distance = formatDistance(row.progressMeters);
    final pinColor =
        AppColors.friendPinPalette[row.pinColorIndex %
            AppColors.friendPinPalette.length];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: row.isSelf ? Border.all(color: AppColors.gold) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: row.isSelf ? AppColors.gold : pinColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              row.isSelf
                  ? '${row.nickname} (${l10n.friendsYouLabel})'
                  : row.nickname,
              style: AppTypography.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                localizedDistanceInline(l10n, distance),
                style: AppTypography.body,
              ),
              if (!row.isSelf)
                Text(
                  _signedDeltaLabel(l10n, myMeters: myMeters, row: row),
                  style: AppTypography.bodySecondary,
                ),
            ],
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.textSecondary,
              ),
              tooltip: l10n.friendsRemoveButton,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

String _signedDeltaLabel(
  AppLocalizations l10n, {
  required int myMeters,
  required FriendProgressRow row,
}) {
  final delta = friendDeltaMeters(
    myMeters: myMeters,
    friendMeters: row.progressMeters,
  );
  final formatted = formatSignedDistance(delta);
  final unit = localizedUnitLabel(
    l10n,
    FormattedDistance(value: formatted.value, unit: formatted.unit),
  );
  return '${formatted.value} $unit';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Text(
            l10n.friendsEmptyTitle,
            style: AppTypography.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.friendsEmptyBody,
            style: AppTypography.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
