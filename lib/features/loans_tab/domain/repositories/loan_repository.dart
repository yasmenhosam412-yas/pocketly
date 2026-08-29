import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/loans_tab/data/models/loan_model.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';

abstract class LoanRepository {
  Future<Either<Failure, String>> addLoan(
    String personName,
    LoanDirection direction,
    double principal,
    double repaidAmount,
    DateTime? dueDate,
    String notes,
  );

  Future<Either<Failure, void>> updateLoan(
    String loanId,
    String personName,
    LoanDirection direction,
    double principal,
    double repaidAmount,
    DateTime? dueDate,
    String notes,
  );

  Future<Either<Failure, void>> updateLoanRepaid(
    String loanId,
    double repaidAmount,
  );

  Future<Either<Failure, void>> deleteLoan(String loanId);

  Future<Either<Failure, List<LoanModel>>> getLoans();
}
