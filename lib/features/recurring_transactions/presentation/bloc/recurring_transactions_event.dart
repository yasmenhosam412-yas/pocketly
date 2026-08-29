part of 'recurring_transactions_bloc.dart';

sealed class RecurringTransactionsEvent extends Equatable {
  const RecurringTransactionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadRecurringTransactionsEvent extends RecurringTransactionsEvent {
  const LoadRecurringTransactionsEvent();
}

class SaveRecurringTransactionEvent extends RecurringTransactionsEvent {
  final RecurringTransaction item;

  const SaveRecurringTransactionEvent({required this.item});

  @override
  List<Object?> get props => [item];
}

class DeleteRecurringTransactionEvent extends RecurringTransactionsEvent {
  final String id;

  const DeleteRecurringTransactionEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class ToggleRecurringTransactionEvent extends RecurringTransactionsEvent {
  final String id;
  final bool enabled;

  const ToggleRecurringTransactionEvent({
    required this.id,
    required this.enabled,
  });

  @override
  List<Object?> get props => [id, enabled];
}

class ResetRecurringTransactionsEvent extends RecurringTransactionsEvent {
  const ResetRecurringTransactionsEvent();
}
