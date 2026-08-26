import 'package:flutter/material.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/theme_preferences.dart';
import 'package:imrpo/core/utils/app_colors.dart';

/// Header colors that adapt between the selected appearance gradient and dark mode.
class HomeHeaderTheme {
  const HomeHeaderTheme._({
    required this.isDark,
    required this.gradientColors,
    required this.gradientBegin,
    required this.gradientEnd,
    required this.foreground,
    required this.foregroundMuted,
    required this.foregroundSubtle,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.shadow,
    required this.chipFill,
    required this.chipFillHighlighted,
    required this.chipBorder,
    required this.chipBorderHighlighted,
    required this.decorSoft,
  });

  final bool isDark;
  final List<Color> gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final Color foreground;
  final Color foregroundMuted;
  final Color foregroundSubtle;
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassBorder;
  final Color shadow;
  final Color chipFill;
  final Color chipFillHighlighted;
  final Color chipBorder;
  final Color chipBorderHighlighted;
  final Color decorSoft;

  factory HomeHeaderTheme.resolve(BuildContext context, Color tabAccent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.appPalette;
    final gradient = getIt<ThemePreferences>().headerGradient(accent: tabAccent);

    if (!isDark) {
      return HomeHeaderTheme._(
        isDark: false,
        gradientColors: gradient.colors,
        gradientBegin: gradient.begin,
        gradientEnd: gradient.end,
        foreground: Colors.white,
        foregroundMuted: Colors.white.withValues(alpha: 0.88),
        foregroundSubtle: Colors.white.withValues(alpha: 0.72),
        glassFill: Colors.white.withValues(alpha: 0.14),
        glassFillStrong: Colors.white.withValues(alpha: 0.2),
        glassBorder: Colors.white.withValues(alpha: 0.3),
        shadow: Colors.black.withValues(alpha: 0.1),
        chipFill: Colors.white.withValues(alpha: 0.16),
        chipFillHighlighted: Colors.white.withValues(alpha: 0.28),
        chipBorder: Colors.white.withValues(alpha: 0.12),
        chipBorderHighlighted: Colors.white.withValues(alpha: 0.45),
        decorSoft: Colors.white.withValues(alpha: 0.08),
      );
    }

    return HomeHeaderTheme._(
      isDark: true,
      gradientColors: gradient.colors,
      gradientBegin: gradient.begin,
      gradientEnd: gradient.end,
      foreground: palette.textPrimary,
      foregroundMuted: palette.textSecondary,
      foregroundSubtle: palette.textMuted,
      glassFill: palette.surface.withValues(alpha: 0.72),
      glassFillStrong: palette.card.withValues(alpha: 0.9),
      glassBorder: palette.border,
      shadow: Colors.black.withValues(alpha: 0.35),
      chipFill: palette.card.withValues(alpha: 0.55),
      chipFillHighlighted: palette.surface,
      chipBorder: palette.border.withValues(alpha: 0.7),
      chipBorderHighlighted: AppColors.primary.withValues(alpha: 0.45),
      decorSoft: AppColors.primary.withValues(alpha: 0.1),
    );
  }
}

class HomeHeaderScope extends InheritedWidget {
  const HomeHeaderScope({
    super.key,
    required this.theme,
    required super.child,
  });

  final HomeHeaderTheme theme;

  static HomeHeaderTheme of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HomeHeaderScope>();
    assert(scope != null, 'HomeHeaderScope not found');
    return scope!.theme;
  }

  @override
  bool updateShouldNotify(HomeHeaderScope oldWidget) =>
      theme != oldWidget.theme;
}
