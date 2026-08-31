import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme_id.dart';
import '../../../core/formatters.dart';
import '../../../design/colors.dart';
import '../../../design/components/app_card.dart';
import '../../../design/components/app_snackbar.dart';
import '../../../design/components/distance_text.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/presentation/theme_provider.dart';
import '../domain/friend_progress.dart';
import 'friends_providers.dart';

/// Друзья / Challengers (§6.4): a passive comparison table, plus the
/// pending-request sections and the add-by-nickname flow. No group quests,
/// no teams — every row is one person's own quest, on their own pace.
class ChallengersTab extends ConsumerWidget {
  const ChallengersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // This task's requirement: the tab stays inactive until login + a
    // nickname exist (§6.4/§6.5/§8) — `AppShell`'s bottom-nav tap already
    // blocks getting here in the first place; this is the belt-and-
    // suspenders guard for any other path that might still land on this
    // route (e.g. a restored navigation stack from before the account was
    // signed out, or a future deep link).
    if (!ref.watch(friendsUnlockedProvider)) {
      return _LockedPlaceholder(l10n: l10n);
    }

    // Bootstraps the signed-in user's own profile the first time a uid
    // exists — fire-and-forget, this screen doesn't block on it.
    ref.watch(ensureFriendProfileProvider);

    final myNickname = ref.watch(myProfileProvider).value?.nickname;
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
            _MyNicknameCard(nickname: myNickname, l10n: l10n),
            const SizedBox(height: AppSpacing.md),
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
                  onPrimary: () => _runFriendAction(
                    context,
                    l10n,
                    () => ref
                        .read(friendsControllerProvider.notifier)
                        .acceptRequest(request.pairId),
                  ),
                  secondaryLabel: l10n.friendsDeclineButton,
                  onSecondary: () => _runFriendAction(
                    context,
                    l10n,
                    () => ref
                        .read(friendsControllerProvider.notifier)
                        .removeOrDecline(request.pairId),
                  ),
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
                  onPrimary: () => _runFriendAction(
                    context,
                    l10n,
                    () => ref
                        .read(friendsControllerProvider.notifier)
                        .removeOrDecline(request.pairId),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (view.rows.length <= 1 &&
                view.incoming.isEmpty &&
                view.outgoing.isEmpty)
              _EmptyState(ref: ref, l10n: l10n)
            else
              for (final row in view.rows)
                _FriendRow(
                  row: row,
                  l10n: l10n,
                  myMeters: myMeters,
                  onRemove: row.pairId == null
                      ? null
                      : () => _runFriendAction(
                          context,
                          l10n,
                          () => ref
                              .read(friendsControllerProvider.notifier)
                              .removeOrDecline(row.pairId!),
                        ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Shown by [ChallengersTab] instead of its real content while
/// [friendsUnlockedProvider] is `false` — same AppBar/background shape as
/// the real tab (so the bottom-nav switch doesn't visibly jolt), just
/// without the add-friend button or any table to show yet.
class _LockedPlaceholder extends StatelessWidget {
  const _LockedPlaceholder({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(l10n.friendsTitle, style: AppTypography.heading),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.textSecondary,
                  size: 40,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.friendsLockedTitle,
                  style: AppTypography.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.friendsLockedBody,
                  style: AppTypography.bodySecondary,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs a fire-and-forget friend action (accept / decline / cancel /
/// remove — every `onPrimary`/`onSecondary`/`onRemove` callback below) and
/// surfaces a generic error snackbar if it throws. None of these have their
/// own outcome enum the way `addFriendByNickname` does — there is nothing
/// to disambiguate, "it worked" is the only expected result — so any
/// exception here (firestore.rules denying the write, no network) is
/// unexpected by definition.
///
/// Without this, the `Future<void>` these buttons kick off was never
/// awaited by anything (`VoidCallback` discards it) — a rejection just
/// became an unhandled Future error with nothing on screen to show for it:
/// a tap that visibly did nothing (§7 — never a dead end, not even a
/// silent one; the same fix `_showAddFriendDialog` applies to its own add-
/// friend flow, `settings_tab.dart`'s `_signInWithGoogle`/`_updateNickname`
/// to theirs).
void _runFriendAction(
  BuildContext context,
  AppLocalizations l10n,
  Future<void> Function() action,
) {
  unawaited(
    action().catchError((Object error) {
      debugPrint('Friend action failed: $error');
      if (context.mounted) showAppSnackBar(context, l10n.friendsOutcomeError);
    }),
  );
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

            String message;
            try {
              final outcome = await ref
                  .read(friendsControllerProvider.notifier)
                  .addFriendByNickname(nickname);
              message = _outcomeMessage(outcome, l10n);
            } catch (error) {
              // Anything beyond the known AddFriendOutcome cases —
              // firestore.rules denying the write, no network, a plugin
              // exception. Without this the request just silently failed:
              // the dialog had already closed above and the rejected
              // Future had nothing awaiting it, so nothing at all appeared
              // on screen and no `friendships/{pairId}` doc was created
              // (§7 — never a dead end, not even a silent one; the same
              // fix `settings_tab.dart`'s `_signInWithGoogle`/
              // `_updateNickname` already apply to their own flows).
              //
              // Logged (debug builds only, per `debugPrint`'s own
              // contract) so a report of "adding a friend does nothing" is
              // actually diagnosable — the caught error here carries only
              // an error code/message, never a nickname or uid, so this
              // doesn't violate §13's no-PII-in-logs rule.
              debugPrint('Add friend failed: $error');
              message = l10n.friendsOutcomeError;
            }

            if (!context.mounted) return;
            showAppSnackBar(context, message);
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
  };
}

/// The signed-in user's own nickname, pinned above everything else on this
/// tab so it's the first thing found here — the whole point of §6.4's
/// "add by nickname" flow is that a friend needs to *have* this nickname
/// before they can use it, and until now the only place it appeared was
/// this user's own row further down the same list.
class _MyNicknameCard extends StatelessWidget {
  const _MyNicknameCard({required this.nickname, required this.l10n});

  /// `null` while the profile hasn't loaded yet (no uid, or
  /// [ensureFriendProfileProvider] hasn't finished its first write) —
  /// rendered as a placeholder dash rather than an empty string so the card
  /// never looks broken.
  final String? nickname;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      highlighted: true,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.friendsMyNicknameLabel, style: AppTypography.label),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  nickname ?? '—',
                  style: AppTypography.body.copyWith(color: AppColors.gold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: AppColors.goldMuted),
            tooltip: l10n.friendsMyNicknameCopyTooltip,
            onPressed: nickname == null
                ? null
                : () => _copyNickname(context, nickname!, l10n),
          ),
        ],
      ),
    );
  }
}

Future<void> _copyNickname(
  BuildContext context,
  String nickname,
  AppLocalizations l10n,
) async {
  await Clipboard.setData(ClipboardData(text: nickname));
  if (!context.mounted) return;
  showAppSnackBar(context, l10n.friendsMyNicknameCopied);
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
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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

    return AppCard(
      highlighted: row.isSelf,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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

/// The Друзья tab's empty state — plain by default, but dressed up for
/// [AppThemeId.odyssey] (this task's requirement: "🏛️ Путь интереснее
/// вместе... это только для текущей темы Одиссея"). A future non-Odyssey
/// theme falls back to the same plain copy classic already used, rather
/// than inheriting Odyssey's illustration by accident.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.ref, required this.l10n});

  final WidgetRef ref;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(effectiveThemeProvider);
    final isOdyssey = theme == AppThemeId.odyssey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          if (isOdyssey) ...[
            // A placeholder glyph, not a real illustration asset — §9.1's
            // art source is still undecided; cheap to swap for a drawn
            // laurel-wreath/ship illustration once one exists.
            const Text('🏛️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            isOdyssey ? l10n.friendsEmptyOdysseyTitle : l10n.friendsEmptyTitle,
            style: AppTypography.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isOdyssey ? l10n.friendsEmptyOdysseyBody : l10n.friendsEmptyBody,
            style: AppTypography.bodySecondary,
            textAlign: TextAlign.center,
          ),
          if (isOdyssey) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => _showAddFriendDialog(context, ref, l10n),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
              ),
              icon: const Icon(Icons.add),
              label: Text(l10n.friendsAddButton),
            ),
          ],
        ],
      ),
    );
  }
}
