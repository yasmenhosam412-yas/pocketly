import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User rules for splitting a paycheck (percentages of salary).
class SalaryDayPreferences extends ChangeNotifier {
  static const _dayKey = 'salary_day_of_month_v1';
  static const _rentKey = 'salary_alloc_rent_pct_v1';
  static const _billsKey = 'salary_alloc_bills_pct_v1';
  static const _plansKey = 'salary_alloc_plans_pct_v1';
  static const _promptKey = 'salary_day_prompt_enabled_v1';

  int _dayOfMonth = 1;
  double _rentPercent = 30;
  double _billsPercent = 20;
  double _plansPercent = 20;
  bool _promptOnSalaryIncome = true;

  int get dayOfMonth => _dayOfMonth;
  double get rentPercent => _rentPercent;
  double get billsPercent => _billsPercent;
  double get plansPercent => _plansPercent;
  double get leftoverPercent {
    final used = _rentPercent + _billsPercent + _plansPercent;
    final left = 100 - used;
    return left < 0 ? 0 : left;
  }

  bool get promptOnSalaryIncome => _promptOnSalaryIncome;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _dayOfMonth = (prefs.getInt(_dayKey) ?? 1).clamp(1, 28);
    _rentPercent = prefs.getDouble(_rentKey) ?? 30;
    _billsPercent = prefs.getDouble(_billsKey) ?? 20;
    _plansPercent = prefs.getDouble(_plansKey) ?? 20;
    _promptOnSalaryIncome = prefs.getBool(_promptKey) ?? true;
    notifyListeners();
  }

  Future<void> save({
    required int dayOfMonth,
    required double rentPercent,
    required double billsPercent,
    required double plansPercent,
    required bool promptOnSalaryIncome,
  }) async {
    _dayOfMonth = dayOfMonth.clamp(1, 28);
    _rentPercent = rentPercent.clamp(0, 100);
    _billsPercent = billsPercent.clamp(0, 100);
    _plansPercent = plansPercent.clamp(0, 100);
    _promptOnSalaryIncome = promptOnSalaryIncome;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dayKey, _dayOfMonth);
    await prefs.setDouble(_rentKey, _rentPercent);
    await prefs.setDouble(_billsKey, _billsPercent);
    await prefs.setDouble(_plansKey, _plansPercent);
    await prefs.setBool(_promptKey, _promptOnSalaryIncome);
  }

  bool isSalaryDay([DateTime? now]) {
    final today = now ?? DateTime.now();
    return today.day == _dayOfMonth;
  }
}
