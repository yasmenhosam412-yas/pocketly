import 'dart:convert';

import 'package:imrpo/features/bill_reminders/domain/bill_reminder_day_helper.dart';
import 'package:imrpo/features/commitments/domain/entities/payment_commitment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommitmentStore {
  static const _keyPrefix = 'commitments_v1_';

  Future<List<PaymentCommitment>> loadAll(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$userId');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => _fromMap(Map<String, dynamic>.from(e as Map)))
          .where((item) => item.id.isNotEmpty && item.title.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(String userId, List<PaymentCommitment> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix$userId',
      jsonEncode(items.map(_toMap).toList()),
    );
  }

  Map<String, dynamic> _toMap(PaymentCommitment item) => {
        'id': item.id,
        'kind': item.kind.name,
        'title': item.title,
        'monthly_amount': item.monthlyAmount,
        'total_count': item.totalCount,
        'paid_count': item.paidCount,
        'due_day': item.dueDay,
        'my_turn': item.myTurn,
        'members': item.members,
        'last_paid_ym': item.lastPaidYm,
        'notes': item.notes,
        'pay_from': item.payFrom,
        'expense_category': item.expenseCategory,
        'receive_into': item.receiveInto,
        'last_expense_id': item.lastExpenseId,
        'last_income_id': item.lastIncomeId,
      };

  List<String> _members(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((entry) => entry.toString().trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  String _text(Object? raw, {required String fallback}) {
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  PaymentCommitment _fromMap(Map<String, dynamic> map) {
    final kindName = map['kind']?.toString() ?? CommitmentKind.installment.name;
    return PaymentCommitment(
      id: map['id']?.toString() ?? '',
      kind: CommitmentKind.values.firstWhere(
        (k) => k.name == kindName,
        orElse: () => CommitmentKind.installment,
      ),
      title: map['title']?.toString() ?? '',
      monthlyAmount: (map['monthly_amount'] as num?)?.toDouble() ?? 0,
      totalCount: (map['total_count'] as num?)?.toInt() ?? 1,
      paidCount: (map['paid_count'] as num?)?.toInt() ?? 0,
      dueDay: BillReminderDayHelper.clampStoredDay(
        (map['due_day'] as num?)?.toInt() ?? 1,
      ),
      myTurn: (map['my_turn'] as num?)?.toInt() ?? 1,
      members: _members(map['members']),
      lastPaidYm: map['last_paid_ym']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      payFrom: _text(map['pay_from'], fallback: 'Cash'),
      expenseCategory: _text(map['expense_category'], fallback: 'Bills'),
      receiveInto: _text(map['receive_into'], fallback: 'Cash'),
      lastExpenseId: map['last_expense_id']?.toString() ?? '',
      lastIncomeId: map['last_income_id']?.toString() ?? '',
    );
  }
}
