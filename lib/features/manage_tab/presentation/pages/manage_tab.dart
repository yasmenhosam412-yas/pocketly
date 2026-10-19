import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:imrpo/core/helpers/association_ledger_access.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/expenses_tab/data/models/expense_model.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/expenses_tab/presentation/widgets/daily_budget_card.dart';
import 'package:imrpo/features/smart_import/presentation/widgets/smart_import_ai_tab.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class ManageTab extends StatelessWidget {
  const ManageTab({super.key});

  DateTime _localDate(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  double _toEgp(double amount) {
    return CurrencyConverter.fromBase(amount, 'EGP');
  }

  double _dailyTotal(List<ExpenseModel> expenses, DateTime date) {
    return expenses
        .where((expense) => _localDate(expense.date) == date)
        .fold<double>(0, (total, expense) => total + _toEgp(expense.amount));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ExpensesTabBloc, ExpensesTabState>(
        builder: (context, state) {
          final today = _localDate(DateTime.now());

          final dailyTotals = List.generate(7, (index) {
            final date = today.subtract(Duration(days: index));

            return _DailyExpense(
              date: date,
              amount: _dailyTotal(state.expenses, date),
            );
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                DailyBudgetCard(
                  expenses: state.expenses,
                  onAddExpense: () async {
                    if (!AssociationLedgerAccess.canEdit) return;

                    await showMagicAddSheet(
                      context,
                      preferredType: FinancialEntryType.expense,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _DailyExpensesList(items: dailyTotals),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DailyExpense {
  final DateTime date;
  final double amount;

  const _DailyExpense({required this.date, required this.amount});
}

class _DailyExpensesList extends StatelessWidget {
  final List<_DailyExpense> items;

  const _DailyExpensesList({required this.items});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.appPalette;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.stroke.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: palette.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.dailyExpensesSummaryTitle,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isToday = index == 0;

              final amount = l10n.egpAmount(
                NumberFormat('#,##0.##', 'en_US').format(item.amount),
              );

              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: palette.stroke.withValues(alpha: 0.15),
                      child: Icon(
                        isToday
                            ? Icons.today_rounded
                            : Icons.calendar_today_rounded,
                        color: palette.textMuted,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      isToday
                          ? DateFormat('dd/MM/yyyy').format(item.date)
                          : DateFormat('dd/MM/yyyy').format(item.date),
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: isToday
                        ? Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'اليوم'
                                : 'Today',
                            style: TextStyle(
                              color: palette.textMuted,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: Text(
                      amount,
                      style: TextStyle(
                        color: item.amount > 0
                            ? palette.textPrimary
                            : palette.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      color: palette.stroke.withValues(alpha: 0.15),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
