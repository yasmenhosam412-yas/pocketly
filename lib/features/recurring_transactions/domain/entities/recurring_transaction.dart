import 'package:equatable/equatable.dart';

enum RecurringKind { income, expense }

class RecurringTransaction extends Equatable {
  final String id;
  final RecurringKind kind;
  final String title;
  final double amount;
  final String category;
  final String? incomeSource;
  final int dayOfMonth;
  final bool isEnabled;
  /// `yyyy-MM` of the last month a row was posted, or empty if never.
  final String lastPostedYm;

  static String yearMonth(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  const RecurringTransaction({
    required this.id,
    required this.kind,
    required this.title,
    required this.amount,
    required this.category,
    this.incomeSource,
    required this.dayOfMonth,
    this.isEnabled = true,
    this.lastPostedYm = '',
  });

  RecurringTransaction copyWith({
    String? id,
    RecurringKind? kind,
    String? title,
    double? amount,
    String? category,
    String? incomeSource,
    bool clearIncomeSource = false,
    int? dayOfMonth,
    bool? isEnabled,
    String? lastPostedYm,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      incomeSource: clearIncomeSource
          ? null
          : (incomeSource ?? this.incomeSource),
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isEnabled: isEnabled ?? this.isEnabled,
      lastPostedYm: lastPostedYm ?? this.lastPostedYm,
    );
  }

  @override
  List<Object?> get props => [
        id,
        kind,
        title,
        amount,
        category,
        incomeSource,
        dayOfMonth,
        isEnabled,
        lastPostedYm,
      ];
}
