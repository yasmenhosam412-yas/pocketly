import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/app_appearance.dart';
import 'package:imrpo/core/theme/app_color_scheme.dart';

class AppColors {
  AppColors._();

  static Color stroke = AppColorScheme.light.stroke;
  static Color background = AppColorScheme.light.background;
  static Color scaffold = AppColorScheme.light.scaffold;
  static Color surface = AppColorScheme.light.surface;
  static Color card = AppColorScheme.light.card;
  static Color border = AppColorScheme.light.border;
  static Color textPrimary = AppColorScheme.light.textPrimary;
  static Color textSecondary = AppColorScheme.light.textSecondary;
  static Color textMuted = AppColorScheme.light.textMuted;
  static Color incomeLight = AppColorScheme.light.incomeLight;
  static Color expenseLight = AppColorScheme.light.expenseLight;
  static Color plansLight = AppColorScheme.light.plansLight;
  static Color balanceLight = AppColorScheme.light.balanceLight;

  static Color primary = AppAccentPalette.coral.primary;
  static Color primaryLight = AppAccentPalette.coral.primaryLight;
  static Color secondary = AppAccentPalette.coral.secondary;

  static const income = Color(0xFF7EB87A);
  static const incomeDark = Color(0xFF5A9B56);
  static const incomeBill = Color(0xFFA8D1A0);

  static const expense = Color(0xFFE07A6A);
  static const expenseDark = Color(0xFFC96858);

  static Color balance = AppAccentPalette.coral.primary;
  static Color balanceDark = AppAccentPalette.coral.primaryDark;

  static const plans = Color(0xFFF7C14D);
  static const plansDark = Color(0xFFE5A83A);

  static const loans = Color(0xFF5BA8A0);
  static const loansDark = Color(0xFF3D8A82);

  static const success = income;
  static const warning = plans;
  static const error = expense;

  static const onWarm = Color(0xFFFFFFFF);

  static Color get primaryColor => primary;
  static Color get secondaryColor => primaryLight;
  static const accentColor = warning;
  static const errorColor = error;

  static Color get backgroundColor => background;
  static Color get textColor => textPrimary;

  static void applyPalette(AppAccentPalette palette) {
    primary = palette.primary;
    primaryLight = palette.primaryLight;
    secondary = palette.secondary;
    balance = palette.primary;
    balanceDark = palette.primaryDark;
  }

  static void applyScheme(AppColorScheme scheme) {
    stroke = scheme.stroke;
    background = scheme.background;
    scaffold = scheme.scaffold;
    surface = scheme.surface;
    card = scheme.card;
    border = scheme.border;
    textPrimary = scheme.textPrimary;
    textSecondary = scheme.textSecondary;
    textMuted = scheme.textMuted;
    incomeLight = scheme.incomeLight;
    expenseLight = scheme.expenseLight;
    plansLight = scheme.plansLight;
    balanceLight = scheme.balanceLight;
  }

  static void applyDarkMode(bool isDark) {
    applyScheme(isDark ? AppColorScheme.dark : AppColorScheme.light);
  }
}

extension AppColorSchemeContext on BuildContext {
  AppColorScheme get appPalette => Theme.of(this).brightness == Brightness.dark
      ? AppColorScheme.dark
      : AppColorScheme.light;
}
