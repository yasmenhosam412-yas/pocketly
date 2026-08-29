import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';

class LoanModel extends Loan {
  const LoanModel({
    required super.id,
    required super.personName,
    required super.direction,
    required super.principal,
    required super.repaidAmount,
    super.dueDate,
    super.notes,
  });

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    final dueRaw = map['due_date'];
    return LoanModel(
      id: map['loan_id'] as String,
      personName: map['person_name'] as String,
      direction: _directionFromStored(map['direction'] as String?),
      principal: (map['principal'] as num).toDouble(),
      repaidAmount: (map['repaid_amount'] as num?)?.toDouble() ?? 0,
      dueDate: dueRaw != null ? DateTime.parse(dueRaw as String) : null,
      notes: (map['notes'] as String?) ?? '',
    );
  }

  static LoanDirection _directionFromStored(String? value) {
    if (value == LoanDirection.received.name) {
      return LoanDirection.received;
    }
    return LoanDirection.given;
  }
}
