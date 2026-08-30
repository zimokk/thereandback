import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/auth_provider.dart';
import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../friends/presentation/friends_providers.dart';
import '../../journey/presentation/lock_screen_controller.dart';
import '../../journey/presentation/lock_screen_state.dart';
import 'locale_provider.dart';

/// Настройки (§6.5), trimmed to what this base ships: the Google sign-in
/// entry point, an editable nickname, and a working language switch.
/// Everything else in §6.5 (stride, privacy, permission re-request, quest
/// change) is a later slice.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final l10n = AppLocalizations.of(context)!;
    final lockScreenSupported = ref.watch(lockScreenSupportedProvider);
    final authState = ref.watch(authControllerProvider);
    // Bootstraps the signed-in user's own `users/{uid}` profile the first
    // time a uid exists — same fire-and-forget call the Challengers tab
    // makes (`ensureFriendProfileProvider`'s own doc comment). Watching it
    // here too means the nickname row below works even for someone who
    // never opens the Friends tab first.
    ref.watch(ensureFriendProfileProvider);
    final nickname = ref.watch(myProfileProvider).value?.nickname;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(l10n.settingsTitle, style: AppTypography.heading),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _SectionCard(
              title: l10n.settingsAccountSectionTitle,
              // Same upgrade the friends feature triggers when adding a
              // friend while still anonymous (`AuthController
              // .upgradeWithGoogle`) — this row is a second, equally real
              // entry point to it, not a separate flow. Once linked
              // (`!isAnonymous`) there's nothing left to tap: the row just
              // confirms the state.
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  authState.isAnonymous
                      ? l10n.settingsSignInButton
                      : l10n.settingsSignedInTitle,
                  style: AppTypography.body,
                ),
                subtitle: Text(
                  authState.isAnonymous
                      ? l10n.settingsSignInSubtitle
                      : l10n.settingsSignedInSubtitle,
                  style: AppTypography.bodySecondary,
                ),
                trailing: Icon(
                  authState.isAnonymous
                      ? Icons.chevron_right
                      : Icons.check_circle,
                  color: AppColors.gold,
                ),
                onTap: authState.isAnonymous
                    ? () => _signInWithGoogle(context, ref, l10n)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.settingsNicknameSectionTitle,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  nickname ?? l10n.settingsNicknameLoading,
                  style: AppTypography.body.copyWith(color: AppColors.gold),
                ),
                trailing: Tooltip(
                  message: l10n.settingsNicknameEditTooltip,
                  child: const Icon(Icons.edit, color: AppColors.gold),
                ),
                // Used to be `onTap: nickname == null ? null : ...` — a
                // literal no-op while the profile hadn't loaded (no uid
                // yet, or ensureFriendProfileProvider's first write hasn't
                // landed, or that write failed outright and never
                // retries on its own). Visually indistinguishable from the
                // enabled row, so a tap there just silently did nothing —
                // the same dead-end shape the sign-in row above used to
                // have before it was fixed to surface a message (§7: never
                // a dead end, not even silent). Now it always does
                // something: opens the editor once a nickname exists, or
                // retries the bootstrap write and says so otherwise.
                onTap: () => nickname == null
                    ? _retryProfileLoad(context, ref, l10n)
                    : _showEditNicknameDialog(context, ref, l10n, nickname),
              ),
            ),
            if (lockScreenSupported) ...[
              const SizedBox(height: AppSpacing.md),
              const _LockScreenSection(),
            ],
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.settingsLanguageSectionTitle,
              child: RadioGroup<Locale>(
                groupValue: locale,
                onChanged: (value) => value == null
                    ? null
                    : ref.read(appLocaleProvider.notifier).setLocale(value),
                child: Column(
                  children: [
                    RadioListTile<Locale>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.settingsLanguageRussian,
                        style: AppTypography.body,
                      ),
                      value: const Locale('ru'),
                      activeColor: AppColors.gold,
                    ),
                    RadioListTile<Locale>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.settingsLanguageEnglish,
                        style: AppTypography.body,
                      ),
                      value: const Locale('en'),
                      activeColor: AppColors.gold,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Upgrades the current anonymous Firebase session to a permanent one
