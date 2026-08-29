import 'package:imrpo/features/loans_tab/data/models/loan_model.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';

abstract class LoansDatasource {
  Future<String> addLoan(
    String personName,
    LoanDirection direction,
    double principal,
    double repaidAmount,
    DateTime? dueDate,
    String notes,
  );

  Future<void> updateLoan(
    String loanId,
    String personName,
    LoanDirection direction,
    double principal,
    double repaidAmount,
    DateTime? dueDate,
    String notes,
  );

  Future<void> updateLoanRepaid(String loanId, double repaidAmount);

  Future<void> deleteLoan(String loanId);

  Future<List<LoanModel>> getLoans();
}
