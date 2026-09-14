import 'package:imrpo/features/plans_tab/domain/entities/plan.dart';

enum PlanPaceStatus { completed, overdue, urgent, steady, noDeadline }

/// Helps users pace savings toward a plan target and deadline.
class PlanSavingsCoach {
  PlanSavingsCoach._();

  static double remaining(Plan plan) {
    final left = plan.targetAmount - plan.savedAmount;
    return left <= 0 ? 0 : left;
  }

  /// Whole months left until deadline (at least 1 if deadline is still ahead).
  static int? monthsRemaining(Plan plan, {DateTime? now}) {
    final deadline = plan.deadline;
    if (deadline == null || plan.isCompleted) return null;
    final today = _dateOnly(now ?? DateTime.now());
    final due = _dateOnly(deadline);
    if (!due.isAfter(today)) return 0;
    var months =
        (due.year - today.year) * 12 + (due.month - today.month);
    if (due.day < today.day) months -= 1;
    return months < 1 ? 1 : months;
  }

  /// Days left until deadline (0 if due today or past).
  static int? daysRemaining(Plan plan, {DateTime? now}) {
    final deadline = plan.deadline;
    if (deadline == null || plan.isCompleted) return null;
    final today = _dateOnly(now ?? DateTime.now());
    final due = _dateOnly(deadline);
    final days = due.difference(today).inDays;
    return days < 0 ? 0 : days;
  }

  /// Suggested amount to save each month to hit the deadline.
  static double? suggestedMonthly(Plan plan, {DateTime? now}) {
    final left = remaining(plan);
    if (left <= 0) return null;
    final months = monthsRemaining(plan, now: now);
    if (months == null) return null;
    if (months <= 0) return left;
    return left / months;
  }

  static PlanPaceStatus paceStatus(Plan plan, {DateTime? now}) {
    if (plan.isCompleted) return PlanPaceStatus.completed;
    final deadline = plan.deadline;
    if (deadline == null) return PlanPaceStatus.noDeadline;

    final days = daysRemaining(plan, now: now) ?? 0;
    if (days <= 0 && remaining(plan) > 0) return PlanPaceStatus.overdue;
    if (days <= 30) return PlanPaceStatus.urgent;
    return PlanPaceStatus.steady;
  }

  /// Useful contribution: smallest of available cash, remaining goal, and
  /// monthly suggestion (when present).
  static double suggestedContribution({
    required Plan plan,
    required double availableBalance,
    DateTime? now,
  }) {
    final left = remaining(plan);
    if (left <= 0 || availableBalance <= 0) return 0;
    final monthly = suggestedMonthly(plan, now: now);
    final candidates = <double>[left, availableBalance];
    if (monthly != null && monthly > 0) {
      candidates.add(monthly);
    }
    return candidates.reduce((a, b) => a < b ? a : b);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
