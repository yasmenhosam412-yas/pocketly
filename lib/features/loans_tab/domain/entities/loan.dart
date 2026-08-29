import 'package:equatable/equatable.dart';

enum LoanDirection {
  given,
  received,
}

class Loan extends Equatable {
  final String id;
  final String personName;
  final LoanDirection direction;
  final double principal;
  final double repaidAmount;
  final DateTime? dueDate;
  final String notes;

  const Loan({
    required this.id,
    required this.personName,
    required this.direction,
    required this.principal,
    required this.repaidAmount,
    this.dueDate,
    this.notes = '',
  });

  double get remaining {
    final value = principal - repaidAmount;
    if (value <= 0) return 0;
    return value;
  }

  double get progress {
    if (principal <= 0) return 0;
    return (repaidAmount / principal).clamp(0.0, 1.0);
  }

  bool get isSettled => remaining <= 0;

  bool get isOverdue {
    if (isSettled || dueDate == null) return false;
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final today = DateTime.now();
    final startToday = DateTime(today.year, today.month, today.day);
    return due.isBefore(startToday);
  }

  bool get isGiven => direction == LoanDirection.given;

  @override
  List<Object?> get props => [
    id,
    personName,
    direction,
    principal,
    repaidAmount,
    dueDate,
    notes,
  ];
}
