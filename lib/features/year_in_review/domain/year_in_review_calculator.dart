import 'package:imrpo/features/budgets/domain/services/budget_calculator.dart';
import 'package:imrpo/features/expenses_tab/domain/entities/expense.dart';
import 'package:imrpo/features/incomes_tab/domain/entities/income.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';

class YearInReviewSnapshot {
  final int year;
  final double totalIncome;
  final double totalExpenses;
  final double net;
  final double savingsRate;
  final Map<String, double> topCategories;
  final Map<String, double> topMerchants;
  final Map<String, double> incomeBySource;
  final int loansClosed;
  final int loansStillOpen;
  final int? bestMonth;
  final double? bestMonthNet;
  final int? toughestMonth;
  final double? toughestMonthNet;

  const YearInReviewSnapshot({
    required this.year,
    required this.totalIncome,
    required this.totalExpenses,
    required this.net,
    required this.savingsRate,
    required this.topCategories,
    required this.topMerchants,
    required this.incomeBySource,
    required this.loansClosed,
    required this.loansStillOpen,
    this.bestMonth,
    this.bestMonthNet,
    this.toughestMonth,
    this.toughestMonthNet,
  });
}

class YearInReviewCalculator {
  YearInReviewCalculator._();

  static YearInReviewSnapshot build({
    required int year,
    required List<Income> incomes,
    required List<Expense> expenses,
    required List<Loan> loans,
  }) {
    final yearIncomes =
        incomes.where((i) => i.date.year == year).toList(growable: false);
    final yearExpenses =
        expenses.where((e) => e.date.year == year).toList(growable: false);

    final totalIncome =
        yearIncomes.fold<double>(0, (s, i) => s + i.amount);
    final totalExpenses =
        yearExpenses.fold<double>(0, (s, e) => s + e.amount);
    final net = totalIncome - totalExpenses;
    final savingsRate = totalIncome <= 0
        ? 0.0
        : ((totalIncome - totalExpenses) / totalIncome).clamp(0.0, 1.0);

    final categories = <String, double>{};
    final merchants = <String, double>{};
    for (final e in yearExpenses) {
      final cat = BudgetCalculator.categoryKey(e.category);
      categories[cat] = (categories[cat] ?? 0) + e.amount;
      final title = e.title.trim();
      if (title.isEmpty) continue;
      final key = title.length > 40 ? '${title.substring(0, 40)}…' : title;
      merchants[key] = (merchants[key] ?? 0) + e.amount;
    }

    final incomeBySource = <String, double>{};
    for (final i in yearIncomes) {
      final key = BudgetCalculator.categoryKey(i.category);
      incomeBySource[key] = (incomeBySource[key] ?? 0) + i.amount;
    }

    final monthNets = <int, double>{};
    for (var m = 1; m <= 12; m++) {
      final inc = yearIncomes
          .where((i) => i.date.month == m)
          .fold<double>(0, (s, i) => s + i.amount);
      final exp = yearExpenses
          .where((e) => e.date.month == m)
          .fold<double>(0, (s, e) => s + e.amount);
      if (inc == 0 && exp == 0) continue;
      monthNets[m] = inc - exp;
    }

    int? bestMonth;
    double? bestNet;
    int? toughMonth;
    double? toughNet;
    for (final entry in monthNets.entries) {
      if (bestNet == null || entry.value > bestNet) {
        bestNet = entry.value;
        bestMonth = entry.key;
      }
      if (toughNet == null || entry.value < toughNet) {
        toughNet = entry.value;
        toughMonth = entry.key;
      }
    }

    final closed = loans.where((l) => l.isSettled).length;
    final open = loans.where((l) => !l.isSettled).length;

    return YearInReviewSnapshot(
      year: year,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      net: net,
      savingsRate: savingsRate,
      topCategories: _top(categories, 5),
      topMerchants: _top(merchants, 5),
      incomeBySource: _top(incomeBySource, 5),
      loansClosed: closed,
      loansStillOpen: open,
      bestMonth: bestMonth,
      bestMonthNet: bestNet,
      toughestMonth: toughMonth,
      toughestMonthNet: toughNet,
    );
  }

  static Map<String, double> _top(Map<String, double> map, int n) {
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries.take(n));
  }
}
