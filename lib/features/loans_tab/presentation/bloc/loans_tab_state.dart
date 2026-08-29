part of 'loans_tab_bloc.dart';

enum LoansTabStatus {
  initial,
  loading,
  loaded,
  error,
  loadingAdd,
  errorAdd,
  loadingUpdate,
  errorUpdate,
  loadingDelete,
  errorDelete,
  loadingUpdateSaved,
  errorUpdateSaved,
}

abstract class LoansTabState extends Equatable {
  const LoansTabState();

  @override
  List<Object?> get props => [];
}

class LoansTabInitial extends LoansTabState {
  const LoansTabInitial();
}

class LoansTabLoaded extends LoansTabState {
  final List<Loan> loans;
  final LoansFilter filter;
  final LoansTabStatus status;
  final String error;
  final String? deletingLoanId;

  const LoansTabLoaded({
    required this.loans,
    this.filter = LoansFilter.all,
    this.status = LoansTabStatus.loaded,
    this.error = '',
    this.deletingLoanId,
  });

  bool get hasData => loans.isNotEmpty;

  List<Loan> get visibleLoans {
    switch (filter) {
      case LoansFilter.all:
        return loans;
      case LoansFilter.given:
        return loans.where((l) => l.isGiven).toList();
      case LoansFilter.received:
        return loans.where((l) => !l.isGiven).toList();
      case LoansFilter.overdue:
        return loans.where((l) => l.isOverdue).toList();
      case LoansFilter.settled:
        return loans.where((l) => l.isSettled).toList();
    }
  }

  double get owedToYou => loans
      .where((l) => l.isGiven)
      .fold(0, (sum, loan) => sum + loan.remaining);

  double get youOwe => loans
      .where((l) => !l.isGiven)
      .fold(0, (sum, loan) => sum + loan.remaining);

  double get netPosition => owedToYou - youOwe;

  int get openCount => loans.where((l) => !l.isSettled).length;

  int get overdueCount => loans.where((l) => l.isOverdue).length;

  int get settledCount => loans.where((l) => l.isSettled).length;

  LoansTabLoaded copyWith({
    List<Loan>? loans,
    LoansFilter? filter,
    LoansTabStatus? status,
    String? error,
    String? deletingLoanId,
  }) {
    return LoansTabLoaded(
      loans: loans ?? this.loans,
      filter: filter ?? this.filter,
      status: status ?? this.status,
      error: error ?? this.error,
      deletingLoanId: deletingLoanId,
    );
  }

  @override
  List<Object?> get props => [loans, filter, status, error, deletingLoanId];
}
