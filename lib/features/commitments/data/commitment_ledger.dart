import 'package:imrpo/features/expenses_tab/domain/usecases/add_expense_usecase.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/delete_expense_usecase.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/get_all_expenses_usecase.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/add_income_usecase.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/delete_income_usecase.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/get_all_incomes_usecase.dart';

class CommitmentPostResult {
  final String expenseId;
  final String incomeId;
  final String? error;

  const CommitmentPostResult({
    this.expenseId = '',
    this.incomeId = '',
    this.error,
  });

  bool get ok => error == null;
}

/// Writes a commitment payment into Expenses, and a gameya pot into Income.
class CommitmentLedger {
  CommitmentLedger({
    required this.addExpenseUsecase,
    required this.addIncomeUsecase,
    required this.deleteExpenseUsecase,
    required this.deleteIncomeUsecase,
    required this.getAllExpensesUsecase,
    required this.getAllIncomesUsecase,
  });

  final AddExpenseUsecase addExpenseUsecase;
  final AddIncomeUsecase addIncomeUsecase;
  final DeleteExpenseUsecase deleteExpenseUsecase;
  final DeleteIncomeUsecase deleteIncomeUsecase;
  final GetAllExpensesUsecase getAllExpensesUsecase;
  final GetAllIncomesUsecase getAllIncomesUsecase;

  static const missingLink = 'missing_link';
  static const rolledBack = 'rolled_back';

  Future<CommitmentPostResult> post({
    required String expenseTitle,
    required String category,
    required double amount,
    required String payFrom,
    required DateTime date,
    required Set<String> usedExpenseIds,
    String? incomeTitle,
    double payout = 0,
    String receiveInto = '',
    Set<String> usedIncomeIds = const {},
  }) async {
    final expenseResult = await addExpenseUsecase(
      expenseTitle,
      category,
      amount,
      date,
      incomeSource: payFrom,
    );
    final expenseError = expenseResult.fold((failure) => failure.error, (_) => null);
    if (expenseError != null) {
      return CommitmentPostResult(error: expenseError);
    }

    final expenseId = await _findExpenseId(
      title: expenseTitle,
      amount: amount,
      skip: usedExpenseIds,
    );
    if (expenseId == null) {
      return const CommitmentPostResult(error: missingLink);
    }

    final shouldPostIncome = incomeTitle != null &&
        incomeTitle.trim().isNotEmpty &&
        payout > 0 &&
        receiveInto.trim().isNotEmpty;
    if (!shouldPostIncome) {
      return CommitmentPostResult(expenseId: expenseId);
    }

    final incomeResult = await addIncomeUsecase(
      incomeTitle,
      payout,
      date,
      receiveInto,
    );
    final incomeError = incomeResult.fold((failure) => failure.error, (_) => null);
    if (incomeError != null) {
      await _deleteExpenseIfPresent(expenseId);
      return CommitmentPostResult(error: incomeError);
    }

    final incomeId = await _findIncomeId(
      title: incomeTitle,
      amount: payout,
      skip: usedIncomeIds,
    );
    if (incomeId == null) {
      await _deleteExpenseIfPresent(expenseId);
      return const CommitmentPostResult(error: rolledBack);
    }

    return CommitmentPostResult(expenseId: expenseId, incomeId: incomeId);
  }

  Future<String?> remove({
    required String expenseId,
    required String incomeId,
  }) async {
    final incomeError = await _deleteIncomeIfPresent(incomeId);
    final expenseError = await _deleteExpenseIfPresent(expenseId);
    return incomeError ?? expenseError;
  }

  Future<String?> _findExpenseId({
    required String title,
    required double amount,
    required Set<String> skip,
  }) async {
    final listed = await getAllExpensesUsecase();
    return listed.fold((_) => null, (items) {
      final matches = items
          .where(
            (item) =>
                item.title == title &&
                (item.amount - amount).abs() < 0.001 &&
                !skip.contains(item.id),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (matches.isEmpty) return null;
      return matches.first.id;
    });
  }

  Future<String?> _findIncomeId({
    required String title,
    required double amount,
    required Set<String> skip,
  }) async {
    final listed = await getAllIncomesUsecase();
    return listed.fold((_) => null, (items) {
      final matches = items
          .where(
            (item) =>
                item.title == title &&
                (item.amount - amount).abs() < 0.001 &&
                !skip.contains(item.id),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (matches.isEmpty) return null;
      return matches.first.id;
    });
  }

  Future<String?> _deleteExpenseIfPresent(String id) async {
    if (id.isEmpty) return null;
    final listed = await getAllExpensesUsecase();
    final exists = listed.fold(
      (_) => true,
      (items) => items.any((item) => item.id == id),
    );
    if (!exists) return null;
    final result = await deleteExpenseUsecase(id);
    return result.fold((failure) => failure.error, (_) => null);
  }

  Future<String?> _deleteIncomeIfPresent(String id) async {
    if (id.isEmpty) return null;
    final listed = await getAllIncomesUsecase();
    final exists = listed.fold(
      (_) => true,
      (items) => items.any((item) => item.id == id),
    );
    if (!exists) return null;
    final result = await deleteIncomeUsecase(id);
    return result.fold((failure) => failure.error, (_) => null);
  }
}
