import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String? incomeSource;
  final String? receiptUrl;
  final String? entryCurrency;
  final double? entryAmount;
  final String? userId;

  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.incomeSource,
    this.receiptUrl,
    this.entryCurrency,
    this.entryAmount,
    this.userId,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        amount,
        date,
        incomeSource,
        receiptUrl,
        entryCurrency,
        entryAmount,
        userId,
      ];
}
