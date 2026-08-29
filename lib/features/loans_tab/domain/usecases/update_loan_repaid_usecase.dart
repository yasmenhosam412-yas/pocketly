import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/loans_tab/domain/repositories/loan_repository.dart';

class UpdateLoanRepaidUsecase {
  final LoanRepository loanRepository;

  UpdateLoanRepaidUsecase({required this.loanRepository});

  Future<Either<Failure, void>> call(String loanId, double repaidAmount) {
    return loanRepository.updateLoanRepaid(loanId, repaidAmount);
  }
}
