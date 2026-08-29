import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/config/root_navigator.dart';
import 'package:imrpo/core/helpers/association_ledger_access.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/services/app_lock_service.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/features/balance_tab/presentation/bloc/balance_tab_bloc.dart';
import 'package:imrpo/features/bill_reminders/domain/bill_reminder_day_helper.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/add_expense_usecase.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/add_income_usecase.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/recurring_transactions/domain/entities/recurring_transaction.dart';
import 'package:imrpo/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

/// Posts due monthly recurring rules when the app is opened.
class RecurringTransactionPostService {
  RecurringTransactionPostService({
    required this.repository,
    required this.addIncomeUsecase,
    required this.addExpenseUsecase,
  });

  final RecurringTransactionRepository repository;
  final AddIncomeUsecase addIncomeUsecase;
  final AddExpenseUsecase addExpenseUsecase;

  bool _running = false;

  Future<int> postDue() async {
    if (_running) return 0;
    if (!SupabaseAuthHelper.isSignedIn) return 0;
    if (!AssociationLedgerAccess.canEdit) return 0;
    final lock = getIt<AppLockService>();
    if (lock.isEnabled && lock.isLocked) return 0;

    _running = true;
    var posted = 0;
    try {
      final result = await repository.getAll();
      final items = result.fold((_) => <RecurringTransaction>[], (list) => list);
      if (items.isEmpty) return 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final ym = RecurringTransaction.yearMonth(now);
      final next = <RecurringTransaction>[];

      for (final rule in items) {
        if (!rule.isEnabled || rule.amount <= 0) {
          next.add(rule);
          continue;
        }
        if (rule.lastPostedYm == ym) {
          next.add(rule);
          continue;
        }

        final dueDay = BillReminderDayHelper.effectiveDay(
          now.year,
          now.month,
          rule.dayOfMonth,
        );
        final due = DateTime(now.year, now.month, dueDay);
        if (today.isBefore(due)) {
          next.add(rule);
          continue;
        }

        final ok = await _post(rule, due);
        if (ok) {
          posted++;
          next.add(rule.copyWith(lastPostedYm: ym));
        } else {
          next.add(rule);
        }
      }

      if (posted > 0) {
        for (final rule in next) {
          await repository.save(rule);
        }
        _refreshTabs();
      }
    } finally {
      _running = false;
    }
    return posted;
  }

  Future<bool> _post(RecurringTransaction rule, DateTime due) async {
    if (rule.kind == RecurringKind.income) {
      final result = await addIncomeUsecase(
        rule.title,
        rule.amount,
        due,
        rule.category,
      );
      return result.isRight();
    }

    final result = await addExpenseUsecase(
      rule.title,
      rule.category,
      rule.amount,
      due,
      incomeSource: rule.incomeSource,
    );
    return result.isRight();
  }

  void _refreshTabs() {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    try {
      context.read<IncomesTabBloc>().add(const LoadIncomesEvent(force: true));
      context.read<ExpensesTabBloc>().add(const LoadExpensesEvent(force: true));
      final filter = getIt<HomeDateFilter>();
      context.read<BalanceTabBloc>().add(
        LoadBalanceEvent(
          reference: filter.date,
          filterByDay: filter.isDayMode,
          includeAllDates: filter.isAllMode,
        ),
      );
    } catch (_) {}
  }
}
