import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/services/app_lock_service.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/association_member_names.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:imrpo/features/balance_tab/presentation/bloc/balance_tab_bloc.dart';
import 'package:imrpo/features/budgets/domain/entities/budget_period.dart';
import 'package:imrpo/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/home/presentation/bloc/home_bloc.dart';
import 'package:imrpo/core/services/bill_reminder_notification_service.dart';
import 'package:imrpo/core/services/daily_digest_notification_service.dart';
import 'package:imrpo/core/services/notification_inbox_store.dart';
import 'package:imrpo/core/services/initial_balance_store.dart';
import 'package:imrpo/core/services/offline_transaction_store.dart';
import 'package:imrpo/core/services/offline_transaction_sync_service.dart';
import 'package:imrpo/features/bill_reminders/data/bill_reminder_store.dart';
import 'package:imrpo/features/bill_reminders/presentation/bloc/bill_reminders_bloc.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
import 'package:imrpo/features/loans_tab/presentation/bloc/loans_tab_bloc.dart';

/// Clears cached user-specific state when signing out or switching accounts.
class UserSession {
  UserSession._();

  static Future<void> ensureAssociationsLoaded() async {
    await getIt<AssociationContext>().load();
  }

  static void clearAll(BuildContext context) {
    BillReminderNotificationService.instance.cancelAll();
    DailyDigestNotificationService.instance.cancel();
    getIt<NotificationInboxStore>().clear();
    getIt<OfflineTransactionStore>().clearForUser();
    getIt<InitialBalanceStore>().clearForUser();
    final userId = SupabaseAuthHelper.userId;
    if (userId != null) {
      getIt<BillReminderStore>().clear(userId);
    }
    context.read<BillRemindersBloc>().add(const ResetBillRemindersEvent());
    getIt<AssociationContext>().clear();
    getIt<AssociationMemberNames>().clear();
    getIt<AppLockService>().onLoggedOut();
    getIt<HomeDateFilter>().reset(notify: false);
    context.read<HomeBloc>().add(const ClearUserProfileEvent());
    context.read<IncomesTabBloc>().add(const ResetIncomesTabEvent());
    context.read<ExpensesTabBloc>().add(const ResetExpensesTabEvent());
    context.read<BudgetsBloc>().add(const ResetBudgetsEvent());
    context.read<BalanceTabBloc>().add(const ResetBalanceTabEvent());
    context.read<PlansTabBloc>().add(const ResetPlansTabEvent());
    context.read<LoansTabBloc>().add(const ResetLoansTabEvent());
    context.read<AuthBloc>().add(const ResetAuthEvent());
  }

  /// Reloads all tabs after switching association ledger.
  static void reloadForAssociationSwitch(BuildContext context) {
    if (!SupabaseAuthHelper.isSignedIn) return;
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent(force: true));
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent(force: true));
    final dateFilter = getIt<HomeDateFilter>();
    final budgetPeriod = BudgetPeriod.fromDateFilter(dateFilter);
    context.read<BudgetsBloc>().add(
          LoadBudgetsEvent(
            year: budgetPeriod.year,
            month: budgetPeriod.month,
            force: true,
          ),
        );
    context.read<PlansTabBloc>().add(const LoadPlansEvent(force: true));
    context.read<LoansTabBloc>().add(const LoadLoansEvent(force: true));
    getIt<AssociationMemberNames>().refresh();
  }

  static void loadAll(BuildContext context) {
    final associations = getIt<AssociationContext>();
    if (associations.isOffline) {
      _loadOfflineLedgers(context);
      return;
    }
    if (associations.isAvailable && !associations.isReadyForData) {
      return;
    }
    context.read<HomeBloc>().add(const LoadUserProfileEvent());
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent());
    final dateFilter = getIt<HomeDateFilter>();
    final budgetPeriod = BudgetPeriod.fromDateFilter(dateFilter);
    context.read<BudgetsBloc>().add(
          LoadBudgetsEvent(
            year: budgetPeriod.year,
            month: budgetPeriod.month,
          ),
        );
    context.read<PlansTabBloc>().add(const LoadPlansEvent());
    context.read<LoansTabBloc>().add(const LoadLoansEvent());
    getIt<AssociationMemberNames>().refresh();
  }

  static void _loadOfflineLedgers(BuildContext context) {
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent(force: true));
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent(force: true));
  }

  /// Flushes queued transactions then reloads tabs when back online.
  static Future<void> syncOfflineTransactionsAndReload(
    BuildContext context,
  ) async {
    await getIt<OfflineTransactionSyncService>().flushIfOnline();
    if (!context.mounted) return;
    loadAll(context);
  }

  /// Reloads transaction tabs after background SMS auto-import.
  static void refreshAfterAutoImport(BuildContext context) {
    if (!SupabaseAuthHelper.isSignedIn) return;
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent(force: true));
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent(force: true));
  }

  /// Reloads all tabs after the display currency changes.
  static void refreshForDisplayCurrency(BuildContext context) {
    if (!SupabaseAuthHelper.isSignedIn) return;
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent(force: true));
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent(force: true));
    final dateFilter = getIt<HomeDateFilter>();
    final budgetPeriod = BudgetPeriod.fromDateFilter(dateFilter);
    context.read<BudgetsBloc>().add(
          LoadBudgetsEvent(
            year: budgetPeriod.year,
            month: budgetPeriod.month,
            force: true,
          ),
        );
    context.read<PlansTabBloc>().add(const LoadPlansEvent(force: true));
    context.read<LoansTabBloc>().add(const LoadLoansEvent(force: true));
  }
}
