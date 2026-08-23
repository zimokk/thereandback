/// Spacing, radius and stroke tokens (CLAUDE.md §9). Feature widgets pull
/// from here instead of writing a magic `EdgeInsets.all(13)`.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double card = 12;
  static const double sheet = 20;
  static const double pill = 999;
}

abstract final class AppStroke {
  /// Uniform stroke width for the thin gold line icons (§9).
  static const double icon = 1.5;

  /// Stroke width for the placeholder path line on the Путь tab.
  static const double path = 2;
}
