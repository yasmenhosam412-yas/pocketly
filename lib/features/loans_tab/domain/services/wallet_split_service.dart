import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/add_expense_usecase.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';
import 'package:imrpo/features/loans_tab/domain/usecases/add_loan_usecase.dart';

class WalletSplitPersonShare {
  final String personName;
  final double amountInBase;

  const WalletSplitPersonShare({
    required this.personName,
    required this.amountInBase,
  });
}

class WalletSplitResult {
  final int loanCount;
  final double expenseAmount;

  const WalletSplitResult({
    required this.loanCount,
    required this.expenseAmount,
  });
}

/// Logs a wallet/InstaPay outflow as one expense and creates "I lent" loans
/// for each person who should repay their share.
class WalletSplitService {
  final AddExpenseUsecase _addExpense;
  final AddLoanUsecase _addLoan;

  WalletSplitService({
    required AddExpenseUsecase addExpenseUsecase,
    required AddLoanUsecase addLoanUsecase,
  })  : _addExpense = addExpenseUsecase,
        _addLoan = addLoanUsecase;

  Future<Either<Failure, WalletSplitResult>> submit({
    required String title,
    required String category,
    required double totalAmountInBase,
    required String paidFrom,
    required DateTime date,
    required List<WalletSplitPersonShare> debtors,
    String notes = '',
  }) async {
    if (totalAmountInBase <= 0) {
      return Left(UnknownError(error: 'invalid_amount'));
    }
    if (debtors.isEmpty) {
      return Left(UnknownError(error: 'split_no_people'));
    }
    for (final d in debtors) {
      if (d.personName.trim().isEmpty || d.amountInBase <= 0) {
        return Left(UnknownError(error: 'invalid_amount'));
      }
    }

    final expenseResult = await _addExpense(
      title.trim(),
      category,
      totalAmountInBase,
      date,
      incomeSource: paidFrom,
    );
    final expenseFailure = expenseResult.fold((f) => f, (_) => null);
    if (expenseFailure != null) return Left(expenseFailure);

    final noteParts = <String>[
      if (notes.trim().isNotEmpty) notes.trim(),
      'Split via $paidFrom',
    ];
    final loanNotes = noteParts.join(' · ');

    var loanCount = 0;
    for (final debtor in debtors) {
      final loanResult = await _addLoan(
        debtor.personName.trim(),
        LoanDirection.given,
        debtor.amountInBase,
        0,
        null,
        loanNotes,
      );
      final loanFailure = loanResult.fold((f) => f, (_) => null);
      if (loanFailure != null) {
        return Left(
          UnknownError(
            error: loanFailure.error.isNotEmpty
                ? loanFailure.error
                : 'split_partial_fail',
          ),
        );
      }
      loanCount++;
    }

    return Right(
      WalletSplitResult(
        loanCount: loanCount,
        expenseAmount: totalAmountInBase,
      ),
    );
  }
}