/// backed by a Google identity (§8, §14) — same call the friends feature
/// makes from "Add friend" (`friends_providers.dart`'s
/// `addFriendByNickname`), just triggered from Settings instead. The three
/// `GoogleUpgradeOutcome` cases (§8's own outbound: success / a plain
/// cancel / an identity already linked elsewhere) are rendered explicitly
/// rather than only ever surfacing a bare exception.
Future<void> _signInWithGoogle(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) async {
  String? message;
  try {
    final outcome = await ref
        .read(authControllerProvider.notifier)
        .upgradeWithGoogle();
    message = switch (outcome) {
      GoogleUpgradeOutcome.success => l10n.settingsSignInSuccessMessage,
      // The user just closed the account picker — not worth a toast.
      GoogleUpgradeOutcome.cancelled => null,
      GoogleUpgradeOutcome.existingAccountRestored =>
        l10n.settingsSignInRestoredMessage,
    };
  } catch (error) {
    // Anything beyond the known GoogleUpgradeOutcome cases — no network,
    // Google sign-in misconfigured on this build, a plugin/platform
    // exception. Without this the row used to fail silently: the Future
    // rejected with nothing awaiting it, so the tap visibly did nothing
    // (§7 — never a dead end, not even a silent one).
    //
    // Logged (debug builds only, per `debugPrint`'s own contract) so a
    // report of "sign-in failed" is diagnosable — the caught types here
    // (FirebaseAuthException, GoogleSignInException, PlatformException)
    // carry only an error code/message, never the idToken or account
    // email, so this doesn't violate §13's no-PII-in-logs rule.
    debugPrint('Google sign-in failed: $error');
    message = context.mounted ? l10n.settingsSignInErrorMessage : null;
  }

  if (!context.mounted || message == null) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Handles a tap on the nickname row while [SettingsTab] hasn't resolved a
/// nickname yet — retries [ensureFriendProfileProvider] (in case its first
/// write failed, e.g. a transient Firestore error, and just never got
/// another chance) and tells the user why nothing opened, rather than the
/// tap being a silent no-op.
void _retryProfileLoad(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) {
  ref.invalidate(ensureFriendProfileProvider);
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(l10n.settingsNicknameNotReadyMessage)));
}

/// Prompts for a new nickname, pre-filled with the current one — same
/// dialog shape as `challengers_tab.dart`'s add-friend dialog.
void _showEditNicknameDialog(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
  String currentNickname,
) {
  final controller = TextEditingController(text: currentNickname);
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        l10n.settingsNicknameEditDialogTitle,
        style: AppTypography.heading,
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: AppTypography.body,
        decoration: InputDecoration(labelText: l10n.settingsNicknameFieldLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            l10n.settingsNicknameCancelButton,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () {
            final newNickname = controller.text.trim();
            Navigator.of(dialogContext).pop();
            // Empty, or retyped exactly as-is — nothing to save, and
            // updateNickname() would just reject an empty one anyway (the
            // Firestore doc requires a non-empty `usernames/{...}` key).
            if (newNickname.isEmpty || newNickname == currentNickname) return;
            unawaited(_updateNickname(context, ref, l10n, newNickname));
          },
          child: Text(
            l10n.settingsNicknameSaveButton,
            style: const TextStyle(color: AppColors.gold),
          ),
        ),
      ],
    ),
  );
}

