import 'package:flutter/material.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/theme_preferences.dart';
import 'package:imrpo/core/theme/color_contrast.dart';
import 'package:imrpo/core/utils/app_colors.dart';

/// Auth hero header colors — selected appearance gradient in light, tinted dark in dark mode.
class AuthHeaderTheme {
  const AuthHeaderTheme._({
    required this.gradientColors,
    required this.gradientBegin,
    required this.gradientEnd,
    required this.foreground,
    required this.foregroundMuted,
    required this.glassFill,
    required this.glassBorder,
    required this.iconGlassFill,
    required this.shadow,
  });

  final List<Color> gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final Color foreground;
  final Color foregroundMuted;
  final Color glassFill;
  final Color glassBorder;
  final Color iconGlassFill;
  final Color shadow;

  factory AuthHeaderTheme.resolve(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.appPalette;
    final gradient = getIt<ThemePreferences>().headerGradient();
    final lightBg = ColorContrast.isLightAverage(gradient.colors);
    final on = OnSurfaceColors.fromColors(
      gradient.colors,
      isDark: isDark,
      palette: palette,
    );

    if (!isDark || lightBg) {
      return AuthHeaderTheme._(
        gradientColors: gradient.colors,
        gradientBegin: gradient.begin,
        gradientEnd: gradient.end,
        foreground: on.foreground,
        foregroundMuted: on.muted,
        glassFill: on.overlay,
        glassBorder: on.border,
        iconGlassFill: on.overlayStrong,
        shadow: AppColors.stroke.withValues(alpha: lightBg ? 0.08 : 0.12),
      );
    }

    return AuthHeaderTheme._(
      gradientColors: gradient.colors,
      gradientBegin: gradient.begin,
      gradientEnd: gradient.end,
      foreground: palette.textPrimary,
      foregroundMuted: palette.textSecondary,
      glassFill: palette.surface.withValues(alpha: 0.72),
      glassBorder: palette.border,
      iconGlassFill: palette.card.withValues(alpha: 0.85),
      shadow: Colors.black.withValues(alpha: 0.35),
    );
  }
}
