import '../../core/formatters.dart';
import '../../l10n/app_localizations.dart';

/// Localizes a [FormattedDistance]'s unit word (§5.4) — the one place that
/// turns [DistanceUnit] into the correctly declined ru/en noun, reused by
/// every screen that shows a distance instead of each re-deriving it.
String localizedUnitLabel(AppLocalizations l10n, FormattedDistance distance) {
  return switch (distance.unit) {
    DistanceUnit.meters => l10n.unitMeters(int.parse(distance.value)),
    DistanceUnit.kilometers => l10n.unitKilometers(
      double.parse(distance.value),
    ),
  };
}

/// `"<value> <unit>"` for inline use (e.g. a caption or a catalog card).
/// The large two-line hero presentation (§9: number on one line, unit
/// beneath) is built directly where it's used — see `journey_path_view.dart`.
String localizedDistanceInline(
  AppLocalizations l10n,
  FormattedDistance distance,
) {
  return '${distance.value} ${localizedUnitLabel(l10n, distance)}';
}
