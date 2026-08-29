import 'package:equatable/equatable.dart';

class Income extends Equatable {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String? entryCurrency;
  final double? entryAmount;
  /// Who recorded this row (family ledgers).
  final String? userId;

  const Income({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
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
        entryCurrency,
        entryAmount,
        userId,
      ];
}
