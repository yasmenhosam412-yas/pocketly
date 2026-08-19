import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/budgets/domain/services/budget_calculator.dart';
import 'package:imrpo/features/balance_tab/domain/entities/balance_activity.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class BalanceActivityTile extends StatelessWidget {
  final BalanceActivity activity;

  const BalanceActivityTile({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome = activity.type == BalanceActivityType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final categoryLabel = isIncome
        ? localizeIncomeCategory(l10n, activity.category)
        : localizeExpenseCategory(l10n, activity.category);
    final title = localizeDemoTitle(l10n, activity.title);
    final paidFromRaw = activity.incomeSource?.trim();
    final paidFromLabel = !isIncome &&
            paidFromRaw != null &&
            paidFromRaw.isNotEmpty
        ? localizeIncomeCategory(
            l10n,
            BudgetCalculator.categoryKey(paidFromRaw),
          )
        : null;
    final showTitleSubtitle =
        title.trim().toLowerCase() != categoryLabel.trim().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitleLine(
                    context,
                    l10n,
                    isIncome: isIncome,
                    title: title,
                    showTitleSubtitle: showTitleSubtitle,
                    paidFromLabel: paidFromLabel,
                    date: activity.date,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textColor.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${Money.format(activity.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.MMMd(locale).format(date);
  }

  String _subtitleLine(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isIncome,
    required String title,
    required bool showTitleSubtitle,
    required String? paidFromLabel,
    required DateTime date,
  }) {
    final parts = <String>[];
    if (showTitleSubtitle) {
      parts.add(title);
    }
    if (paidFromLabel != null) {
      parts.add('${l10n.expensePaidFromField}: $paidFromLabel');
    }
    final dateStr = _formatDate(context, date);
    if (parts.isEmpty) {
      return '${isIncome ? l10n.activityIncome : l10n.activityExpense} · $dateStr';
    }
    parts.add(dateStr);
    return parts.join(' · ');
  }
}
