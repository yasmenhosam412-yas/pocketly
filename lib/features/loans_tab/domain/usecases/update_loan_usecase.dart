import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';
import 'package:imrpo/features/loans_tab/domain/repositories/loan_repository.dart';

class UpdateLoanUsecase {
  final LoanRepository loanRepository;

  UpdateLoanUsecase({required this.loanRepository});

  Future<Either<Failure, void>> call(
    String loanId,
    String personName,
    LoanDirection direction,
    double principal,
    double repaidAmount,
    DateTime? dueDate,
    String notes,
  ) {
    return loanRepository.updateLoan(
      loanId,
      personName,
      direction,
      principal,
      repaidAmount,
      dueDate,
      notes,
    );
  }
}
