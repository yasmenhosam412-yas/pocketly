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

  double get remaining {
    final net = initial + income - spent;
    return net < 0 ? 0 : net;
  }

  @override
  List<Object?> get props => [source, initial, income, spent];
}
