import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/balance_tab/domain/entities/balance_summary.dart';
import 'package:imrpo/features/balance_tab/domain/services/balance_summary_builder.dart';
import 'package:imrpo/features/balance_tab/domain/repositories/balance_repository.dart';
import 'package:imrpo/features/expenses_tab/domain/repositories/expense_repository.dart';
import 'package:imrpo/features/incomes_tab/domain/repositories/income_repository.dart';

class BalanceRepositoryImpl implements BalanceRepository {
  final IncomeRepository incomeRepository;
  final ExpenseRepository expenseRepository;

  BalanceRepositoryImpl({
    required this.incomeRepository,
    required this.expenseRepository,
  });

  @override
  Future<Either<Failure, BalanceSummary>> getBalance({
    required DateTime reference,
    bool filterByDay = false,
    bool includeAllDates = false,
  }) async {
    final incomesResult = await incomeRepository.getIncomes();
    final expensesResult = await expenseRepository.getExpenses();

    return incomesResult.fold(
      Left.new,
      (incomes) => expensesResult.fold(
        Left.new,
        (expenses) => Right(
          BalanceSummaryBuilder.build(
            incomes: incomes,
            expenses: expenses,
            reference: reference,
            filterByDay: filterByDay,
            includeAllDates: includeAllDates,
          ),
        ),
      ),
    );
  }
}
