import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/monthly_report/domain/entities/monthly_report_snapshot.dart';
import 'package:imrpo/features/monthly_report/domain/services/monthly_report_calculator.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class ReportComparisonCard extends StatelessWidget {
  final MonthlyReportSnapshot snapshot;

  const ReportComparisonCard({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(
        borderColor: AppColors.balance.withValues(alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.monthlyReportVsLastMonth,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          _ComparisonRow(
            label: l10n.balanceStatIncome,
            change: snapshot.incomeChange,
            percentLabel: MonthlyReportCalculator.formatPercentChange(
              snapshot.income,
              snapshot.previousIncome,
            ),
            positiveIsGood: true,
          ),
          const SizedBox(height: 12),
          _ComparisonRow(
            label: l10n.balanceStatExpense,
            change: snapshot.expensesChange,
            percentLabel: MonthlyReportCalculator.formatPercentChange(
              snapshot.expenses,
              snapshot.previousExpenses,
            ),
            positiveIsGood: false,
          ),
          Divider(height: 28),
          _ComparisonRow(
            label: l10n.balanceNetBalance,
            change: snapshot.netChange,
            percentLabel: MonthlyReportCalculator.formatPercentChange(
              snapshot.net,
              snapshot.previousNet,
            ),
            positiveIsGood: true,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final double change;
  final String percentLabel;
  final bool positiveIsGood;
  final bool emphasized;

  const _ComparisonRow({
    required this.label,
    required this.change,
    required this.percentLabel,
    required this.positiveIsGood,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final isGood = positiveIsGood ? isPositive : !isPositive;
    final color = change == 0
        ? AppColors.textColor.withValues(alpha: 0.5)
        : isGood
            ? AppColors.income
            : AppColors.expense;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasized ? 15 : 14,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${change >= 0 ? '+' : '-'}${Money.format(change.abs())}',
              style: TextStyle(
                fontSize: emphasized ? 16 : 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              percentLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
