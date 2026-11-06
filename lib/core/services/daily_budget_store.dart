import 'package:shared_preferences/shared_preferences.dart';

class DailyBudgetStore {
  static const String _dailyBudgetKey = 'pocketly_daily_budget_v1';

  static const double defaultDailyBudget = 300;

  static String _trackedKey(String userId) =>
      'pocketly_daily_budget_expense_ids_v1_$userId';

  Future<double> loadDailyBudget() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getDouble(_dailyBudgetKey) ?? defaultDailyBudget;
  }

  Future<bool> saveDailyBudget(double amount) async {
    if (!amount.isFinite || amount <= 0) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();

    return prefs.setDouble(_dailyBudgetKey, amount);
  }

  /// Expense ids created from the button inside the daily budget card.
  Future<Set<String>> loadTrackedExpenseIds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_trackedKey(userId))?.toSet() ?? <String>{};
  }

  Future<void> rememberTrackedExpenses(
    String userId,
    Iterable<String> ids,
  ) async {
    final tracked = await loadTrackedExpenseIds(userId);
    final fresh = ids.map((id) => id.trim()).where((id) => id.isNotEmpty);
    if (fresh.isEmpty) return;
    tracked.addAll(fresh);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_trackedKey(userId), tracked.toList());
  }
}
