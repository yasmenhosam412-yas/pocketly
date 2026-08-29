part of 'recurring_transactions_bloc.dart';

sealed class RecurringTransactionsState extends Equatable {
  const RecurringTransactionsState();

  @override
  List<Object?> get props => [];
}

class RecurringTransactionsInitial extends RecurringTransactionsState {
  const RecurringTransactionsInitial();
}

class RecurringTransactionsLoading extends RecurringTransactionsState {
  const RecurringTransactionsLoading();
}

class RecurringTransactionsLoaded extends RecurringTransactionsState {
  final List<RecurringTransaction> items;
  final bool isSaving;

  const RecurringTransactionsLoaded({
    required this.items,
    this.isSaving = false,
  });

  RecurringTransactionsLoaded copyWith({
    List<RecurringTransaction>? items,
    bool? isSaving,
  }) {
    return RecurringTransactionsLoaded(
      items: items ?? this.items,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [items, isSaving];
}

class RecurringTransactionsError extends RecurringTransactionsState {
  final String message;

  const RecurringTransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}
