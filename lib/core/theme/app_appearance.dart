import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/color_contrast.dart';

class AppAccentPalette {
  const AppAccentPalette({
    required this.id,
    required this.primary,
    required this.secondary,
    required this.primaryLight,
    required this.primaryDark,
  });

  final String id;
  final Color primary;
  final Color secondary;
  final Color primaryLight;
  final Color primaryDark;

  static const coral = AppAccentPalette(
    id: 'coral',
    primary: Color(0xFFF28C74),
    secondary: Color(0xFFF6A060),
    primaryLight: Color(0xFFF9A890),
    primaryDark: Color(0xFFE07862),
  );

  static const ocean = AppAccentPalette(
    id: 'ocean',
    primary: Color(0xFF2F8F9D),
    secondary: Color(0xFF4EC4C8),
    primaryLight: Color(0xFF7ED4D6),
    primaryDark: Color(0xFF1F6F7A),
  );

  static const forest = AppAccentPalette(
    id: 'forest',
    primary: Color(0xFF4C9A6E),
    secondary: Color(0xFF88C9A1),
    primaryLight: Color(0xFFB5DEC4),
    primaryDark: Color(0xFF357554),
  );

  static const sunset = AppAccentPalette(
    id: 'sunset',
    primary: Color(0xFFE07A4A),
    secondary: Color(0xFFF3B06A),
    primaryLight: Color(0xFFF7C99A),
    primaryDark: Color(0xFFC45F32),
  );

  static const grape = AppAccentPalette(
    id: 'grape',
    primary: Color(0xFF7B6BB0),
    secondary: Color(0xFFB39DDB),
    primaryLight: Color(0xFFD1C4E9),
    primaryDark: Color(0xFF5E4E96),
  );

  static const rose = AppAccentPalette(
    id: 'rose',
    primary: Color(0xFFD46A8A),
    secondary: Color(0xFFE9A0B4),
    primaryLight: Color(0xFFF3C5D1),
    primaryDark: Color(0xFFB44E6C),
  );

  static const slate = AppAccentPalette(
    id: 'slate',
    primary: Color(0xFF5C6B7A),
    secondary: Color(0xFF8AA0B3),
    primaryLight: Color(0xFFB7C6D3),
    primaryDark: Color(0xFF3E4C59),
  );

  static const presets = [
    coral,
    ocean,
    forest,
    sunset,
    grape,
    rose,
    slate,
  ];

  static const customId = 'custom';

  static AppAccentPalette customFrom(Color primary, Color secondary) {
    final light = ColorContrast.isLight(primary);
    return AppAccentPalette(
      id: customId,
      primary: primary,
      secondary: secondary,
      primaryLight: Color.lerp(
        primary,
        light ? Colors.black : Colors.white,
        light ? 0.08 : 0.28,
      )!,
      primaryDark: Color.lerp(primary, Colors.black, light ? 0.28 : 0.22)!,
    );
  }

  static AppAccentPalette byId(String id) {
    for (final palette in presets) {
      if (palette.id == id) return palette;
    }
    return coral;
  }

  AppAccentPalette copyWith({
    Color? primary,
    Color? secondary,
    Color? primaryLight,
    Color? primaryDark,
  }) {
    return AppAccentPalette(
      id: id,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
    );
  }
}

enum AppGradientStyleId {
  diagonal,
  sunset,
  aurora,
  wave,
  soft,
  custom,
}

class ResolvedAppGradient {
  const ResolvedAppGradient({
    required this.colors,
    required this.begin,
    required this.end,
  });

  final List<Color> colors;
  final Alignment begin;
  final Alignment end;

  LinearGradient toLinearGradient() => LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      );
}

class AppGradientStyles {
  AppGradientStyles._();

  static const customSwatches = <Color>[
    Color(0xFFF28C74),
    Color(0xFFF6A060),
    Color(0xFFF7C14D),
    Color(0xFF7EB87A),
    Color(0xFF2F8F9D),
    Color(0xFF4EC4C8),
    Color(0xFF4C9A6E),
    Color(0xFF7B6BB0),
    Color(0xFFB39DDB),
    Color(0xFFD46A8A),
    Color(0xFFE07A6A),
    Color(0xFF5C6B7A),
    Color(0xFF3A322E),
    Color(0xFFE8DED6),
    Color(0xFF1A1614),
    Color(0xFFFFFFFF),
  ];

  static AppGradientStyleId parseId(String? raw) {
    for (final id in AppGradientStyleId.values) {
      if (id.name == raw) return id;
    }
    return AppGradientStyleId.diagonal;
  }

  static ResolvedAppGradient resolve({
    required AppGradientStyleId id,
    required Color primary,
    required Color secondary,
    Color? accent,
    List<Color>? customStops,
    bool isDark = false,
  }) {
    final third = accent ?? secondary;
    switch (id) {
      case AppGradientStyleId.diagonal:
        return ResolvedAppGradient(
          colors: _darkenIfNeeded(isDark, [
            primary,
            Color.lerp(primary, secondary, 0.55)!,
            Color.lerp(secondary, third, 0.4)!,
          ]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppGradientStyleId.sunset:
        return ResolvedAppGradient(
          colors: _darkenIfNeeded(isDark, [
            primary,
            const Color(0xFFF0A060),
            const Color(0xFFF7C14D),
          ]),
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        );
      case AppGradientStyleId.aurora:
        return ResolvedAppGradient(
          colors: _darkenIfNeeded(isDark, [
            primary,
            Color.lerp(primary, const Color(0xFF7B6BB0), 0.55)!,
            Color.lerp(secondary, const Color(0xFF3DB8C5), 0.5)!,
            third,
          ]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppGradientStyleId.wave:
        return ResolvedAppGradient(
          colors: _darkenIfNeeded(isDark, [
            primary,
            secondary,
            Color.lerp(primary, secondary, 0.2)!,
          ]),
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case AppGradientStyleId.soft:
        return ResolvedAppGradient(
          colors: _darkenIfNeeded(isDark, [
            Color.lerp(primary, Colors.white, isDark ? 0.06 : 0.22)!,
            primary,
            secondary,
          ]),
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case AppGradientStyleId.custom:
        final stops = (customStops == null || customStops.length < 2)
            ? [primary, secondary]
            : customStops;
        return ResolvedAppGradient(
          colors: _darkenIfNeeded(isDark, stops),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  static List<Color> _darkenIfNeeded(bool isDark, List<Color> colors) {
    if (!isDark) return colors;
    return colors
        .map((c) => Color.lerp(const Color(0xFF1A1614), c, 0.48)!)
        .toList();
  }
}
