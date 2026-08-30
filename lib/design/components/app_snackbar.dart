import 'package:flutter/material.dart';

/// Decides whether a repeated message should actually show again, without
/// touching `ScaffoldMessenger`/`BuildContext` at all — kept as a plain
/// class (rather than inline state in [showAppSnackBar]) so the debounce
/// decision itself can be unit-tested directly
/// (`test/design/components/app_snackbar_test.dart`), deterministically,
/// instead of through `SnackBar`'s own display-duration/animation timing in
/// a widget test.
///
/// This is the general fix for "the same notification appearing 20 times
/// in a row" (§7): a rapid double-tap, a retried async call, or a bug that
/// re-fires the same event repeatedly would otherwise each queue up their
/// own identical `SnackBar`, and `ScaffoldMessenger` dutifully shows every
/// one of them back to back.
@visibleForTesting
class SnackBarDebouncer {
  SnackBarDebouncer({this.window = const Duration(seconds: 3)});

  /// How long an identical message must go unrepeated before [shouldShow]
  /// allows it again — chosen to roughly match a `SnackBar`'s own default
  /// visible duration (~4s): while one is still up, or has only just gone
  /// away, a repeat of the exact same message is vanishingly unlikely to be
  /// new information for the user.
  final Duration window;

  String? _lastMessage;
  DateTime? _lastShownAt;

  /// Whether [message], observed at [now], should actually be shown.
  /// `false` only for an exact repeat of the immediately-preceding message
  /// within [window] — a genuinely different message is never suppressed,
  /// even the instant after an unrelated one went through. A `true` answer
  /// records [message]/[now] as the new "last shown" pair, which the next
  /// call's own decision is based on.
  bool shouldShow(String message, DateTime now) {
    final lastShownAt = _lastShownAt;
    if (message == _lastMessage &&
        lastShownAt != null &&
        now.difference(lastShownAt) < window) {
      return false;
    }
    _lastMessage = message;
    _lastShownAt = now;
    return true;
  }
}

/// Process-wide, not per-screen — this app never shows two unrelated
/// scaffolds at once, and a single shared debouncer is what actually stops
/// "the same event fired from two different call sites within a second of
/// each other" from stacking, not just repeats from one call site.
final _debouncer = SnackBarDebouncer();

/// Shows a `SnackBar` with [message] — the one funnel every in-app
/// notification in this app goes through, debounced via [_debouncer] so an
/// exact repeat within its [SnackBarDebouncer.window] is silently dropped
/// instead of queuing another identical `SnackBar` behind the current one.
///
/// Debounced by message text, not by call site — two different rows
/// producing identical copy still collapse into one shown `SnackBar`.
void showAppSnackBar(BuildContext context, String message) {
  if (!_debouncer.shouldShow(message, DateTime.now())) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
