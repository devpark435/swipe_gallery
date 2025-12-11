import 'package:flutter/material.dart';
import 'package:swipe_gallery/theme/app_color_theme.dart';
import 'package:swipe_gallery/theme/app_text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return _baseTheme(
      brightness: Brightness.light,
      colors: AppColorTheme.light,
    );
  }

  static ThemeData get dark {
    return _baseTheme(brightness: Brightness.dark, colors: AppColorTheme.dark);
  }

  static ThemeData _baseTheme({
    required Brightness brightness,
    required AppColorTheme colors,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [colors],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.surface,
        secondary: colors.secondary,
        onSecondary: colors.surface,
        error: colors.error,
        onError: colors.surface,
        surface: colors.surface,
        onSurface: colors.textPrimary,
      ),
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        color: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 6,
        margin: EdgeInsets.zero,
        shadowColor: colors.textSecondary.withOpacity(0.12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.textPrimary,
        contentTextStyle: TextStyle(
          color: colors.surface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: AppTextTheme.getTheme(colors),
    );
  }
}
