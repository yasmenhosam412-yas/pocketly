import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:imrpo/features/recurring_transactions/data/recurring_transaction_post_service.dart';
import 'package:imrpo/features/recurring_transactions/domain/entities/recurring_transaction.dart';
import 'package:imrpo/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

part 'recurring_transactions_event.dart';
part 'recurring_transactions_state.dart';

class RecurringTransactionsBloc
    extends Bloc<RecurringTransactionsEvent, RecurringTransactionsState> {
  final RecurringTransactionRepository repository;
  final RecurringTransactionPostService postService;

  RecurringTransactionsBloc({
    required this.repository,
    required this.postService,
  }) : super(const RecurringTransactionsInitial()) {
    on<LoadRecurringTransactionsEvent>(_onLoad);
    on<SaveRecurringTransactionEvent>(_onSave);
    on<DeleteRecurringTransactionEvent>(_onDelete);
    on<ToggleRecurringTransactionEvent>(_onToggle);
    on<ResetRecurringTransactionsEvent>(_onReset);
  }

  void _onReset(
    ResetRecurringTransactionsEvent event,
    Emitter<RecurringTransactionsState> emit,
  ) {
    emit(const RecurringTransactionsInitial());
  }

  Future<void> _onLoad(
    LoadRecurringTransactionsEvent event,
    Emitter<RecurringTransactionsState> emit,
  ) async {
    emit(const RecurringTransactionsLoading());
    final result = await repository.getAll();
    result.fold(
      (failure) => emit(RecurringTransactionsError(failure.error)),
      (items) => emit(RecurringTransactionsLoaded(items: items)),
    );
  }

  Future<void> _onSave(
    SaveRecurringTransactionEvent event,
    Emitter<RecurringTransactionsState> emit,
  ) async {
    final current = state;
    if (current is RecurringTransactionsLoaded) {
      emit(current.copyWith(isSaving: true));
    }

    final result = await repository.save(event.item);
    await result.fold((_) async {}, (_) async {
      await postService.postDue();
    });
    add(const LoadRecurringTransactionsEvent());
  }

  Future<void> _onDelete(
    DeleteRecurringTransactionEvent event,
    Emitter<RecurringTransactionsState> emit,
  ) async {
    await repository.delete(event.id);
    add(const LoadRecurringTransactionsEvent());
  }

  Future<void> _onToggle(
    ToggleRecurringTransactionEvent event,
    Emitter<RecurringTransactionsState> emit,
  ) async {
    final current = state;
    if (current is! RecurringTransactionsLoaded) return;

    RecurringTransaction? target;
    for (final item in current.items) {
      if (item.id == event.id) {
        target = item;
        break;
      }
    }
    if (target == null) return;

    await repository.save(target.copyWith(isEnabled: event.enabled));
    if (event.enabled) {
      await postService.postDue();
    }
    add(const LoadRecurringTransactionsEvent());
  }
}
