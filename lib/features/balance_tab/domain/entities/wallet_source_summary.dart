import 'package:equatable/equatable.dart';

class WalletSourceSummary extends Equatable {
  final String source;
  final double initial;
  final double income;
  final double spent;

  const WalletSourceSummary({
    required this.source,
    required this.initial,
    required this.income,
    required this.spent,
  });

  double get remaining => initial + income - spent;

  @override
  List<Object?> get props => [source, initial, income, spent];
}
