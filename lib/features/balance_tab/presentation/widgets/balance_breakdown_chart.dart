import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class BalanceBreakdownChart extends StatelessWidget {
  final double income;
  final double expenses;

  const BalanceBreakdownChart({
    super.key,
    required this.income,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = income + expenses;
    final incomeRatio = total > 0 ? income / total : 0.5;
    final expenseRatio = total > 0 ? expenses / total : 0.5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.balanceIncomeVsExpenses,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (incomeRatio > 0)
                    Expanded(
                      flex: (incomeRatio * 100).round().clamp(1, 100),
                      child: Container(color: AppColors.income),
                    ),
                  if (expenseRatio > 0)
                    Expanded(
                      flex: (expenseRatio * 100).round().clamp(1, 100),
                      child: Container(color: AppColors.expense),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _LegendDot(
                color: AppColors.income,
                label: l10n.balanceStatIncome,
                value: income,
              ),
              const SizedBox(width: 24),
              _LegendDot(
                color: AppColors.expense,
                label: l10n.balanceStatExpense,
                value: expenses,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final double value;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textColor.withValues(alpha: 0.55),
              ),
            ),
            Text(
              Money.format(value),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

}
