import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/auth_provider.dart';
import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../journey/presentation/lock_screen_controller.dart';
import '../../journey/presentation/lock_screen_state.dart';
import 'locale_provider.dart';

/// Настройки (§6.5), trimmed to what this base ships: the Google sign-in
/// entry point and a working language switch. Everything else in §6.5
/// (stride, privacy, permission re-request, quest change) is a later slice.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final l10n = AppLocalizations.of(context)!;
    final lockScreenSupported = ref.watch(lockScreenSupportedProvider);
    final authState = ref.watch(authControllerProvider);

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
  final outcome = await ref
      .read(authControllerProvider.notifier)
      .upgradeWithGoogle();

  if (!context.mounted) return;
  final message = switch (outcome) {
    GoogleUpgradeOutcome.success => l10n.settingsSignInSuccessMessage,
    // The user just closed the account picker — not worth a toast.
    GoogleUpgradeOutcome.cancelled => null,
    GoogleUpgradeOutcome.alreadyLinked =>
      l10n.friendsOutcomeUpgradeAlreadyLinked,
  };
  if (message == null) return;
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
