
import 'package:imrpo/core/models/parsed_financial_entry.dart';

class MagicAddHistoryEntry {
  final String id;
  final String originalText;
  final String title;
  final double amount;
  final String currencyCode;
  final DateTime date;
  final FinancialEntryType type;
  final String? expenseCategory;
  final String? paidFrom;
  final String? incomeSource;
  final DateTime savedAt;

  const MagicAddHistoryEntry({
    required this.id,
    required this.originalText,
    required this.title,
    required this.amount,
    required this.currencyCode,
    required this.date,
    required this.type,
    required this.savedAt,
    this.expenseCategory,
    this.paidFrom,
    this.incomeSource,
  });

  factory MagicAddHistoryEntry.fromParsedEntry(
    ParsedFinancialEntry entry,
  ) {
    return MagicAddHistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      originalText: entry.rawText,
      title: entry.title ?? "",
      amount: entry.amount ?? 0,
      currencyCode: entry.currencyCode ?? "",
      date: entry.date ?? DateTime(2026),
      type: entry.type,
      expenseCategory: entry.expenseCategory,
      paidFrom: entry.paidFrom,
      incomeSource: entry.incomeSource,
      savedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalText': originalText,
      'title': title,
      'amount': amount,
      'currencyCode': currencyCode,
      'date': date.toIso8601String(),
      'type': type.name,
      'expenseCategory': expenseCategory,
      'paidFrom': paidFrom,
      'incomeSource': incomeSource,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory MagicAddHistoryEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    return MagicAddHistoryEntry(
      id: json['id'] as String,
      originalText: json['originalText'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'EGP',
      date: DateTime.parse(json['date'] as String),
      type: FinancialEntryType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => FinancialEntryType.expense,
      ),
      expenseCategory: json['expenseCategory'] as String?,
      paidFrom: json['paidFrom'] as String?,
      incomeSource: json['incomeSource'] as String?,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}
