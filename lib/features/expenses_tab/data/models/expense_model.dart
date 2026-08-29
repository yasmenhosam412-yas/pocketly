import 'package:imrpo/core/helpers/row_user_id.dart';
import 'package:imrpo/features/expenses_tab/domain/entities/expense.dart';

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.title,
    required super.category,
    required super.amount,
    required super.date,
    super.incomeSource,
    super.receiptUrl,
    super.entryCurrency,
    super.entryAmount,
    super.userId,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    final rawSource = map['income_source'];
    final String? incomeSource;
    if (rawSource is String) {
      final t = rawSource.trim();
      incomeSource = t.isEmpty ? null : t;
    } else {
      incomeSource = null;
    }
    final rawReceipt = map['receipt_url'];
    final String? receiptUrl;
    if (rawReceipt is String) {
      final t = rawReceipt.trim();
      receiptUrl = t.isEmpty ? null : t;
    } else {
      receiptUrl = null;
    }
    final rawEntryCurrency = map['entry_currency'];
    final String? entryCurrency;
    if (rawEntryCurrency is String) {
      final t = rawEntryCurrency.trim();
      entryCurrency = t.isEmpty ? null : t;
    } else {
      entryCurrency = null;
    }
    final rawEntryAmount = map['entry_amount'];
    final double? entryAmount = rawEntryAmount == null
        ? null
        : (rawEntryAmount as num).toDouble();

    return ExpenseModel(
      id: map['expense_id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      incomeSource: incomeSource,
      receiptUrl: receiptUrl,
      entryCurrency: entryCurrency,
      entryAmount: entryAmount,
      userId: userIdFromRow(map),
    );
  }
}
