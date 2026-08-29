import 'package:imrpo/features/balance_tab/domain/entities/balance_activity.dart';
import 'package:imrpo/features/balance_tab/domain/entities/balance_summary.dart';
import 'package:imrpo/features/expenses_tab/data/models/expense_model.dart';
import 'package:imrpo/features/incomes_tab/data/models/income_model.dart';

class BalanceSummaryBuilder {
  BalanceSummaryBuilder._();

  static BalanceSummary build({
    required List<IncomeModel> incomes,
    required List<ExpenseModel> expenses,
    required DateTime reference,
    bool filterByDay = false,
    bool includeAllDates = false,
  }) {
    final monthlyIncomes = includeAllDates
        ? incomes
        : incomes
            .where((i) => _matches(i.date, reference, filterByDay))
            .toList();
    final monthlyExpenses = includeAllDates
        ? expenses
        : expenses
            .where((e) => _matches(e.date, reference, filterByDay))
            .toList();

    final monthlyIncome =
        monthlyIncomes.fold<double>(0, (sum, i) => sum + i.amount);
    final monthlyExpenseTotal =
        monthlyExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    final activities = <BalanceActivity>[
      ...monthlyIncomes.map(
        (income) => BalanceActivity(
          id: 'income_${income.id}',
          title: income.title,
          category: income.category,
          amount: income.amount,
          date: income.date,
          type: BalanceActivityType.income,
          userId: income.userId,
        ),
      ),
      ...monthlyExpenses.map(
        (expense) => BalanceActivity(
          id: 'expense_${expense.id}',
          title: expense.title,
          category: expense.category,
          amount: expense.amount,
          date: expense.date,
          type: BalanceActivityType.expense,
          incomeSource: expense.incomeSource,
          userId: expense.userId,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return BalanceSummary(
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenseTotal,
      activities: activities,
    );
  }

  static bool _matches(DateTime date, DateTime reference, bool filterByDay) {
    if (filterByDay) {
      return date.year == reference.year &&
          date.month == reference.month &&
          date.day == reference.day;
    }
    return date.year == reference.year && date.month == reference.month;
  }
}
