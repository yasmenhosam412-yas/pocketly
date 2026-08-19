import 'dart:ui';

/// Light and dark surface palettes. Brand accent colors live on [AppColors].
class AppColorScheme {
  const AppColorScheme({
    required this.stroke,
    required this.background,
    required this.scaffold,
    required this.surface,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.incomeLight,
    required this.expenseLight,
    required this.plansLight,
    required this.balanceLight,
    required this.primaryLight,
  });

  final Color stroke;
  final Color background;
  final Color scaffold;
  final Color surface;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color incomeLight;
  final Color expenseLight;
  final Color plansLight;
  final Color balanceLight;
  final Color primaryLight;

  static const light = AppColorScheme(
    stroke: Color(0xFF3A322E),
    background: Color(0xFFFFFDFB),
    scaffold: Color(0xFFF7F3EF),
    surface: Color(0xFFF0EBE6),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE8DED6),
    textPrimary: Color(0xFF3A322E),
    textSecondary: Color(0xFF6B625C),
    textMuted: Color(0xFF9A9089),
    incomeLight: Color(0xFFE8F3E6),
    expenseLight: Color(0xFFFFECE8),
    plansLight: Color(0xFFFFF6DC),
    balanceLight: Color(0xFFFFF0EC),
    primaryLight: Color(0xFFF9A890),
  );

  static const dark = AppColorScheme(
    stroke: Color(0xFFE8DED6),
    background: Color(0xFF141110),
    scaffold: Color(0xFF1A1614),
    surface: Color(0xFF2A2420),
    card: Color(0xFF231F1C),
    border: Color(0xFF3D3530),
    textPrimary: Color(0xFFF5F0EB),
    textSecondary: Color(0xFFB8AFA8),
    textMuted: Color(0xFF8A817A),
    incomeLight: Color(0xFF1E2E1C),
    expenseLight: Color(0xFF2E1F1C),
    plansLight: Color(0xFF2E2818),
    balanceLight: Color(0xFF2E221F),
    primaryLight: Color(0xFF3D2A24),
  );
}
