import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/app_color_scheme.dart';

/// Contrast helpers so custom white / cream accents stay readable.
class ColorContrast {
  ColorContrast._();

  /// High enough that coral and gold still use light ink.
  static const luminanceThreshold = 0.64;

  static const lightForeground = Color(0xFFFFFFFF);
  static const darkForeground = Color(0xFF3A322E);

  static bool isLight(Color color) =>
      color.computeLuminance() > luminanceThreshold;

  static double averageLuminance(Iterable<Color> colors) {
    var sum = 0.0;
    var n = 0;
    for (final c in colors) {
      sum += c.computeLuminance();
      n++;
    }
    return n == 0 ? 0 : sum / n;
  }

  static bool isLightAverage(Iterable<Color> colors) =>
      averageLuminance(colors) > luminanceThreshold;

  static Color onColor(
    Color background, {
    Color? lightOnDark,
    Color? darkOnLight,
  }) {
    return isLight(background)
        ? (darkOnLight ?? darkForeground)
        : (lightOnDark ?? lightForeground);
  }

  static Color asInk(
    Color color, {
    bool onDarkSurface = false,
  }) {
    if (onDarkSurface) {
      return isLight(color) ? color : lightForeground;
    }
    return isLight(color) ? darkForeground : color;
  }

  static Color onColors(
    Iterable<Color> colors, {
    Color? lightOnDark,
    Color? darkOnLight,
  }) {
    return isLightAverage(colors)
        ? (darkOnLight ?? darkForeground)
        : (lightOnDark ?? lightForeground);
  }
}

/// Ink and overlays for text drawn on a gradient or accent fill.
class OnSurfaceColors {
  const OnSurfaceColors({
    required this.foreground,
    required this.muted,
    required this.subtle,
    required this.overlay,
    required this.overlayStrong,
    required this.border,
  });

  final Color foreground;
  final Color muted;
  final Color subtle;
  final Color overlay;
  final Color overlayStrong;
  final Color border;

  static OnSurfaceColors fromColors(
    Iterable<Color> colors, {
    bool isDark = false,
    AppColorScheme? palette,
  }) {
    final lightBg = ColorContrast.isLightAverage(colors);
    final Color fg;
    if (lightBg) {
      fg = isDark
          ? const Color(0xFF1A1614)
          : (palette?.textPrimary ?? ColorContrast.darkForeground);
    } else if (isDark) {
      fg = palette?.textPrimary ?? ColorContrast.lightForeground;
    } else {
      fg = ColorContrast.lightForeground;
    }

    return OnSurfaceColors(
      foreground: fg,
      muted: fg.withValues(alpha: 0.88),
      subtle: fg.withValues(alpha: 0.75),
      overlay: fg.withValues(alpha: 0.14),
      overlayStrong: fg.withValues(alpha: 0.22),
      border: fg.withValues(alpha: 0.30),
    );
  }

  static OnSurfaceColors fromColor(
    Color color, {
    bool isDark = false,
    AppColorScheme? palette,
  }) {
    return fromColors([color], isDark: isDark, palette: palette);
  }
}
