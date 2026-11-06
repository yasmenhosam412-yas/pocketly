import 'package:equatable/equatable.dart';

enum CommitmentKind { gameya, installment }

/// One payout turn. [partnerName] shares the turn with [name].
class GameyaSeat extends Equatable {
  final String name;
  final String? partnerName;
  final DateTime? paymentOn;
  final DateTime? collectionOn;
  final DateTime? partnerPaymentOn;
  final DateTime? partnerCollectionOn;
  final int paidRounds;
  final int partnerPaidRounds;

  const GameyaSeat({
    required this.name,
    this.partnerName,
    this.paymentOn,
    this.collectionOn,
    this.partnerPaymentOn,
    this.partnerCollectionOn,
    this.paidRounds = 0,
    this.partnerPaidRounds = 0,
  });

  bool get isSplit => (partnerName?.trim().isNotEmpty ?? false);

  String joined(String Function(String first, String second) join) {
    if (!isSplit) return name;
    return join(name, partnerName!.trim());
  }

  @override
  List<Object?> get props => [
        name,
        partnerName,
        paymentOn,
        collectionOn,
        partnerPaymentOn,
        partnerCollectionOn,
        paidRounds,
        partnerPaidRounds,
      ];
}

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
  /// Gameya turns in payout order. Index 0 receives the pot in month 1.
  final List<GameyaSeat> seats;
  final DateTime? startsOn;
  final DateTime? endsOn;
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
  /// Last person marked paid. -1 when there is nothing to undo.
  final int lastMarkIndex;
  final bool lastMarkPartner;

  const PaymentCommitment({
    required this.id,
    required this.kind,
    required this.title,
    required this.monthlyAmount,
    required this.totalCount,
    this.paidCount = 0,
    this.dueDay = 1,
    this.myTurn = 1,
    this.seats = const [],
    this.startsOn,
    this.endsOn,
    this.lastPaidYm = '',
    this.notes = '',
    this.payFrom = 'Cash',
    this.expenseCategory = 'Bills',
    this.receiveInto = 'Cash',
    this.lastExpenseId = '',
    this.lastIncomeId = '',
    this.lastMarkIndex = -1,
    this.lastMarkPartner = false,
  });

  static String yearMonth(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  bool get isGameya => kind == CommitmentKind.gameya;

  /// Primary name of each turn, in payout order.
  List<String> get members => seats.map((seat) => seat.name).toList();

  int get safeTotal => totalCount < 1 ? 1 : totalCount;

  int get safePaid => paidCount.clamp(0, safeTotal);

  int get remainingCount => (safeTotal - safePaid).clamp(0, safeTotal);

  double get remainingMoney => remainingCount * monthlyAmount;

  double get paidMoney => safePaid * monthlyAmount;

  /// Full pot you receive on your gameya turn.
  double get payout => monthlyAmount * safeTotal;

  double get progress => safePaid / safeTotal;

  bool get isFinished => safePaid >= safeTotal;

  bool seatPaidThisRound(int index, {bool partner = false}) {
    if (index < 0 || index >= seats.length || isFinished) return false;
    final seat = seats[index];
    final paid = partner ? seat.partnerPaidRounds : seat.paidRounds;
    return paid >= openRound;
  }

  /// Round currently collecting payments. Each person can be marked once.
  int get openRound => isFinished ? safeTotal : safePaid + 1;

  bool get tracksPeople => isGameya && seats.isNotEmpty;

  PaymentCommitment markPersonPaid(int index, {bool partner = false}) {
    if (!tracksPeople || isFinished) return this;
    if (index < 0 || index >= seats.length) return this;
    final seat = seats[index];
    if (partner && !seat.isSplit) return this;
    if (seatPaidThisRound(index, partner: partner)) return this;
    final round = openRound;
    final updated = GameyaSeat(
      name: seat.name,
      partnerName: seat.partnerName,
      paymentOn: seat.paymentOn,
      collectionOn: seat.collectionOn,
      partnerPaymentOn: seat.partnerPaymentOn,
      partnerCollectionOn: seat.partnerCollectionOn,
      paidRounds: partner ? seat.paidRounds : round,
      partnerPaidRounds: partner ? round : seat.partnerPaidRounds,
    );
    final nextSeats = [...seats]..[index] = updated;
    final roundDone = nextSeats.every((candidate) {
      final primaryDone = candidate.paidRounds >= round;
      final partnerDone =
          !candidate.isSplit || candidate.partnerPaidRounds >= round;
      return primaryDone && partnerDone;
    });
    return copyWith(
      seats: nextSeats,
      paidCount: roundDone ? safePaid + 1 : paidCount,
      lastPaidYm: yearMonth(DateTime.now()),
      lastMarkIndex: index,
      lastMarkPartner: partner,
    );
  }

  PaymentCommitment undoLastPerson() {
    if (lastMarkIndex < 0 || lastMarkIndex >= seats.length) return this;
    final seat = seats[lastMarkIndex];
    final paid = lastMarkPartner ? seat.partnerPaidRounds : seat.paidRounds;
    if (paid <= 0) return this;
    final closedRound = paidCount >= paid;
    final updated = GameyaSeat(
      name: seat.name,
      partnerName: seat.partnerName,
      paymentOn: seat.paymentOn,
      collectionOn: seat.collectionOn,
      partnerPaymentOn: seat.partnerPaymentOn,
      partnerCollectionOn: seat.partnerCollectionOn,
      paidRounds: lastMarkPartner ? seat.paidRounds : paid - 1,
      partnerPaidRounds: lastMarkPartner ? paid - 1 : seat.partnerPaidRounds,
    );
    final nextSeats = [...seats]..[lastMarkIndex] = updated;
    return copyWith(
      seats: nextSeats,
      paidCount: closedRound
          ? (paidCount - 1).clamp(0, safeTotal).toInt()
          : paidCount,
      lastPaidYm: '',
      lastMarkIndex: -1,
      lastMarkPartner: false,
    );
  }

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
    if (tracksPeople) return openRound.clamp(1, safeTotal).toInt();
    if (paidThisMonth(now)) return safePaid.clamp(1, safeTotal).toInt();
    return nextCycle;
  }

  bool isMyTurnNow([DateTime? now]) {
    if (!isGameya || isFinished) return false;
    return activeTurn(now) == myTurn.clamp(1, safeTotal).toInt();
  }

  String nameForTurn(int turn) {
    final index = turn - 1;
    if (index < 0 || index >= seats.length) return '';
    return seats[index].joined((first, second) => '$first · $second');
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
    List<GameyaSeat>? seats,
    DateTime? startsOn,
    DateTime? endsOn,
    String? lastPaidYm,
    String? notes,
    String? payFrom,
    String? expenseCategory,
    String? receiveInto,
    String? lastExpenseId,
    String? lastIncomeId,
    int? lastMarkIndex,
    bool? lastMarkPartner,
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
      seats: seats ?? this.seats,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
      lastPaidYm: lastPaidYm ?? this.lastPaidYm,
      notes: notes ?? this.notes,
      payFrom: payFrom ?? this.payFrom,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      receiveInto: receiveInto ?? this.receiveInto,
      lastExpenseId: lastExpenseId ?? this.lastExpenseId,
      lastIncomeId: lastIncomeId ?? this.lastIncomeId,
      lastMarkIndex: lastMarkIndex ?? this.lastMarkIndex,
      lastMarkPartner: lastMarkPartner ?? this.lastMarkPartner,
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
        seats,
        startsOn,
        endsOn,
        lastPaidYm,
        notes,
        payFrom,
        expenseCategory,
        receiveInto,
        lastExpenseId,
        lastIncomeId,
        lastMarkIndex,
        lastMarkPartner,
      ];
}
