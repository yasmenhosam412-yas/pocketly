import 'package:flutter/material.dart';
import 'package:imrpo/core/utils/app_colors.dart';

/// Auth hero header colors — warm gradient in light, deep brown in dark.
class AuthHeaderTheme {
  const AuthHeaderTheme._({
    required this.gradientColors,
    required this.foreground,
    required this.foregroundMuted,
    required this.glassFill,
    required this.glassBorder,
    required this.iconGlassFill,
    required this.shadow,
  });

  final List<Color> gradientColors;
  final Color foreground;
  final Color foregroundMuted;
  final Color glassFill;
  final Color glassBorder;
  final Color iconGlassFill;
  final Color shadow;

  factory AuthHeaderTheme.resolve(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.appPalette;

    if (!isDark) {
      return AuthHeaderTheme._(
        gradientColors: [AppColors.primary, AppColors.secondary],
        foreground: Colors.white,
        foregroundMuted: Colors.white.withValues(alpha: 0.88),
        glassFill: Colors.white.withValues(alpha: 0.16),
        glassBorder: Colors.white.withValues(alpha: 0.35),
        iconGlassFill: Colors.white.withValues(alpha: 0.2),
        shadow: AppColors.stroke.withValues(alpha: 0.12),
      );
    }

    return AuthHeaderTheme._(
      gradientColors: [
        const Color(0xFF14100E),
        const Color(0xFF221A17),
        Color.lerp(const Color(0xFF2B211D), AppColors.primary, 0.28)!,
      ],
      foreground: palette.textPrimary,
      foregroundMuted: palette.textSecondary,
      glassFill: palette.surface.withValues(alpha: 0.72),
      glassBorder: palette.border,
      iconGlassFill: palette.card.withValues(alpha: 0.85),
      shadow: Colors.black.withValues(alpha: 0.35),
    );
  }
}
