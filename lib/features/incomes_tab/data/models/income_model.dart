import 'package:imrpo/core/helpers/row_user_id.dart';
import 'package:imrpo/features/incomes_tab/domain/entities/income.dart';

class IncomeModel extends Income {
  const IncomeModel({
    required super.id,
    required super.title,
    required super.category,
    required super.amount,
    required super.date,
    super.entryCurrency,
    super.entryAmount,
    super.userId,
  });

  factory IncomeModel.fromMap(Map<String, dynamic> map) {
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

    return IncomeModel(
      id: map['income_id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      entryCurrency: entryCurrency,
      entryAmount: entryAmount,
      userId: userIdFromRow(map),
    );
  }
}
