import 'package:imrpo/core/services/currency_converter.dart';

enum FinancialEntryType { expense, income }

/// Data extracted from pasted text or bank SMS.
class ParsedFinancialEntry {
  final String? title;
  /// Amount in [currencyCode] as read from the message (not app base currency).
  final double? amount;
  final String? currencyCode;
  final DateTime? date;
  final FinancialEntryType type;
  final String rawText;
  /// Preset expense category (Food, Transport, …) when inferred from text.
  final String? expenseCategory;
  /// Wallet / card the expense was paid from.
  final String? paidFrom;
  /// Income source chip (Salary, Freelance, …).
  final String? incomeSource;

  const ParsedFinancialEntry({
    this.title,
    this.amount,
    this.currencyCode,
    this.date,
    required this.type,
    required this.rawText,
    this.expenseCategory,
    this.paidFrom,
    this.incomeSource,
  });

  String get sourceCurrencyCode =>
      currencyCode ?? CurrencyConverter.defaultDisplayCode;

  double? get amountInBase {
    if (amount == null) return null;
    return CurrencyConverter.toBase(amount!, sourceCurrencyCode);
  }

  bool get hasUsableData =>
      (amount != null && amount! > 0) ||
      (title != null && title!.trim().isNotEmpty);

  ParsedFinancialEntry copyWith({
    String? title,
    double? amount,
    String? currencyCode,
    DateTime? date,
    FinancialEntryType? type,
    String? expenseCategory,
    String? paidFrom,
    String? incomeSource,
  }) {
    return ParsedFinancialEntry(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      date: date ?? this.date,
      type: type ?? this.type,
      rawText: rawText,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      paidFrom: paidFrom ?? this.paidFrom,
      incomeSource: incomeSource ?? this.incomeSource,
    );
  }
}
