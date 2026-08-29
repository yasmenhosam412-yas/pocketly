import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';
import 'package:imrpo/features/loans_tab/domain/repositories/loan_repository.dart';

class AddLoanUsecase {
  final LoanRepository loanRepository;

  AddLoanUsecase({required this.loanRepository});

  Future<Either<Failure, String>> call(
    String personName,
    LoanDirection direction,
    double principal,
    double repaidAmount,
    DateTime? dueDate,
    String notes,
  ) {
    return loanRepository.addLoan(
      personName,
      direction,
      principal,
      repaidAmount,
      dueDate,
      notes,
    );
  }
}