/// Renames the signed-in user's own nickname (§6.5, §8) via
/// `FriendsController.updateNickname` — the same `usernames/{nicknameLower}`
/// uniqueness registry "add friend by nickname" already relies on, so a
/// taken nickname is rejected here the same way it would be there. Every
/// `UpdateNicknameOutcome` case is rendered explicitly, plus a catch-all for
/// anything else (mirrors `_signInWithGoogle` above — never a silent dead
/// end, §7).
Future<void> _updateNickname(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
  String newNickname,
) async {
  String message;
  try {
    final outcome = await ref
        .read(friendsControllerProvider.notifier)
        .updateNickname(newNickname);
    message = switch (outcome) {
      UpdateNicknameOutcome.success => l10n.settingsNicknameUpdatedMessage,
      UpdateNicknameOutcome.nicknameTaken => l10n.settingsNicknameTakenMessage,
      // Not reachable from this row in practice (it's disabled until a
      // profile — and so a uid — exists), but rendered rather than assumed
      // impossible.
      UpdateNicknameOutcome.notSignedIn => l10n.settingsNicknameErrorMessage,
    };
  } catch (error) {
    debugPrint('Nickname update failed: $error');
    message = l10n.settingsNicknameErrorMessage;
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// The §7 "persistent lock screen / notification shade" toggle. Off by
/// default — turning it on requests two OS permissions
/// (`POST_NOTIFICATIONS` and Health Connect's background-read permission)
/// through `lock_screen_controller.dart`'s `enable()`, so the subtitle
/// explains what's about to be asked before the prompts show up (§7: never
/// request without explaining first).
class _LockScreenSection extends ConsumerWidget {
  const _LockScreenSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lockScreenControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return _SectionCard(
      title: l10n.settingsLockScreenSectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.gold,
            title: Text(
              l10n.settingsLockScreenToggleTitle,
              style: AppTypography.body,
            ),
            subtitle: Text(
              l10n.settingsLockScreenToggleSubtitle,
              style: AppTypography.bodySecondary,
            ),
            value: state.enabled,
            onChanged: state.isBusy
                ? null
                : (value) => value
                      ? ref.read(lockScreenControllerProvider.notifier).enable()
                      : ref
                            .read(lockScreenControllerProvider.notifier)
                            .disable(),
          ),
          if (state.permissionStatus ==
              LockScreenPermissionStatus.healthConnectMissing)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.lockScreenHealthConnectMissingBody,
                    style: AppTypography.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => ref
                          .read(lockScreenControllerProvider.notifier)
                          .openHealthConnectInstall(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.background,
                      ),
                      child: Text(l10n.stepsHealthConnectInstall),
                    ),
                  ),
                ],
              ),
            ),
          if (state.permissionStatus ==
              LockScreenPermissionStatus.permanentlyDenied) ...[
            // Android stopped offering the dialog again after two denials
            // (`USER_FIXED`) — flipping the toggle again can't show it, so
            // this is a distinct dead-end-free path (§7), not the ordinary
            // "denied" copy below.
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                l10n.lockScreenPermissionPermanentlyDeniedBody,
                style: AppTypography.bodySecondary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: () => ref
                      .read(lockScreenControllerProvider.notifier)
                      .openAppSettings(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.background,
                  ),
                  child: Text(l10n.lockScreenPermissionOpenSettings),
                ),
              ),
            ),
          ] else if (state.permissionStatus ==
              LockScreenPermissionStatus.denied) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                l10n.lockScreenPermissionDeniedBody,
                style: AppTypography.bodySecondary,
              ),
            ),
            // Name the permission that is actually missing: the toggle needs
            // both, and saying only "permission wasn't granted" reads as a
            // flat contradiction when the user can see one of them granted
            // in Android's own settings.
            if (!state.notificationsGranted)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  l10n.lockScreenPermissionMissingNotifications,
                  style: AppTypography.bodySecondary,
                ),
              ),
            if (!state.backgroundHealthGranted)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  l10n.lockScreenPermissionMissingBackgroundHealth,
                  style: AppTypography.bodySecondary,
                ),
              ),
          ],
          if (state.enabled)
            // Every permission this app can request/check is granted at
            // this point, yet the OS-level display can still be blocked by
            // a manufacturer-specific setting (mainly MIUI) this app has no
            // API to detect or request — §7 "never a dead end" applies here
            // too, just pointed at OS settings instead of another prompt.
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => _showLockScreenTroubleshootSheet(context, l10n),
                child: Text(
                  l10n.lockScreenTroubleshootLink,
                  style: AppTypography.bodySecondary.copyWith(
                    color: AppColors.gold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The manufacturer-specific (mainly MIUI) lock-screen-display checklist —
/// see `_LockScreenSection`'s doc comment above for why this exists as a
/// sheet rather than an OS permission request.
void _showLockScreenTroubleshootSheet(
  BuildContext context,
  AppLocalizations l10n,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    // The checklist body is long (five numbered steps) — a plain Column
    // overflows on shorter viewports (small phones, landscape) since a
    // bottom sheet doesn't grow past a fraction of the screen height on its
    // own. `isScrollControlled` lets the sheet grow taller, and the
    // `SingleChildScrollView` below lets the remaining overflow scroll
    // instead of erroring.
    isScrollControlled: true,
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.lockScreenTroubleshootTitle, style: AppTypography.heading),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.lockScreenTroubleshootBody,
            style: AppTypography.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.lockScreenTroubleshootClose,
                style: const TextStyle(color: AppColors.gold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      // ListTile/RadioListTile paint their background and ink splashes on
      // the nearest Material ancestor — without this, the surrounding
      // DecoratedBox below hides both (and Flutter asserts about it).
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}
