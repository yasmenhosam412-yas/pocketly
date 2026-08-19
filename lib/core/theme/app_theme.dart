import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:imrpo/core/theme/app_color_scheme.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColorScheme.light);

  static ThemeData get dark => _build(AppColorScheme.dark);

  static TextTheme _textTheme(TextTheme base, AppColorScheme scheme) {
    final quicksand = GoogleFonts.quicksandTextTheme(base);
    return quicksand.apply(
      bodyColor: scheme.textPrimary,
      displayColor: scheme.textPrimary,
    );
  }

  static ThemeData _build(AppColorScheme scheme) {
    final isDark = scheme == AppColorScheme.dark;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.onWarm,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onWarm,
        tertiary: AppColors.plans,
        surface: scheme.card,
        onSurface: scheme.textPrimary,
        error: AppColors.error,
        onError: AppColors.onWarm,
        outline: scheme.border,
      ),
      scaffoldBackgroundColor: scheme.scaffold,
    );

    final textTheme = _textTheme(base.textTheme, scheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: _textTheme(base.primaryTextTheme, scheme),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.22),
        selectionHandleColor: AppColors.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onWarm,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.onWarm,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
          side: BorderSide(
            color: scheme.stroke.withValues(alpha: isDark ? 0.14 : 0.12),
            width: AppDecorations.outlineWidth,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onWarm,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
          side: BorderSide(
            color: scheme.stroke.withValues(alpha: isDark ? 0.18 : 0.15),
            width: AppDecorations.outlineWidth,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onWarm,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
            side: BorderSide(
              color: scheme.stroke.withValues(alpha: isDark ? 0.16 : 0.12),
              width: AppDecorations.outlineWidth,
            ),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: scheme.stroke.withValues(alpha: isDark ? 0.24 : 0.2),
            width: AppDecorations.outlineWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.card,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
          borderSide: BorderSide(
            color: scheme.stroke.withValues(alpha: isDark ? 0.18 : 0.14),
            width: AppDecorations.outlineWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
          borderSide: BorderSide(
            color: scheme.stroke.withValues(alpha: isDark ? 0.18 : 0.14),
            width: AppDecorations.outlineWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.textMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? scheme.surface : scheme.stroke,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? scheme.textPrimary : AppColors.onWarm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.stroke.withValues(alpha: isDark ? 0.14 : 0.1),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryLight,
        labelStyle: textTheme.labelMedium,
        side: BorderSide(
          color: scheme.stroke.withValues(alpha: isDark ? 0.16 : 0.12),
          width: AppDecorations.outlineWidth,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
