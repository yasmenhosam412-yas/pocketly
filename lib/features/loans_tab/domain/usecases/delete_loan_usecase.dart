import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/loans_tab/domain/repositories/loan_repository.dart';

class DeleteLoanUsecase {
  final LoanRepository loanRepository;

  DeleteLoanUsecase({required this.loanRepository});

  Future<Either<Failure, void>> call(String loanId) {
    return loanRepository.deleteLoan(loanId);
  }
}
