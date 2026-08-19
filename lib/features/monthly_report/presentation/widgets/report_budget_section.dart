import 'package:flutter/material.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/budgets/domain/entities/category_budget_status.dart';
import 'package:imrpo/features/budgets/domain/services/budget_calculator.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class ReportBudgetSection extends StatelessWidget {
  final List<CategoryBudgetStatus> rows;

  const ReportBudgetSection({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final budgetRows = rows.where((row) => row.limit > 0).toList();

    if (budgetRows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: AppDecorations.card(
          borderColor: AppColors.expense.withValues(alpha: 0.12),
        ),
        child: Text(
          l10n.monthlyReportNoBudgets,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textColor.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
      );
    }

    final totalLimit = BudgetCalculator.totalLimit(budgetRows);
    final totalSpent = BudgetCalculator.totalSpentWithBudget(budgetRows);
    final progress =
        totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.5) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(
        borderColor: AppColors.expense.withValues(alpha: 0.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.monthlyReportBudgetTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.expenseLight,
              color: progress > 1
                  ? AppColors.errorColor
                  : progress >= 0.8
                      ? AppColors.secondary
                      : AppColors.expense,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.budgetTotalSpent,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textColor.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '${Money.format(totalSpent)} / ${Money.format(totalLimit)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...budgetRows.map((row) => _BudgetRow(row: row)),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final CategoryBudgetStatus row;

  const _BudgetRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = localizeExpenseCategory(l10n, row.category);
    final progress = row.progress.clamp(0.0, 1.0);
    final barColor = row.isOverBudget
        ? AppColors.errorColor
        : row.isNearLimit
            ? AppColors.secondary
            : AppColors.expense;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              Text(
                Money.format(row.spent),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.expense,
                ),
              ),
              Text(
                ' / ${Money.format(row.limit)}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.expenseLight,
              color: barColor,
            ),
          ),
          if (row.isOverBudget) ...[
            const SizedBox(height: 4),
            Text(
              l10n.budgetOverBy(Money.format(row.spent - row.limit)),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.errorColor,
              ),
            ),
          ] else if (row.limit > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.budgetRemaining(Money.format(row.remaining)),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textColor.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
