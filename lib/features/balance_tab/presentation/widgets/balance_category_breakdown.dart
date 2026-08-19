import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class BalanceCategoryBreakdown extends StatelessWidget {
  final String title;
  final Map<String, double> totals;
  final Color accentColor;
  final Color accentLight;
  final Color? accentDark;
  final String? selectedKey;
  final ValueChanged<String> onSelected;
  final String Function(AppLocalizations l10n, String key) localizeKey;
  /// When true, negative totals use [AppColors.expense] for the amount text.
  final bool signedAmountStyle;

  const BalanceCategoryBreakdown({
    super.key,
    required this.title,
    required this.totals,
    required this.accentColor,
    required this.accentLight,
    this.accentDark,
    required this.selectedKey,
    required this.onSelected,
    required this.localizeKey,
    this.signedAmountStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (totals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 10),
        ...totals.entries.map((entry) {
          final label = localizeKey(l10n, entry.key);
          final isSelected = selectedKey == entry.key;
          final amountColor = signedAmountStyle && entry.value < 0
              ? AppColors.expense
              : accentColor;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(entry.key),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: AppDecorations.card(
                  borderColor: isSelected
                      ? accentColor
                      : accentColor.withValues(alpha: 0.12),
                ).copyWith(
                  color: isSelected ? accentLight : null,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.15)
                            : accentLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.filter_alt_rounded
                            : Icons.pie_chart_outline_rounded,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? (accentDark ?? accentColor)
                              : AppColors.textColor,
                        ),
                      ),
                    ),
                    Text(
                      Money.format(entry.value),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
