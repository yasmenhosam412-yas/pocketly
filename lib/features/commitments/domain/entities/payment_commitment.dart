import 'package:equatable/equatable.dart';

enum CommitmentKind { gameya, installment }

/// Personal tracker for a rotating savings circle (جمعية) or an installment plan (قسط).
class PaymentCommitment extends Equatable {
  final String id;
  final CommitmentKind kind;
  final String title;
  final double monthlyAmount;
  final int totalCount;
  final int paidCount;
  final int dueDay;
  /// 1-based month you receive the gameya pot. Unused for installments.
  final int myTurn;
  /// Gameya members in payout order. Index 0 receives the pot in month 1.
  final List<String> members;
  /// `yyyy-MM` of the last marked payment, or empty.
  final String lastPaidYm;
  final String notes;
  /// Wallet the monthly share is paid from (same sources as Expenses).
  final String payFrom;
  /// Expense category the monthly share is filed under.
  final String expenseCategory;
  /// Wallet a gameya pot is added to (an Income source).
  final String receiveInto;
  final String lastExpenseId;
  final String lastIncomeId;

  const PaymentCommitment({
    required this.id,
    required this.kind,
    required this.title,
    required this.monthlyAmount,
    required this.totalCount,
    this.paidCount = 0,
    this.dueDay = 1,
    this.myTurn = 1,
    this.members = const [],
    this.lastPaidYm = '',
    this.notes = '',
    this.payFrom = 'Cash',
    this.expenseCategory = 'Bills',
    this.receiveInto = 'Cash',
    this.lastExpenseId = '',
    this.lastIncomeId = '',
  });

  static String yearMonth(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  bool get isGameya => kind == CommitmentKind.gameya;

  int get safeTotal => totalCount < 1 ? 1 : totalCount;

  int get safePaid => paidCount.clamp(0, safeTotal);

  int get remainingCount => (safeTotal - safePaid).clamp(0, safeTotal);

  double get remainingMoney => remainingCount * monthlyAmount;

  double get paidMoney => safePaid * monthlyAmount;

  /// Full pot you receive on your gameya turn.
  double get payout => monthlyAmount * safeTotal;

  double get progress => safePaid / safeTotal;

  bool get isFinished => safePaid >= safeTotal;

  bool paidThisMonth([DateTime? now]) =>
      lastPaidYm.isNotEmpty && lastPaidYm == yearMonth(now ?? DateTime.now());

  bool canMarkPaid([DateTime? now]) => !isFinished && !paidThisMonth(now);

  /// Next cycle that still needs a payment (1-based).
  int get nextCycle => isFinished ? safeTotal : safePaid + 1;

  bool get isMyTurnNext =>
      isGameya && !isFinished && nextCycle == myTurn.clamp(1, safeTotal);

  bool get turnAlreadyPassed =>
      isGameya && safePaid >= myTurn.clamp(1, safeTotal);

  int get cyclesUntilMyTurn {
    if (!isGameya || isFinished) return 0;
    final turn = myTurn.clamp(1, safeTotal);
    final left = turn - nextCycle;
    return left < 0 ? 0 : left;
  }

  /// 1-based turn that is receiving the pot this month. 0 when this is not a gameya.
  int activeTurn([DateTime? now]) {
    if (!isGameya) return 0;
    if (isFinished) return safeTotal;
    if (paidThisMonth(now)) return safePaid.clamp(1, safeTotal).toInt();
    return nextCycle;
  }

  bool isMyTurnNow([DateTime? now]) {
    if (!isGameya || isFinished) return false;
    return activeTurn(now) == myTurn.clamp(1, safeTotal).toInt();
  }

  String nameForTurn(int turn) {
    final index = turn - 1;
    if (index < 0 || index >= members.length) return '';
    return members[index];
  }

  String activeTurnName([DateTime? now]) => nameForTurn(activeTurn(now));

  PaymentCommitment copyWith({
    String? id,
    CommitmentKind? kind,
    String? title,
    double? monthlyAmount,
    int? totalCount,
    int? paidCount,
    int? dueDay,
    int? myTurn,
    List<String>? members,
    String? lastPaidYm,
    String? notes,
    String? payFrom,
    String? expenseCategory,
    String? receiveInto,
    String? lastExpenseId,
    String? lastIncomeId,
  }) {
    return PaymentCommitment(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      totalCount: totalCount ?? this.totalCount,
      paidCount: paidCount ?? this.paidCount,
      dueDay: dueDay ?? this.dueDay,
      myTurn: myTurn ?? this.myTurn,
      members: members ?? this.members,
      lastPaidYm: lastPaidYm ?? this.lastPaidYm,
      notes: notes ?? this.notes,
      payFrom: payFrom ?? this.payFrom,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      receiveInto: receiveInto ?? this.receiveInto,
      lastExpenseId: lastExpenseId ?? this.lastExpenseId,
      lastIncomeId: lastIncomeId ?? this.lastIncomeId,
    );
  }

  PaymentCommitment recordPayment({
    required String expenseId,
    String incomeId = '',
    String? payFrom,
    String? expenseCategory,
    String? receiveInto,
    DateTime? now,
  }) {
    if (!canMarkPaid(now)) return this;
    return copyWith(
      paidCount: safePaid + 1,
      lastPaidYm: yearMonth(now ?? DateTime.now()),
      lastExpenseId: expenseId,
      lastIncomeId: incomeId,
      payFrom: payFrom,
      expenseCategory: expenseCategory,
      receiveInto: receiveInto,
    );
  }

  PaymentCommitment undoLastPayment() {
    if (!paidThisMonth() || safePaid <= 0) return this;
    return copyWith(
      paidCount: safePaid - 1,
      lastPaidYm: '',
      lastExpenseId: '',
      lastIncomeId: '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        kind,
        title,
        monthlyAmount,
        totalCount,
        paidCount,
        dueDay,
        myTurn,
        members,
        lastPaidYm,
        notes,
        payFrom,
        expenseCategory,
        receiveInto,
        lastExpenseId,
        lastIncomeId,
      ];
}
