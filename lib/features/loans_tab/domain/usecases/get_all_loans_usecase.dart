import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/loans_tab/data/models/loan_model.dart';
import 'package:imrpo/features/loans_tab/domain/repositories/loan_repository.dart';

class GetAllLoansUsecase {
  final LoanRepository loanRepository;

  GetAllLoansUsecase({required this.loanRepository});

  Future<Either<Failure, List<LoanModel>>> call() {
    return loanRepository.getLoans();
  }
}
