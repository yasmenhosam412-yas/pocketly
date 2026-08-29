import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/color_contrast.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';

enum BalanceActivityFilter { all, income, expense }

class BalanceActivityFilterBar extends StatelessWidget {
  final BalanceActivityFilter selected;
  final ValueChanged<BalanceActivityFilter> onTypeChanged;

  const BalanceActivityFilterBar({
    super.key,
    required this.selected,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<BalanceActivityFilter>(
      segments: [
        ButtonSegment(
          value: BalanceActivityFilter.all,
          label: Text(l10n.balanceFilterAll),
          icon: const Icon(Icons.list_rounded, size: 18),
        ),
        ButtonSegment(
          value: BalanceActivityFilter.income,
          label: Text(l10n.balanceFilterIncome),
          icon: const Icon(Icons.south_west_rounded, size: 18),
        ),
        ButtonSegment(
          value: BalanceActivityFilter.expense,
          label: Text(l10n.balanceFilterExpense),
          icon: const Icon(Icons.north_east_rounded, size: 18),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (value) => onTypeChanged(value.first),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorContrast.onColor(AppColors.balance);
          }
          return AppColors.textColor;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.balance;
          }
          return AppColors.surface;
        }),
      ),
    );
  }
}

class BalanceCategoryFilterChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Color accentColor;
  final String allLabel;
  final ValueChanged<String?> onSelected;
  final String Function(AppLocalizations l10n, String key) localizeKey;

  const BalanceCategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.accentColor,
    required this.allLabel,
    required this.onSelected,
    required this.localizeKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (categories.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: Text(allLabel),
            selected: selectedCategory == null,
            onSelected: (_) => onSelected(null),
            selectedColor: accentColor,
            checkmarkColor: ColorContrast.onColor(accentColor),
            labelStyle: TextStyle(
              color: selectedCategory == null
                  ? ColorContrast.onColor(accentColor)
                  : AppColors.textColor,
              fontWeight: FontWeight.w500,
            ),
            backgroundColor: AppColors.surface,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 8),
          ...categories.map((category) {
            final selected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(localizeKey(l10n, category)),
                selected: selected,
                onSelected: (_) => onSelected(category),
                selectedColor: accentColor,
                checkmarkColor: ColorContrast.onColor(accentColor),
                labelStyle: TextStyle(
                  color: selected
                      ? ColorContrast.onColor(accentColor)
                      : AppColors.textColor,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
