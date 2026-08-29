import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/loans_tab/data/datasources/loans_datasource.dart';
import 'package:imrpo/features/loans_tab/data/models/loan_model.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';
import 'package:imrpo/features/loans_tab/domain/repositories/loan_repository.dart';

class LoanRepositoryImpl implements LoanRepository {
  final LoansDatasource loansDatasource;

  LoanRepositoryImpl({required this.loansDatasource});

  @override
  Future<Either<Failure, String>> addLoan(
    String personName,
    LoanDirection direction,
    double principal,
    double repaidAmount,
    DateTime? dueDate,
    String notes,
  ) async {
    try {
      final loanId = await loansDatasource.addLoan(
        personName,
        direction,
        principal,
        repaidAmount,
        dueDate,
        notes,
      );
      return Right(loanId);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLoan(String loanId) async {
    try {
      await loansDatasource.deleteLoan(loanId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, List<LoanModel>>> getLoans() async {
    try {
      final loans = await loansDatasource.getLoans();
      return Right(loans);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateLoan(
    String loanId,
    String personName,
    LoanDirection direction,
    double principal,
    double repaidAmount,
    DateTime? dueDate,
    String notes,
  ) async {
    try {
      await loansDatasource.updateLoan(
        loanId,
        personName,
        direction,
        principal,
        repaidAmount,
        dueDate,
        notes,
      );
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateLoanRepaid(
    String loanId,
    double repaidAmount,
  ) async {
    try {
      await loansDatasource.updateLoanRepaid(loanId, repaidAmount);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHelper.handle(e));
    }
  }
}
