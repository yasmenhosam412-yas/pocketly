import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/app_appearance.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences extends ChangeNotifier {
  static const _storageKey = 'app_theme_mode';
  static const _paletteKey = 'app_accent_palette';
  static const _gradientKey = 'app_gradient_style';
  static const _customPrimaryKey = 'app_custom_primary';
  static const _customSecondaryKey = 'app_custom_secondary';
  static const _customGrad1Key = 'app_custom_grad_1';
  static const _customGrad2Key = 'app_custom_grad_2';
  static const _customGrad3Key = 'app_custom_grad_3';

  ThemeMode _themeMode = ThemeMode.system;
  Brightness _platformBrightness = Brightness.light;
  String _paletteId = AppAccentPalette.coral.id;
  AppGradientStyleId _gradientStyleId = AppGradientStyleId.diagonal;
  Color _customPrimary = AppAccentPalette.coral.primary;
  Color _customSecondary = AppAccentPalette.coral.secondary;
  Color _customGrad1 = AppAccentPalette.coral.primary;
  Color _customGrad2 = AppAccentPalette.coral.secondary;
  Color _customGrad3 = const Color(0xFFF7C14D);
  bool _isSaving = false;

  ThemeMode get themeMode => _themeMode;
  bool get isSaving => _isSaving;
  String get paletteId => _paletteId;
  AppGradientStyleId get gradientStyleId => _gradientStyleId;
  Color get customPrimary => _customPrimary;
  Color get customSecondary => _customSecondary;
  List<Color> get customGradientStops => [
        _customGrad1,
        _customGrad2,
        _customGrad3,
      ];

  bool get isCustomPalette => _paletteId == AppAccentPalette.customId;

  bool get isDark => switch (_themeMode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system => _platformBrightness == Brightness.dark,
      };

  AppAccentPalette get activePalette {
    if (isCustomPalette) {
      return AppAccentPalette(
        id: AppAccentPalette.customId,
        primary: _customPrimary,
        secondary: _customSecondary,
        primaryLight: Color.lerp(_customPrimary, Colors.white, 0.28)!,
        primaryDark: Color.lerp(_customPrimary, Colors.black, 0.22)!,
      );
    }
    return AppAccentPalette.byId(_paletteId);
  }

  ResolvedAppGradient headerGradient({Color? accent}) {
    final palette = activePalette;
    return AppGradientStyles.resolve(
      id: _gradientStyleId,
      primary: palette.primary,
      secondary: palette.secondary,
      accent: accent,
      customStops: customGradientStops,
      isDark: isDark,
    );
  }

  void _syncPalette() {
    AppColors.applyDarkMode(isDark);
    AppColors.applyPalette(activePalette);
  }

  void updatePlatformBrightness(Brightness brightness) {
    if (_platformBrightness == brightness) return;
    _platformBrightness = brightness;
    _syncPalette();
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null) {
      final mode = _parseMode(saved);
      if (mode != null) {
        _themeMode = mode;
      }
    }
    _paletteId = prefs.getString(_paletteKey) ?? AppAccentPalette.coral.id;
    _gradientStyleId = AppGradientStyles.parseId(prefs.getString(_gradientKey));
    _customPrimary = _colorFromPrefs(
          prefs,
          _customPrimaryKey,
        ) ??
        AppAccentPalette.coral.primary;
    _customSecondary = _colorFromPrefs(
          prefs,
          _customSecondaryKey,
        ) ??
        AppAccentPalette.coral.secondary;
    _customGrad1 = _colorFromPrefs(prefs, _customGrad1Key) ?? _customPrimary;
    _customGrad2 = _colorFromPrefs(prefs, _customGrad2Key) ?? _customSecondary;
    _customGrad3 =
        _colorFromPrefs(prefs, _customGrad3Key) ?? const Color(0xFFF7C14D);
    _syncPalette();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode || _isSaving) return;

    _isSaving = true;
    notifyListeners();

    try {
      _themeMode = mode;
      _syncPalette();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _modeToString(mode));
    } finally {
      _isSaving = false;
      _syncPalette();
      notifyListeners();
    }
  }

  Future<void> setPaletteId(String id) async {
    if (_paletteId == id) return;
    _paletteId = id;
    _syncPalette();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, id);
  }

  Future<void> setGradientStyle(AppGradientStyleId id) async {
    if (_gradientStyleId == id) return;
    _gradientStyleId = id;
    _syncPalette();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gradientKey, id.name);
  }

  Future<void> setCustomPaletteColors({
    Color? primary,
    Color? secondary,
  }) async {
    if (primary != null) _customPrimary = primary;
    if (secondary != null) _customSecondary = secondary;
    _paletteId = AppAccentPalette.customId;
    _syncPalette();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, AppAccentPalette.customId);
    await prefs.setInt(_customPrimaryKey, _customPrimary.toARGB32());
    await prefs.setInt(_customSecondaryKey, _customSecondary.toARGB32());
  }

  Future<void> setCustomGradientStop(int index, Color color) async {
    if (index <= 0) {
      _customGrad1 = color;
    } else if (index == 1) {
      _customGrad2 = color;
    } else {
      _customGrad3 = color;
    }
    _gradientStyleId = AppGradientStyleId.custom;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gradientKey, AppGradientStyleId.custom.name);
    await prefs.setInt(_customGrad1Key, _customGrad1.toARGB32());
    await prefs.setInt(_customGrad2Key, _customGrad2.toARGB32());
    await prefs.setInt(_customGrad3Key, _customGrad3.toARGB32());
  }

  static String modeLabel(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }

  static String paletteLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'ocean' => l10n.appearancePaletteOcean,
      'forest' => l10n.appearancePaletteForest,
      'sunset' => l10n.appearancePaletteSunset,
      'grape' => l10n.appearancePaletteGrape,
      'rose' => l10n.appearancePaletteRose,
      'slate' => l10n.appearancePaletteSlate,
      'custom' => l10n.appearanceCustom,
      _ => l10n.appearancePaletteCoral,
    };
  }

  static String gradientLabel(AppLocalizations l10n, AppGradientStyleId id) {
    return switch (id) {
      AppGradientStyleId.diagonal => l10n.appearanceGradientDiagonal,
      AppGradientStyleId.sunset => l10n.appearanceGradientSunset,
      AppGradientStyleId.aurora => l10n.appearanceGradientAurora,
      AppGradientStyleId.wave => l10n.appearanceGradientWave,
      AppGradientStyleId.soft => l10n.appearanceGradientSoft,
      AppGradientStyleId.custom => l10n.appearanceCustom,
    };
  }

  String appearanceSummary(AppLocalizations l10n) {
    return '${modeLabel(l10n, _themeMode)} · ${paletteLabel(l10n, _paletteId)}';
  }

  String _modeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  ThemeMode? _parseMode(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => null,
      };

  static Color? _colorFromPrefs(SharedPreferences prefs, String key) {
    final value = prefs.getInt(key);
    if (value == null) return null;
    return Color(value);
  }
}
