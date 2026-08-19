import 'package:flutter/material.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences extends ChangeNotifier {
  static const _storageKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  Brightness _platformBrightness = Brightness.light;
  bool _isSaving = false;

  ThemeMode get themeMode => _themeMode;
  bool get isSaving => _isSaving;

  bool get isDark => switch (_themeMode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system => _platformBrightness == Brightness.dark,
      };

  void _syncPalette() {
    AppColors.applyDarkMode(isDark);
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
}
