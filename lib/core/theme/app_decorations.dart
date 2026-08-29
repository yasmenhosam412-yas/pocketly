import 'package:flutter/material.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/theme_preferences.dart';
import 'package:imrpo/core/theme/app_appearance.dart';
import 'package:imrpo/core/utils/app_colors.dart';

/// Flat, outlined decorations matching the wallet illustration style.
class AppDecorations {
  AppDecorations._();

  static const double cardRadius = 20;
  static const double buttonRadius = 16;
  static const double outlineWidth = 1.5;

  static List<BoxShadow> flatShadow({Color? color, Offset offset = const Offset(0, 3)}) =>
      [
        BoxShadow(
          color: (color ?? AppColors.stroke).withValues(alpha: 0.14),
          offset: offset,
          blurRadius: 0,
        ),
      ];

  static BoxDecoration card({Color? borderColor, double radius = cardRadius}) =>
      BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.stroke.withValues(alpha: 0.12),
          width: outlineWidth,
        ),
        boxShadow: flatShadow(),
      );

  static BoxDecoration gradientHeader({
    required Color start,
    required Color end,
    Alignment begin = Alignment.topLeft,
    Alignment endAlign = Alignment.bottomRight,
  }) =>
      BoxDecoration(
        gradient: LinearGradient(
          colors: [start, end],
          begin: begin,
          end: endAlign,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.stroke.withValues(alpha: 0.08),
            width: outlineWidth,
          ),
        ),
        boxShadow: flatShadow(
          color: start,
          offset: const Offset(0, 4),
        ),
      );

  static ResolvedAppGradient? _activeGradient({Color? accent}) {
    try {
      if (!getIt.isRegistered<ThemePreferences>()) return null;
      return getIt<ThemePreferences>().headerGradient(accent: accent);
    } catch (_) {
      return null;
    }
  }

  /// Dashboard cards on tabs use the selected palette and gradient style,
  /// optionally tinted with [accent] (same as the home header).
  static BoxDecoration summaryCard(
    List<Color> colors, {
    Alignment? begin,
    Alignment? end,
    Color? accent,
  }) {
    final tabAccent = accent ?? (colors.isNotEmpty ? colors.first : null);
    final g = _activeGradient(accent: tabAccent);
    final resolved = g?.colors;
    final useColors = (resolved != null && resolved.isNotEmpty)
        ? resolved
        : colors;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: useColors,
        begin: begin ?? g?.begin ?? Alignment.topLeft,
        end: end ?? g?.end ?? Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(
        color: AppColors.stroke.withValues(alpha: 0.1),
        width: outlineWidth,
      ),
      boxShadow: flatShadow(
        color: useColors.isNotEmpty ? useColors.first : AppColors.primary,
        offset: const Offset(0, 4),
      ),
    );
  }

  static BoxDecoration outlined({
    Color? fill,
    Color? border,
    double radius = buttonRadius,
  }) =>
      BoxDecoration(
        color: fill ?? AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: border ?? AppColors.stroke.withValues(alpha: 0.14),
          width: outlineWidth,
        ),
      );
}

/// Listens to appearance changes so keep-alive tabs update their dashboard cards.
class ThemedSummaryCard extends StatelessWidget {
  const ThemedSummaryCard({
    super.key,
    required this.child,
    this.colors = const [],
    this.accent,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final List<Color> colors;
  final Color? accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: getIt<ThemePreferences>(),
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: padding,
          decoration: AppDecorations.summaryCard(
            colors,
            accent: accent,
          ),
          child: child,
        );
      },
    );
  }
}
