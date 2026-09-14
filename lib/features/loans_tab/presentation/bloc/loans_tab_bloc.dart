import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/add_expense_usecase.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/add_income_usecase.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';
import 'package:imrpo/features/loans_tab/domain/usecases/add_loan_usecase.dart';
import 'package:imrpo/features/loans_tab/domain/usecases/delete_loan_usecase.dart';
import 'package:imrpo/features/loans_tab/domain/usecases/get_all_loans_usecase.dart';
import 'package:imrpo/features/loans_tab/domain/usecases/update_loan_repaid_usecase.dart';
import 'package:imrpo/features/loans_tab/domain/usecases/update_loan_usecase.dart';

part 'loans_tab_event.dart';
part 'loans_tab_state.dart';

enum LoansFilter { all, given, received, overdue, settled }

class LoansTabBloc extends Bloc<LoansTabEvent, LoansTabState> {
  static const loanPaymentExpenseCategory = 'Other';

  final GetAllLoansUsecase getAllLoansUsecase;
  final AddLoanUsecase addLoanUsecase;
  final UpdateLoanUsecase updateLoanUsecase;
  final UpdateLoanRepaidUsecase updateLoanRepaidUsecase;
  final DeleteLoanUsecase deleteLoanUsecase;
  final AddExpenseUsecase addExpenseUsecase;
  final AddIncomeUsecase addIncomeUsecase;

  LoansTabBloc({
    required this.getAllLoansUsecase,
    required this.addLoanUsecase,
    required this.updateLoanUsecase,
    required this.updateLoanRepaidUsecase,
    required this.deleteLoanUsecase,
    required this.addExpenseUsecase,
    required this.addIncomeUsecase,
  }) : super(const LoansTabInitial()) {
    on<LoadLoansEvent>(_onLoad);
    on<ResetLoansTabEvent>(_onReset);
    on<AddLoanEvent>(_onAdd);
    on<UpdateLoanEvent>(_onUpdate);
    on<RecordLoanPaymentEvent>(_onRecordPayment);
    on<DeleteLoanEvent>(_onDelete);
    on<SetLoansFilterEvent>(_onSetFilter);
  }

  LoansTabLoaded _loadingState() {
    final current = state;
    if (current is LoansTabLoaded) {
      return current.copyWith(status: LoansTabStatus.loading, error: '');
    }
    return const LoansTabLoaded(
      loans: [],
      status: LoansTabStatus.loading,
    );
  }

  void _onReset(ResetLoansTabEvent event, Emitter<LoansTabState> emit) {
    emit(const LoansTabInitial());
  }

  void _onSetFilter(SetLoansFilterEvent event, Emitter<LoansTabState> emit) {
    final current = state;
    if (current is LoansTabLoaded) {
      emit(current.copyWith(filter: event.filter));
    }
  }

  Future<void> _onLoad(
    LoadLoansEvent event,
    Emitter<LoansTabState> emit,
  ) async {
    final current = state;
    if (!event.force &&
        current is LoansTabLoaded &&
        current.status == LoansTabStatus.loading &&
        !current.hasData) {
      return;
    }
    if (current is LoansTabLoaded && current.hasData) {
      emit(current.copyWith(status: LoansTabStatus.loading, error: ''));
    } else {
      emit(_loadingState());
    }

    final result = await getAllLoansUsecase();

    result.fold(
      (failure) {
        final previous = state;
        if (previous is LoansTabLoaded && previous.hasData) {
          emit(
            previous.copyWith(
              status: LoansTabStatus.error,
              error: failure.error,
            ),
          );
        } else {
          emit(
            LoansTabLoaded(
              loans: const [],
              filter: previous is LoansTabLoaded
                  ? previous.filter
                  : LoansFilter.all,
              status: LoansTabStatus.error,
              error: failure.error,
            ),
          );
        }
      },
      (loans) {
        final previous = state;
        emit(
          LoansTabLoaded(
            loans: loans,
            filter: previous is LoansTabLoaded
                ? previous.filter
                : LoansFilter.all,
            status: LoansTabStatus.loaded,
          ),
        );
      },
    );
  }

  Future<void> _onAdd(
    AddLoanEvent event,
    Emitter<LoansTabState> emit,
  ) async {
    final current = state;
    if (current is LoansTabLoaded) {
      emit(current.copyWith(status: LoansTabStatus.loadingAdd, error: ''));
    }

    final result = await addLoanUsecase(
      event.personName,
      event.direction,
      event.principal,
      event.repaidAmount,
      event.dueDate,
      event.notes,
    );

    result.fold(
      (failure) {
        final previous = state;
        if (previous is LoansTabLoaded) {
          emit(
            previous.copyWith(
              status: LoansTabStatus.errorAdd,
              error: failure.error,
            ),
          );
        }
      },
      (_) => add(const LoadLoansEvent()),
    );
  }

