import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../../../design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../journey/presentation/lock_screen_controller.dart';
import '../../journey/presentation/lock_screen_state.dart';
import 'locale_provider.dart';

/// Настройки (§6.5), trimmed to what this base ships: an optional sign-in
/// entry point and a working language switch. Everything else in §6.5
/// (stride, privacy, permission re-request, quest change) is a later slice.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final l10n = AppLocalizations.of(context)!;
    final lockScreenSupported = ref.watch(lockScreenSupportedProvider);

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
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.settingsSignInButton,
                  style: AppTypography.body,
                ),
                subtitle: Text(
                  l10n.settingsSignInSubtitle,
                  style: AppTypography.bodySecondary,
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.gold,
                ),
                onTap: () => _showSignInStub(context, l10n),
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

/// Sign-in is a UI stub today: real Firebase Auth wiring is Phase 8 and
/// needs its own architecture plan (§13) before it touches this button.
/// §8 already treats anonymous auth as the MVP default and login as
/// optional, so this is honest about what's here rather than pretending to
/// authenticate.
void _showSignInStub(BuildContext context, AppLocalizations l10n) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsSignInStubTitle, style: AppTypography.heading),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.settingsSignInStubBody, style: AppTypography.bodySecondary),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.settingsSignInStubClose,
                style: const TextStyle(color: AppColors.gold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
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
          if (state.permissionStatus == LockScreenPermissionStatus.denied)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                l10n.lockScreenPermissionDeniedBody,
                style: AppTypography.bodySecondary,
              ),
            ),
        ],
      ),
    );
  }
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
