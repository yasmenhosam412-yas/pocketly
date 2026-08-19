import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/helpers/association_ledger_access.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/budgets/domain/entities/budget_period.dart';
import 'package:imrpo/features/budgets/domain/entities/category_budget_status.dart';
import 'package:imrpo/features/budgets/domain/services/budget_calculator.dart';
import 'package:imrpo/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:imrpo/features/budgets/presentation/widgets/set_budget_sheet.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class BudgetOverviewSection extends StatelessWidget {
  final BudgetPeriod period;
  final List<CategoryBudgetStatus> rows;
  final List<String> suggestedCategories;
  final String periodLabel;
  final bool isLoading;

  const BudgetOverviewSection({
    super.key,
    required this.period,
    required this.rows,
    required this.suggestedCategories,
    required this.periodLabel,
    this.isLoading = false,
  });

  List<CategoryBudgetStatus> get _budgetRows =>
      rows.where((row) => row.limit > 0).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final budgetRows = _budgetRows;
    final canEdit = AssociationLedgerAccess.canEdit;
    final totalLimit = BudgetCalculator.totalLimit(budgetRows);
    final totalSpent = BudgetCalculator.totalSpentWithBudget(budgetRows);
    final overallProgress = totalLimit > 0
        ? (totalSpent / totalLimit).clamp(0.0, 1.5)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(
        borderColor: AppColors.expense.withValues(alpha: 0.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.budgetMonthlyTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      periodLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textColor.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit)
                TextButton.icon(
                  onPressed: isLoading ? null : () => _openSetBudget(context),
                  icon: const Icon(Icons.add_chart_rounded, size: 18),
                  label: Text(l10n.budgetSetAction),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.expense,
                  ),
                ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: 20),
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.expense,
                ),
              ),
            ),
          ] else if (budgetRows.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.budgetEmptyHint,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColor.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            if (canEdit)
              OutlinedButton.icon(
              onPressed: () => _openSetBudget(context),
              icon: const Icon(Icons.savings_outlined),
              label: Text(l10n.budgetSetFirst),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.expense,
                side: BorderSide(color: AppColors.expense),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            _OverallBudgetBar(
              spent: totalSpent,
              limit: totalLimit,
              progress: overallProgress,
            ),
            const SizedBox(height: 16),
            ...budgetRows.map(
              (row) => _CategoryBudgetRow(
                row: row,
                onEdit: canEdit ? () => _openSetBudget(context, row: row) : null,
                onRemove: !canEdit || row.budgetId == null
                    ? null
                    : () => _confirmDelete(context, row),
              ),
            ),
            if (_hasAlerts(budgetRows)) ...[
              const SizedBox(height: 12),
              _BudgetAlertsBanner(rows: budgetRows),
            ],
          ],
        ],
      ),
    );
  }

  bool _hasAlerts(List<CategoryBudgetStatus> budgetRows) {
    return budgetRows.any((row) => row.isOverBudget || row.isNearLimit);
  }

  Future<void> _openSetBudget(
    BuildContext context, {
    CategoryBudgetStatus? row,
  }) async {
    await showSetBudgetSheet(
      context,
      period: period,
      suggestedCategories: suggestedCategories,
      initialRow: row,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CategoryBudgetStatus row,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.budgetDeleteTitle),
        content: Text(
          l10n.budgetDeleteMessage(localizeExpenseCategory(l10n, row.category)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: Text(l10n.budgetDeleteConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted && row.budgetId != null) {
      context.read<BudgetsBloc>().add(DeleteBudgetEvent(row.budgetId!));
    }
  }
}

class _OverallBudgetBar extends StatelessWidget {
  final double spent;
  final double limit;
  final double progress;

  const _OverallBudgetBar({
    required this.spent,
    required this.limit,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = progress > 1
        ? AppColors.errorColor
        : progress >= 0.8
        ? AppColors.warning
        : AppColors.expense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              '${Money.format(spent)} / ${Money.format(limit)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _CategoryBudgetRow extends StatelessWidget {
  final CategoryBudgetStatus row;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const _CategoryBudgetRow({
    required this.row,
    this.onEdit,
    this.onRemove,
  });

  Color _progressColor(double progress, bool isOver) {
    if (isOver) return AppColors.errorColor;
    if (progress >= 0.8) return AppColors.warning;
    return AppColors.expense;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = localizeExpenseCategory(l10n, row.category);
    final progress = row.progress.clamp(0.0, 1.5);
    final color = _progressColor(row.progress, row.isOverBudget);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    Text(
                      '${Money.format(row.spent)} / ${Money.format(row.limit)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (onRemove != null)
                      IconButton(
                        onPressed: onRemove,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textColor.withValues(alpha: 0.35),
                        ),
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.isOverBudget
                      ? l10n.budgetOverBy(Money.format(-row.remaining))
                      : l10n.budgetRemaining(Money.format(row.remaining)),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textColor.withValues(alpha: 0.5),
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

class _BudgetAlertsBanner extends StatelessWidget {
  final List<CategoryBudgetStatus> rows;

  const _BudgetAlertsBanner({required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overCount = rows.where((r) => r.isOverBudget).length;
    final nearCount = rows.where((r) => r.isNearLimit).length;

    String message;
    if (overCount > 0 && nearCount > 0) {
      message = l10n.budgetAlertOverAndNear(overCount, nearCount);
    } else if (overCount > 0) {
      message = l10n.budgetAlertOver(overCount);
    } else {
      message = l10n.budgetAlertNear(nearCount);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
