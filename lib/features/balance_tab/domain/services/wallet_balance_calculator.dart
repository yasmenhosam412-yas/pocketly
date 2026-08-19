import 'package:imrpo/features/balance_tab/domain/balance_source_constants.dart';
import 'package:imrpo/features/balance_tab/domain/entities/balance_activity.dart';
import 'package:imrpo/features/balance_tab/domain/entities/wallet_source_summary.dart';
import 'package:imrpo/features/budgets/domain/services/budget_calculator.dart';

class WalletBalanceCalculator {
  WalletBalanceCalculator._();

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
}
