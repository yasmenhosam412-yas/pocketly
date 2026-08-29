import 'package:imrpo/features/balance_tab/domain/balance_source_constants.dart';
import 'package:imrpo/features/balance_tab/domain/entities/balance_activity.dart';
import 'package:imrpo/features/balance_tab/domain/entities/wallet_source_summary.dart';
import 'package:imrpo/features/balance_tab/domain/services/balance_summary_builder.dart';
import 'package:imrpo/features/budgets/domain/services/budget_calculator.dart';
import 'package:imrpo/features/expenses_tab/data/models/expense_model.dart';
import 'package:imrpo/features/incomes_tab/data/models/income_model.dart';

class WalletBalanceCalculator {
  WalletBalanceCalculator._();

  static const _epsilon = 0.005;

  static String _sourceKey(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? 'Other' : BudgetCalculator.categoryKey(trimmed);
  }

  static List<WalletSourceSummary> summaries({
    required List<BalanceActivity> activities,
    required Map<String, double> initialBySource,
  }) {
    final initial = <String, double>{};
    for (final entry in initialBySource.entries) {
      final key = _sourceKey(entry.key);
      initial[key] = (initial[key] ?? 0) + entry.value;
    }

    final income = <String, double>{};
    final spent = <String, double>{};
    var unassignedSpent = 0.0;

    for (final activity in activities) {
      if (activity.type == BalanceActivityType.income) {
        final key = _sourceKey(activity.category);
        income[key] = (income[key] ?? 0) + activity.amount;
      } else {
        final raw = activity.incomeSource?.trim();
        if (raw == null || raw.isEmpty) {
          unassignedSpent += activity.amount;
        } else {
          final key = _sourceKey(raw);
          spent[key] = (spent[key] ?? 0) + activity.amount;
        }
      }
    }

    final keys = {...initial.keys, ...income.keys, ...spent.keys};
    final rows = <WalletSourceSummary>[];

    for (final key in keys) {
      rows.add(
        WalletSourceSummary(
          source: key,
          initial: initial[key] ?? 0,
          income: income[key] ?? 0,
          spent: spent[key] ?? 0,
        ),
      );
    }

    if (unassignedSpent > 0) {
      rows.add(
        WalletSourceSummary(
          source: BalanceSourceConstants.unassigned,
          initial: 0,
          income: 0,
          spent: unassignedSpent,
        ),
      );
    }

    rows.sort((a, b) => b.remaining.compareTo(a.remaining));
    return rows;
  }

  /// All-time amount left in a pocket. Never negative.
  static double availableToSpend({
    required String? paidFrom,
    required List<IncomeModel> incomes,
    required List<ExpenseModel> expenses,
    required Map<String, double> initialBySource,
    String? excludeExpenseId,
  }) {
    final scoped = excludeExpenseId == null
        ? expenses
        : expenses.where((e) => e.id != excludeExpenseId).toList();
    final summary = BalanceSummaryBuilder.build(
      incomes: incomes,
      expenses: scoped,
      reference: DateTime.now(),
      includeAllDates: true,
    );
    final rows = summaries(
      activities: summary.activities,
      initialBySource: initialBySource,
    );
    final raw = paidFrom?.trim();
    if (raw == null || raw.isEmpty) {
      return rows
          .where((row) => row.source != BalanceSourceConstants.unassigned)
          .fold<double>(0, (sum, row) => sum + row.remaining);
    }
    final key = _sourceKey(raw);
    for (final row in rows) {
      if (row.source == key) return row.remaining;
    }
    return 0;
  }

  static bool exceedsPocket({
    required double amount,
    required String? paidFrom,
    required List<IncomeModel> incomes,
    required List<ExpenseModel> expenses,
    required Map<String, double> initialBySource,
    String? excludeExpenseId,
  }) {
    final available = availableToSpend(
      paidFrom: paidFrom,
      incomes: incomes,
      expenses: expenses,
      initialBySource: initialBySource,
      excludeExpenseId: excludeExpenseId,
    );
    return amount > available + _epsilon;
  }
}
