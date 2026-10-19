import 'package:shared_preferences/shared_preferences.dart';

class DailyBudgetStore {
  static const String _dailyBudgetKey = 'pocketly_daily_budget_v1';

  static const double defaultDailyBudget = 300;

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
}
