import 'package:equatable/equatable.dart';

class InitialBalanceEntry extends Equatable {
  final String source;
  final double amount;

  const InitialBalanceEntry({
    required this.source,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'amount': amount,
      };

  factory InitialBalanceEntry.fromJson(Map<String, dynamic> json) {
    return InitialBalanceEntry(
      source: (json['source'] as String? ?? '').trim(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [source, amount];
}
