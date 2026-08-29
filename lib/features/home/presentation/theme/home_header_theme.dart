import 'package:flutter/material.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/theme_preferences.dart';
import 'package:imrpo/core/theme/color_contrast.dart';
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
    final lightBg = ColorContrast.isLightAverage(gradient.colors);
    final on = OnSurfaceColors.fromColors(
      gradient.colors,
      isDark: isDark,
      palette: palette,
    );

    if (!isDark || lightBg) {
      return HomeHeaderTheme._(
        isDark: isDark,
        gradientColors: gradient.colors,
        gradientBegin: gradient.begin,
        gradientEnd: gradient.end,
        foreground: on.foreground,
        foregroundMuted: on.muted,
        foregroundSubtle: on.subtle,
        glassFill: on.overlay,
        glassFillStrong: on.overlayStrong,
        glassBorder: on.border,
        shadow: Colors.black.withValues(alpha: lightBg ? 0.08 : 0.1),
        chipFill: on.overlay,
        chipFillHighlighted: on.overlayStrong,
        chipBorder: on.foreground.withValues(alpha: 0.12),
        chipBorderHighlighted: on.foreground.withValues(alpha: 0.45),
        decorSoft: on.foreground.withValues(alpha: 0.08),
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
        chipBorderHighlighted: AppColors.primaryInk.withValues(alpha: 0.45),
        decorSoft: AppColors.primaryInk.withValues(alpha: 0.1),
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

  static HomeHeaderTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeHeaderScope>()?.theme;
  }

  @override
  bool updateShouldNotify(HomeHeaderScope oldWidget) =>
      theme != oldWidget.theme;
}
