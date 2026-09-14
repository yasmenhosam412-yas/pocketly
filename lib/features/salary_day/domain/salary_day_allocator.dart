import 'package:dartz/dartz.dart';
import 'package:imrpo/core/helpers/error_helper.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/add_expense_usecase.dart';
import 'package:imrpo/features/plans_tab/domain/entities/plan.dart';
import 'package:imrpo/features/plans_tab/domain/usecases/update_plan_saved_usecase.dart';

enum SalaryAllocationKind { rent, bills, plans, leftover }

class SalaryAllocationLine {
  final SalaryAllocationKind kind;
  final String title;
  final String category;
  final double amountInBase;
  final bool enabled;
  final String? planId;
  final double? planCurrentSaved;

  const SalaryAllocationLine({
    required this.kind,
    required this.title,
    required this.category,
    required this.amountInBase,
    this.enabled = true,
    this.planId,
    this.planCurrentSaved,
  });

  SalaryAllocationLine copyWith({
    double? amountInBase,
    bool? enabled,
  }) {
    return SalaryAllocationLine(
      kind: kind,
      title: title,
      category: category,
      amountInBase: amountInBase ?? this.amountInBase,
      enabled: enabled ?? this.enabled,
      planId: planId,
      planCurrentSaved: planCurrentSaved,
    );
  }
}

class SalaryAllocationDraft {
  final double salaryAmountInBase;
  final String paidFrom;
  final List<SalaryAllocationLine> lines;

  const SalaryAllocationDraft({
    required this.salaryAmountInBase,
    required this.paidFrom,
    required this.lines,
  });

  double get allocatedTotal => lines
      .where((l) => l.enabled && l.kind != SalaryAllocationKind.leftover)
      .fold<double>(0, (sum, l) => sum + l.amountInBase);

  double get leftover =>
      (salaryAmountInBase - allocatedTotal).clamp(0, salaryAmountInBase);
}

class SalaryDayAllocator {
  final AddExpenseUsecase _addExpense;
  final UpdatePlanSavedUsecase _updatePlanSaved;

  SalaryDayAllocator({
    required AddExpenseUsecase addExpenseUsecase,
    required UpdatePlanSavedUsecase updatePlanSavedUsecase,
  })  : _addExpense = addExpenseUsecase,
        _updatePlanSaved = updatePlanSavedUsecase;

  static SalaryAllocationDraft buildDraft({
    required double salaryAmountInBase,
    required double rentPercent,
    required double billsPercent,
    required double plansPercent,
    required List<Plan> plans,
    String paidFrom = 'Salary',
  }) {
    if (salaryAmountInBase <= 0) {
      return SalaryAllocationDraft(
        salaryAmountInBase: 0,
        paidFrom: paidFrom,
        lines: const [],
      );
    }

    final rent = salaryAmountInBase * (rentPercent / 100);
    final bills = salaryAmountInBase * (billsPercent / 100);
    final plansBudget = salaryAmountInBase * (plansPercent / 100);

    final lines = <SalaryAllocationLine>[
      if (rent > 0)
        SalaryAllocationLine(
          kind: SalaryAllocationKind.rent,
          title: 'Rent',
          category: 'Rent',
          amountInBase: rent,
        ),
      if (bills > 0)
        SalaryAllocationLine(
          kind: SalaryAllocationKind.bills,
          title: 'Bills',
          category: 'Bills',
          amountInBase: bills,
        ),
    ];

    final openPlans =
        plans.where((p) => p.savedAmount < p.targetAmount).toList()
          ..sort((a, b) {
            final aLeft = a.targetAmount - a.savedAmount;
            final bLeft = b.targetAmount - b.savedAmount;
            return bLeft.compareTo(aLeft);
          });

    if (plansBudget > 0 && openPlans.isNotEmpty) {
      final each = plansBudget / openPlans.length;
      for (final plan in openPlans) {
        final room = plan.targetAmount - plan.savedAmount;
        final amount = each < room ? each : room;
        if (amount <= 0) continue;
        lines.add(
          SalaryAllocationLine(
            kind: SalaryAllocationKind.plans,
            title: plan.title,
            category: 'Savings',
            amountInBase: amount,
            planId: plan.id,
            planCurrentSaved: plan.savedAmount,
          ),
        );
      }
    } else if (plansBudget > 0) {
      lines.add(
        SalaryAllocationLine(
          kind: SalaryAllocationKind.plans,
          title: 'Savings',
          category: 'Savings',
          amountInBase: plansBudget,
        ),
      );
    }

    final allocated = lines.fold<double>(0, (s, l) => s + l.amountInBase);
    final leftover =
        (salaryAmountInBase - allocated).clamp(0.0, double.infinity);
    lines.add(
      SalaryAllocationLine(
        kind: SalaryAllocationKind.leftover,
        title: 'Leftover',
        category: 'Other',
        amountInBase: leftover,
        enabled: false,
      ),
    );

    return SalaryAllocationDraft(
      salaryAmountInBase: salaryAmountInBase,
      paidFrom: paidFrom,
      lines: lines,
    );
  }

  Future<Either<Failure, int>> apply(
    SalaryAllocationDraft draft, {
    DateTime? date,
  }) async {
    final when = date ?? DateTime.now();
    var created = 0;

    for (final line in draft.lines) {
      if (!line.enabled) continue;
      if (line.kind == SalaryAllocationKind.leftover) continue;
      if (line.amountInBase <= 0) continue;

      final expenseResult = await _addExpense(
        line.title,
        line.category,
        line.amountInBase,
        when,
        incomeSource: draft.paidFrom,
      );
      final expenseFail = expenseResult.fold((f) => f, (_) => null);
      if (expenseFail != null) return Left(expenseFail);
      created++;

      if (line.kind == SalaryAllocationKind.plans &&
          line.planId != null &&
          line.planCurrentSaved != null) {
        final nextSaved = line.planCurrentSaved! + line.amountInBase;
        final planResult = await _updatePlanSaved(line.planId!, nextSaved);
        final planFail = planResult.fold((f) => f, (_) => null);
        if (planFail != null) return Left(planFail);
      }
    }

    return Right(created);
  }
}
