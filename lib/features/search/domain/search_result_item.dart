import 'package:equatable/equatable.dart';
import 'package:imrpo/features/expenses_tab/data/models/expense_model.dart';
import 'package:imrpo/features/incomes_tab/data/models/income_model.dart';

enum SearchResultType { income, expense }

class SearchResultItem extends Equatable {
  final SearchResultType type;
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String? userId;

  const SearchResultItem({
    required this.type,
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.userId,
  });

  factory SearchResultItem.fromIncome(IncomeModel income) {
    return SearchResultItem(
      type: SearchResultType.income,
      id: income.id,
      title: income.title,
      category: income.category,
      amount: income.amount,
      date: income.date,
      userId: income.userId,
    );
  }

  factory SearchResultItem.fromExpense(ExpenseModel expense) {
    return SearchResultItem(
      type: SearchResultType.expense,
      id: expense.id,
      title: expense.title,
      category: expense.category,
      amount: expense.amount,
      date: expense.date,
      userId: expense.userId,
    );
  }

  @override
  List<Object?> get props => [type, id, title, category, amount, date, userId];
}
