import 'package:flutter/material.dart';
import 'package:imrpo/core/utils/app_colors.dart';

/// Header colors that adapt between the warm light gradient and a dark home hero.
class HomeHeaderTheme {
  const HomeHeaderTheme._({
    required this.isDark,
    required this.gradientColors,
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

    if (!isDark) {
      return HomeHeaderTheme._(
        isDark: false,
        gradientColors: [
          AppColors.primary,
          Color.lerp(AppColors.primary, AppColors.secondary, 0.55)!,
          Color.lerp(AppColors.secondary, tabAccent, 0.4)!,
        ],
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
      gradientColors: [
        const Color(0xFF14100E),
        const Color(0xFF221A17),
        Color.lerp(const Color(0xFF2B211D), tabAccent, 0.38)!,
      ],
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
