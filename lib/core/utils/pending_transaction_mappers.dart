import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/models/pending_transaction.dart';
import 'package:imrpo/features/expenses_tab/data/models/expense_model.dart';
import 'package:imrpo/features/incomes_tab/data/models/income_model.dart';

List<ExpenseModel> pendingToExpenseModels(List<PendingTransaction> pending) {
  return pending
      .map(
        (item) => ExpenseModel(
          id: item.publicId,
          title: item.title,
          category: item.category,
          amount: item.amount,
          date: item.date,
          incomeSource: item.incomeSource,
          entryCurrency: item.entryCurrency,
          entryAmount: item.entryAmount,
          userId: SupabaseAuthHelper.userId,
        ),
      )
      .toList();
}

List<IncomeModel> pendingToIncomeModels(List<PendingTransaction> pending) {
  return pending
      .map(
        (item) => IncomeModel(
          id: item.publicId,
          title: item.title,
          category: item.category,
          amount: item.amount,
          date: item.date,
          entryCurrency: item.entryCurrency,
          entryAmount: item.entryAmount,
          userId: SupabaseAuthHelper.userId,
        ),
      )
      .toList();
}

List<ExpenseModel> mergeExpenses(
  List<ExpenseModel> remote,
  List<ExpenseModel> pending,
) {
  final merged = [...remote, ...pending];
  merged.sort((a, b) => b.date.compareTo(a.date));
  return merged;
}

List<IncomeModel> mergeIncomes(
  List<IncomeModel> remote,
  List<IncomeModel> pending,
) {
  final merged = [...remote, ...pending];
  merged.sort((a, b) => b.date.compareTo(a.date));
  return merged;
}
