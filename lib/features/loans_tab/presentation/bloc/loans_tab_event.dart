part of 'loans_tab_bloc.dart';

abstract class LoansTabEvent extends Equatable {
  const LoansTabEvent();

  @override
  List<Object> get props => [];
}

class LoadLoansEvent extends LoansTabEvent {
  final bool force;

  const LoadLoansEvent({this.force = false});

  @override
  List<Object> get props => [force];
}

class ResetLoansTabEvent extends LoansTabEvent {
  const ResetLoansTabEvent();
}

class SetLoansFilterEvent extends LoansTabEvent {
  final LoansFilter filter;

  const SetLoansFilterEvent(this.filter);

  @override
  List<Object> get props => [filter];
}

class AddLoanEvent extends LoansTabEvent {
  final String personName;
  final LoanDirection direction;
  final double principal;
  final double repaidAmount;
  final DateTime? dueDate;
  final String notes;

  const AddLoanEvent({
    required this.personName,
    required this.direction,
    required this.principal,
    required this.repaidAmount,
    this.dueDate,
    this.notes = '',
  });

  @override
  List<Object> get props => [
    personName,
    direction,
    principal,
    repaidAmount,
    dueDate ?? '',
    notes,
  ];
}

class UpdateLoanEvent extends LoansTabEvent {
  final String id;
  final String personName;
  final LoanDirection direction;
  final double principal;
  final double repaidAmount;
  final DateTime? dueDate;
  final String notes;

  const UpdateLoanEvent({
    required this.id,
    required this.personName,
    required this.direction,
    required this.principal,
    required this.repaidAmount,
    this.dueDate,
    this.notes = '',
  });

  @override
  List<Object> get props => [
    id,
    personName,
    direction,
    principal,
    repaidAmount,
    dueDate ?? '',
    notes,
  ];
}

class RecordLoanPaymentEvent extends LoansTabEvent {
  final String id;
  final double amount;

  /// Wallet / payment method: expense "paid from" when you repay,
  /// or income source when you receive a repayment.
  final String walletSource;

  /// Localized title for the expense or income created for this payment.
  final String balanceEntryTitle;

  const RecordLoanPaymentEvent({
    required this.id,
    required this.amount,
    required this.walletSource,
    required this.balanceEntryTitle,
  });

  @override
  List<Object> get props => [id, amount, walletSource, balanceEntryTitle];
}

class DeleteLoanEvent extends LoansTabEvent {
  final String id;

  const DeleteLoanEvent(this.id);

  @override
  List<Object> get props => [id];
}