  Future<void> _onUpdate(
    UpdateLoanEvent event,
    Emitter<LoansTabState> emit,
  ) async {
    final current = state;
    if (current is LoansTabLoaded) {
      emit(current.copyWith(status: LoansTabStatus.loadingUpdate, error: ''));
    }

    final result = await updateLoanUsecase(
      event.id,
      event.personName,
      event.direction,
      event.principal,
      event.repaidAmount,
      event.dueDate,
      event.notes,
    );

    result.fold(
      (failure) {
        final previous = state;
        if (previous is LoansTabLoaded) {
          emit(
            previous.copyWith(
              status: LoansTabStatus.errorUpdate,
              error: failure.error,
            ),
          );
        }
      },
      (_) => add(const LoadLoansEvent()),
    );
  }

  Future<void> _onRecordPayment(
    RecordLoanPaymentEvent event,
    Emitter<LoansTabState> emit,
  ) async {
    final current = state;
    if (current is! LoansTabLoaded) return;

    Loan? loan;
    for (final candidate in current.loans) {
      if (candidate.id == event.id) {
        loan = candidate;
        break;
      }
    }
    if (loan == null) return;
    final target = loan;

    if (event.amount <= 0) {
      emit(
        current.copyWith(
          status: LoansTabStatus.errorUpdateSaved,
          error: 'Invalid amount',
        ),
      );
      return;
    }

    final walletSource = event.walletSource.trim();
    if (walletSource.isEmpty) {
      emit(
        current.copyWith(
          status: LoansTabStatus.errorUpdateSaved,
          error: 'Select a payment source',
        ),
      );
      return;
    }

    final addAmount = event.amount > target.remaining
        ? target.remaining
        : event.amount;
    if (addAmount <= 0) return;

    emit(
      current.copyWith(status: LoansTabStatus.loadingUpdateSaved, error: ''),
    );

    final title = event.balanceEntryTitle.trim().isEmpty
        ? 'Loan payment · ${target.personName}'
        : event.balanceEntryTitle.trim();
    final now = DateTime.now();

    // Given (owed to you): repayment credits the wallet as income.
    // Received (you owe): repayment debits the wallet as expense.
    final balanceResult = target.isGiven
        ? await addIncomeUsecase(title, addAmount, now, walletSource)
        : await addExpenseUsecase(
            title,
            loanPaymentExpenseCategory,
            addAmount,
            now,
            incomeSource: walletSource,
          );

    final balanceFailed = balanceResult.fold(
      (failure) {
        final previous = state;
        if (previous is LoansTabLoaded) {
          emit(
            previous.copyWith(
              status: LoansTabStatus.errorUpdateSaved,
              error: failure.error,
            ),
          );
        }
        return true;
      },
      (_) => false,
    );
    if (balanceFailed) return;

    final newRepaid = target.repaidAmount + addAmount;
    final result = await updateLoanRepaidUsecase(target.id, newRepaid);

    result.fold(
      (failure) {
        final previous = state;
        if (previous is LoansTabLoaded) {
          emit(
            previous.copyWith(
              status: LoansTabStatus.errorUpdateSaved,
              error: failure.error,
            ),
          );
        }
      },
      (_) {
        final previous = state;
        if (previous is! LoansTabLoaded) return;
        final updatedLoans = previous.loans
            .map(
              (l) => l.id == target.id
                  ? Loan(
                      id: l.id,
                      personName: l.personName,
                      direction: l.direction,
                      principal: l.principal,
                      repaidAmount: newRepaid,
                      dueDate: l.dueDate,
                      notes: l.notes,
                      userId: l.userId,
                    )
                  : l,
            )
            .toList();
        emit(
          previous.copyWith(
            loans: updatedLoans,
            status: LoansTabStatus.loaded,
            error: '',
          ),
        );
      },
    );
  }

  Future<void> _onDelete(
    DeleteLoanEvent event,
    Emitter<LoansTabState> emit,
  ) async {
    final current = state;
    if (current is LoansTabLoaded) {
      emit(
        current.copyWith(
          status: LoansTabStatus.loadingDelete,
          deletingLoanId: event.id,
          error: '',
        ),
      );
    }

    final result = await deleteLoanUsecase(event.id);
    if (emit.isDone) return;

    if (result.isLeft()) {
      final failure = result.fold(
        (l) => l,
        (_) => throw StateError('unreachable'),
      );
      final previous = state;
      if (previous is LoansTabLoaded) {
        emit(
          previous.copyWith(
            status: LoansTabStatus.errorDelete,
            error: failure.error,
            deletingLoanId: null,
          ),
        );
      }
      return;
    }

    if (current is LoansTabLoaded) {
      final updated =
          current.loans.where((loan) => loan.id != event.id).toList();
      emit(
        current.copyWith(
          loans: updated,
          status: LoansTabStatus.loaded,
          deletingLoanId: null,
          error: '',
        ),
      );
    }

    add(const LoadLoansEvent(force: true));
  }
}
