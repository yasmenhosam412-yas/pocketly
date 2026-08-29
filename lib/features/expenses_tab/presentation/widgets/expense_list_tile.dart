import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/features/expenses_tab/data/models/expense_model.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:intl/intl.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/budgets/domain/services/budget_calculator.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/models/transaction_entry_meta.dart';
import 'package:imrpo/core/utils/transaction_entry_format.dart';
import 'package:imrpo/core/widgets/payment_method_badge.dart';
import 'package:imrpo/features/associations/presentation/widgets/family_author_meta.dart';
import 'package:imrpo/l10n/app_localizations.dart';
class ExpenseListTile extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExpenseListTile({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
  });

  static const _expenseColor = AppColors.expense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final category = localizeExpenseCategory(l10n, expense.category);
    final title = localizeDemoTitle(l10n, expense.title);
    final showTitleSubtitle =
        title.trim().toLowerCase() != category.trim().toLowerCase();
    final paidFromRaw = expense.incomeSource?.trim();
    final paidFrom = paidFromRaw != null && paidFromRaw.isNotEmpty
        ? localizeIncomeCategory(
            l10n,
            BudgetCalculator.categoryKey(paidFromRaw),
          )
        : null;
    final foreignSubtitle = formatForeignEntrySubtitle(
      l10n,
      TransactionEntryMeta(
        entryCurrency: expense.entryCurrency,
        entryAmount: expense.entryAmount,
      ),
    );
    final hasReceipt =
        expense.receiptUrl != null && expense.receiptUrl!.trim().isNotEmpty;
    final metaStyle = TextStyle(
      fontSize: 12.5,
      height: 1.25,
      fontWeight: FontWeight.w500,
      color: AppColors.textColor.withValues(alpha: 0.55),
    );
    final iconMetaColor = AppColors.textColor.withValues(alpha: 0.45);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AppDecorations.card(
            borderColor: AppColors.expense.withValues(alpha: 0.15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: _expenseColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasReceipt
                      ? Icons.receipt_long_rounded
                      : Icons.arrow_upward_rounded,
                  color: _expenseColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                        height: 1.2,
                      ),
                    ),
                    if (showTitleSubtitle) ...[
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: AppColors.textColor.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: iconMetaColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatDate(context, expense.date),
                            style: metaStyle,
                          ),
                        ),
                      ],
                    ),
                    if (foreignSubtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(foreignSubtitle, style: metaStyle),
                    ],
                    if (paidFrom != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${l10n.expensePaidFromField}: ',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textColor.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          Flexible(
                            child: PaymentMethodBadge(
                              label: paidFrom,
                              storedSource: paidFromRaw,
                            ),
                          ),
                        ],
                      ),
                    ],
                    FamilyAuthorMeta(
                      userId: expense.userId,
                      style: metaStyle,
                      iconColor: iconMetaColor,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '-${Money.format(expense.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _expenseColor,
                    height: 1.2,
                  ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                BlocBuilder<ExpensesTabBloc, ExpensesTabState>(
                  buildWhen: (previous, current) =>
                      previous.deletingExpenseId != current.deletingExpenseId ||
                      previous.status != current.status,
                  builder: (context, state) {
                    final isDeleting =
                        state.status == ExpensesTabStatus.loadingDelete &&
                        state.deletingExpenseId == expense.id;
                    return IconButton(
                      onPressed: isDeleting ? null : onDelete,
                      icon: isDeleting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _expenseColor.withValues(alpha: 0.7),
                              ),
                            )
                          : Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.textColor.withValues(
                                alpha: 0.35,
                              ),
                            ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.MMMd(locale).format(date);
  }
}
