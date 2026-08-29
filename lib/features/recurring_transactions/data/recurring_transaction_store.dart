import 'dart:convert';

import 'package:imrpo/features/bill_reminders/domain/bill_reminder_day_helper.dart';
import 'package:imrpo/features/recurring_transactions/domain/entities/recurring_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecurringTransactionStore {
  static const _keyPrefix = 'recurring_tx_v1_';

  Future<List<RecurringTransaction>> loadAll(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$userId');
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => _fromMap(Map<String, dynamic>.from(e as Map)))
          .toList()
        ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(
    String userId,
    List<RecurringTransaction> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix$userId',
      jsonEncode(items.map(_toMap).toList()),
    );
  }

  Map<String, dynamic> _toMap(RecurringTransaction r) => {
        'id': r.id,
        'kind': r.kind.name,
        'title': r.title,
        'amount': r.amount,
        'category': r.category,
        'income_source': r.incomeSource,
        'day_of_month': r.dayOfMonth,
        'is_enabled': r.isEnabled,
        'last_posted_ym': r.lastPostedYm,
      };

  RecurringTransaction _fromMap(Map<String, dynamic> map) {
    final kindName = map['kind']?.toString() ?? RecurringKind.expense.name;
    return RecurringTransaction(
      id: map['id']?.toString() ?? '',
      kind: RecurringKind.values.firstWhere(
        (k) => k.name == kindName,
        orElse: () => RecurringKind.expense,
      ),
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      category: map['category']?.toString() ?? 'Other',
      incomeSource: map['income_source']?.toString(),
      dayOfMonth: BillReminderDayHelper.clampStoredDay(
        (map['day_of_month'] as num?)?.toInt() ?? 1,
      ),
      isEnabled: map['is_enabled'] != false,
      lastPostedYm: map['last_posted_ym']?.toString() ?? '',
    );
  }
}
