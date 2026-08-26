import 'package:flutter/material.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/theme_preferences.dart';
import 'package:imrpo/core/theme/app_appearance.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/show_app_bottom_sheet.dart';
import 'package:imrpo/l10n/app_localizations.dart';

Future<void> showAppearanceSettingsSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _AppearanceSettingsSheet(),
  );
}

class _AppearanceSettingsSheet extends StatelessWidget {
  const _AppearanceSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = getIt<ThemePreferences>();
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.stroke.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.settingsTheme,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.72,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ThemeModeRow(prefs: prefs, l10n: l10n),
                      const SizedBox(height: 22),
                      _SectionLabel(l10n.appearanceColors),
                      const SizedBox(height: 12),
                      _PaletteGrid(prefs: prefs, l10n: l10n),
                      if (prefs.isCustomPalette) ...[
                        const SizedBox(height: 12),
                        _CustomColorRow(
                          label: l10n.appearanceCustomPrimary,
                          color: prefs.customPrimary,
                          onPick: (c) => prefs.setCustomPaletteColors(primary: c),
                        ),
                        const SizedBox(height: 8),
                        _CustomColorRow(
                          label: l10n.appearanceCustomSecondary,
                          color: prefs.customSecondary,
                          onPick: (c) =>
                              prefs.setCustomPaletteColors(secondary: c),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _SectionLabel(l10n.appearanceGradients),
                      const SizedBox(height: 12),
                      _GradientGrid(prefs: prefs, l10n: l10n),
                      if (prefs.gradientStyleId == AppGradientStyleId.custom) ...[
                        const SizedBox(height: 12),
                        _SectionLabel(l10n.appearanceGradientStops),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (var i = 0; i < 3; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: _GradientStopWell(
                                  color: prefs.customGradientStops[i],
                                  onPick: (c) =>
                                      prefs.setCustomGradientStop(i, c),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textColor.withValues(alpha: 0.55),
      ),
    );
  }
}

class _ThemeModeRow extends StatelessWidget {
  final ThemePreferences prefs;
  final AppLocalizations l10n;

  const _ThemeModeRow({required this.prefs, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ModeChip(
          icon: Icons.light_mode_outlined,
          label: l10n.themeLight,
          selected: prefs.themeMode == ThemeMode.light,
          onTap: () => prefs.setThemeMode(ThemeMode.light),
        ),
        const SizedBox(width: 8),
        _ModeChip(
          icon: Icons.dark_mode_outlined,
          label: l10n.themeDark,
          selected: prefs.themeMode == ThemeMode.dark,
          onTap: () => prefs.setThemeMode(ThemeMode.dark),
        ),
        const SizedBox(width: 8),
        _ModeChip(
          icon: Icons.brightness_auto_outlined,
          label: l10n.themeSystem,
          selected: prefs.themeMode == ThemeMode.system,
          onTap: () => prefs.setThemeMode(ThemeMode.system),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.55)
                    : AppColors.stroke.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteGrid extends StatelessWidget {
  final ThemePreferences prefs;
  final AppLocalizations l10n;

  const _PaletteGrid({required this.prefs, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final items = [
      ...AppAccentPalette.presets,
      AppAccentPalette(
        id: AppAccentPalette.customId,
        primary: prefs.customPrimary,
        secondary: prefs.customSecondary,
        primaryLight: Color.lerp(prefs.customPrimary, Colors.white, 0.28)!,
        primaryDark: Color.lerp(prefs.customPrimary, Colors.black, 0.22)!,
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final palette in items)
          _PaletteDot(
            palette: palette,
            label: ThemePreferences.paletteLabel(l10n, palette.id),
            selected: prefs.paletteId == palette.id,
            onTap: () => prefs.setPaletteId(palette.id),
          ),
      ],
    );
  }
}

class _PaletteDot extends StatelessWidget {
  final AppAccentPalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteDot({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [palette.primary, palette.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: selected ? AppColors.textColor : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.28),
                      blurRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                    : palette.id == AppAccentPalette.customId
                        ? const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: AppColors.textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientGrid extends StatelessWidget {
  final ThemePreferences prefs;
  final AppLocalizations l10n;

  const _GradientGrid({required this.prefs, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final palette = prefs.activePalette;
    return Column(
      children: [
        for (final id in AppGradientStyleId.values) ...[
          if (id != AppGradientStyleId.values.first) const SizedBox(height: 8),
          _GradientPreviewTile(
            label: ThemePreferences.gradientLabel(l10n, id),
            selected: prefs.gradientStyleId == id,
            gradient: AppGradientStyles.resolve(
              id: id,
              primary: palette.primary,
              secondary: palette.secondary,
              customStops: prefs.customGradientStops,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            onTap: () => prefs.setGradientStyle(id),
          ),
        ],
      ],
    );
  }
}

class _GradientPreviewTile extends StatelessWidget {
  final String label;
  final bool selected;
  final ResolvedAppGradient gradient;
  final VoidCallback onTap;

  const _GradientPreviewTile({
    required this.label,
    required this.selected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.65)
                  : AppColors.stroke.withValues(alpha: 0.12),
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: gradient.toLinearGradient(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onPick;

  const _CustomColorRow({
    required this.label,
    required this.color,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pickColor(context, color, onPick),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: AppDecorations.outlined(),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.stroke.withValues(alpha: 0.2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientStopWell extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onPick;

  const _GradientStopWell({required this.color, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pickColor(context, color, onPick),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.stroke.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _pickColor(
  BuildContext context,
  Color current,
  ValueChanged<Color> onPick,
) async {
  final l10n = AppLocalizations.of(context)!;
  final selected = await showDialog<Color>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.appearancePickColor),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in AppGradientStyles.customSwatches)
                GestureDetector(
                  onTap: () => Navigator.pop(dialogContext, color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.toARGB32() == current.toARGB32()
                            ? AppColors.textColor
                            : AppColors.stroke.withValues(alpha: 0.2),
                        width: color.toARGB32() == current.toARGB32() ? 2.5 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
      );
    },
  );
  if (selected != null) onPick(selected);
}
