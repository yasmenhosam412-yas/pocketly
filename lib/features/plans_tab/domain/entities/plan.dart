import 'package:equatable/equatable.dart';

class Plan extends Equatable {
  final String id;
  final String title;
  final String category;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final String? userId;
  final String? imageUrl;

  const Plan({
    required this.id,
    required this.title,
    required this.category,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    this.userId,
    this.imageUrl,
  });

  double get progress {
    if (targetAmount <= 0) return 0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0);
  }

  bool get isCompleted => savedAmount >= targetAmount;

  double get remaining {
    final left = targetAmount - savedAmount;
    return left <= 0 ? 0 : left;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    category,
    targetAmount,
    savedAmount,
    deadline,
    userId,
    imageUrl,
  ];
}
