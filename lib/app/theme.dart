import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/typography.dart';

/// `ThemeData` built from the design tokens (§9). Dark is the only theme —
/// there is no `ThemeMode.light` to build.
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'serif',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.gold,
      surface: AppColors.surface,
      onPrimary: AppColors.background,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    dividerColor: AppColors.divider,
    textTheme: const TextTheme(
      headlineSmall: AppTypography.heading,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.bodySecondary,
      labelLarge: AppTypography.label,
    ),
  );
}
