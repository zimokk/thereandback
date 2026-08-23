import 'package:intl/intl.dart';

/// A formatted distance ready for display: the number and its unit label
/// are kept separate because the design renders them on two lines (§5.4, §9).
class FormattedDistance {
  const FormattedDistance({required this.value, required this.unit});

  /// The number as a string, already following the §5.4 precision rule.
  final String value;

  /// `meters` or `kilometers` — presentation is responsible for localizing
  /// this label; it is not translated here.
  final DistanceUnit unit;
}

enum DistanceUnit { meters, kilometers }

/// Formats whole meters into a display string per CLAUDE.md §5.4:
///
/// - below 1 000 m: whole meters (`196`)
/// - 1 km – 100 km: two decimals (`5.23`)
/// - above 100 km: whole kilometers (`2853`)
///
/// The domain always deals in integer meters; this is the only place that
/// turns them into a display string. Metric only — no miles setting exists
/// or is planned (§5.4, §6.5).
FormattedDistance formatDistance(int meters) {
  assert(meters >= 0, 'distance is never negative (progress is monotonic)');

  if (meters < 1000) {
    return FormattedDistance(value: '$meters', unit: DistanceUnit.meters);
  }

  final km = meters / 1000;
  if (km <= 100) {
    return FormattedDistance(
      value: km.toStringAsFixed(2),
      unit: DistanceUnit.kilometers,
    );
  }

  return FormattedDistance(
    value: km.round().toString(),
    unit: DistanceUnit.kilometers,
  );
}

/// Formats an ETA date using the given locale's date format, or `null` when
/// there is no meaningful estimate (zero pace) — the caller renders that as
/// a dash, never as an infinite or NaN date (§5.3).
String? formatEtaDate(DateTime? eta, {required String localeName}) {
  if (eta == null) return null;
  return DateFormat.yMMMd(localeName).format(eta);
}

/// Formats a plain date (e.g. "Quest Started") using the locale's format —
/// never a hand-rolled `dd.MM.yyyy` (§11, `l10n` skill).
String formatDate(DateTime date, {required String localeName}) {
  return DateFormat.yMMMd(localeName).format(date);
}
