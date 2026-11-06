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
        'seats': item.seats
            .map(
              (seat) => {
                'name': seat.name,
                'partner_name': seat.partnerName,
                'payment_on': _dateOut(seat.paymentOn),
                'collection_on': _dateOut(seat.collectionOn),
                'partner_payment_on': _dateOut(seat.partnerPaymentOn),
                'partner_collection_on': _dateOut(seat.partnerCollectionOn),
                'paid_rounds': seat.paidRounds,
                'partner_paid_rounds': seat.partnerPaidRounds,
              },
            )
            .toList(),
        'starts_on': _dateOut(item.startsOn),
        'ends_on': _dateOut(item.endsOn),
        'last_paid_ym': item.lastPaidYm,
        'notes': item.notes,
        'pay_from': item.payFrom,
        'expense_category': item.expenseCategory,
        'receive_into': item.receiveInto,
        'last_expense_id': item.lastExpenseId,
        'last_income_id': item.lastIncomeId,
        'last_mark_index': item.lastMarkIndex,
        'last_mark_partner': item.lastMarkPartner,
      };

  List<GameyaSeat> _seats(Map<String, dynamic> map) {
    final rawSeats = map['seats'];
    if (rawSeats is List && rawSeats.isNotEmpty) {
      return rawSeats
          .whereType<Map>()
          .map((entry) => _seat(Map<String, dynamic>.from(entry)))
          .where((seat) => seat.name.isNotEmpty)
          .toList();
    }
    return _members(map['members'])
        .map((name) => GameyaSeat(name: name))
        .toList();
  }

  GameyaSeat _seat(Map<String, dynamic> map) {
    final partner = map['partner_name']?.toString().trim() ?? '';
    return GameyaSeat(
      name: map['name']?.toString().trim() ?? '',
      partnerName: partner.isEmpty ? null : partner,
      paymentOn: _dateIn(map['payment_on']),
      collectionOn: _dateIn(map['collection_on']),
      partnerPaymentOn: _dateIn(map['partner_payment_on']),
      partnerCollectionOn: _dateIn(map['partner_collection_on']),
      paidRounds: (map['paid_rounds'] as num?)?.toInt() ?? 0,
      partnerPaidRounds: (map['partner_paid_rounds'] as num?)?.toInt() ?? 0,
    );
  }

  String? _dateOut(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime? _dateIn(Object? raw) {
    final value = raw?.toString() ?? '';
    if (value.length < 10) return null;
    final y = int.tryParse(value.substring(0, 4));
    final m = int.tryParse(value.substring(5, 7));
    final d = int.tryParse(value.substring(8, 10));
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

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
      seats: _seats(map),
      startsOn: _dateIn(map['starts_on']),
      endsOn: _dateIn(map['ends_on']),
      lastPaidYm: map['last_paid_ym']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      payFrom: _text(map['pay_from'], fallback: 'Cash'),
      expenseCategory: _text(map['expense_category'], fallback: 'Bills'),
      receiveInto: _text(map['receive_into'], fallback: 'Cash'),
      lastExpenseId: map['last_expense_id']?.toString() ?? '',
      lastIncomeId: map['last_income_id']?.toString() ?? '',
      lastMarkIndex: (map['last_mark_index'] as num?)?.toInt() ?? -1,
      lastMarkPartner: map['last_mark_partner'] == true,
    );
  }
}
