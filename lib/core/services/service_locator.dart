import 'package:get_it/get_it.dart';
import 'package:imrpo/core/services/app_lock_service.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/bill_reminder_preferences.dart';
import 'package:imrpo/core/services/daily_digest_preferences.dart';
import 'package:imrpo/core/services/notification_inbox_store.dart';
import 'package:imrpo/core/services/notification_inbox_sync_service.dart';
import 'package:imrpo/core/services/offline_transaction_store.dart';
import 'package:imrpo/core/services/offline_transaction_sync_service.dart';
import 'package:imrpo/core/services/auto_sms_import_preferences.dart';
import 'package:imrpo/features/bill_reminders/data/bill_reminder_store.dart';
import 'package:imrpo/features/bill_reminders/data/repositories/bill_reminder_repository_impl.dart';
import 'package:imrpo/features/bill_reminders/domain/repositories/bill_reminder_repository.dart';
import 'package:imrpo/features/bill_reminders/presentation/bloc/bill_reminders_bloc.dart';
import 'package:imrpo/core/services/auto_sms_import_service.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/receipt_storage_service.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/initial_balance_store.dart';
import 'package:imrpo/core/services/expense_shortcuts_store.dart';
import 'package:imrpo/core/services/smart_import_draft_store.dart';
import 'package:imrpo/core/services/shared_text_import_store.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/theme_preferences.dart';
import 'package:imrpo/core/services/association_invite_disclaimer_prefs.dart';
import 'package:imrpo/core/services/onboarding_preferences.dart';
import 'package:imrpo/core/services/sms_bulk_import_service.dart';
import 'package:imrpo/core/services/sms_import_service.dart';
import 'package:imrpo/core/services/sms_imported_registry.dart';
import 'package:imrpo/features/auth/data/datasources/auth_datasource.dart';
import 'package:imrpo/features/auth/data/datasources/auth_datasource_impl.dart';
import 'package:imrpo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:imrpo/features/auth/domain/repositories/auth_repository.dart';
import 'package:imrpo/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:imrpo/features/auth/domain/usecases/forget_password_usecase.dart';
import 'package:imrpo/features/auth/domain/usecases/login_usecase.dart';
import 'package:imrpo/features/auth/domain/usecases/logout_usecase.dart';
import 'package:imrpo/features/auth/domain/usecases/signup_usecase.dart';
import 'package:imrpo/features/auth/domain/usecases/verify_set_new_pass_usecase.dart';
import 'package:imrpo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:imrpo/features/balance_tab/data/repositories/balance_repository_impl.dart';
import 'package:imrpo/features/balance_tab/domain/repositories/balance_repository.dart';
import 'package:imrpo/features/balance_tab/domain/usecases/get_balance_usecase.dart';
import 'package:imrpo/features/budgets/data/datasources/budget_datasource.dart';
import 'package:imrpo/features/budgets/data/datasources/budget_datasource_impl.dart';
import 'package:imrpo/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:imrpo/features/budgets/domain/repositories/budget_repository.dart';
import 'package:imrpo/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'package:imrpo/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:imrpo/features/budgets/domain/usecases/upsert_budget_usecase.dart';
import 'package:imrpo/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:imrpo/features/balance_tab/presentation/bloc/balance_tab_bloc.dart';
import 'package:imrpo/features/expenses_tab/data/datasources/expenses_datasource.dart';
import 'package:imrpo/features/expenses_tab/data/datasources/expenses_datasource_impl.dart';
import 'package:imrpo/features/expenses_tab/data/repositories/expense_repositroy_impl.dart';
import 'package:imrpo/features/expenses_tab/domain/repositories/expense_repository.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/add_expense_usecase.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/delete_all_expenses_usecase.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/delete_expense_usecase.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/delete_expenses_by_category_usecase.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/get_all_expenses_usecase.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/rename_expense_category_usecase.dart';
import 'package:imrpo/features/expenses_tab/domain/usecases/update_expense_usecase.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/data/datasources/income_datasource.dart';
import 'package:imrpo/features/incomes_tab/data/datasources/income_datasource_impl.dart';
import 'package:imrpo/features/incomes_tab/data/repositories/income_repository_impl.dart';
import 'package:imrpo/features/incomes_tab/domain/repositories/income_repository.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/add_income_usecase.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/delete_all_incomes_usecase.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/delete_income_usecase.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/delete_incomes_by_source_usecase.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/get_all_incomes_usecase.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/rename_income_source_usecase.dart';
import 'package:imrpo/features/incomes_tab/domain/usecases/update_income_usecase.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/plans_tab/data/datasources/plans_datasource.dart';
import 'package:imrpo/features/plans_tab/data/datasources/plans_datasource_impl.dart';
import 'package:imrpo/features/plans_tab/data/repositories/plan_repository_impl.dart';
import 'package:imrpo/features/plans_tab/domain/repositories/plan_repository.dart';
import 'package:imrpo/features/plans_tab/domain/usecases/add_plan_usecase.dart';
import 'package:imrpo/features/plans_tab/domain/usecases/delete_plan_usecase.dart';
import 'package:imrpo/features/plans_tab/domain/usecases/get_all_plans_usecase.dart';
import 'package:imrpo/features/plans_tab/domain/usecases/update_plan_saved_usecase.dart';
import 'package:imrpo/features/plans_tab/domain/usecases/update_plan_usecase.dart';
import 'package:imrpo/features/home/data/datasources/home_datasource.dart';
import 'package:imrpo/features/home/data/datasources/home_datasource_impl.dart';
import 'package:imrpo/features/home/data/repositories/home_repository_impl.dart';
import 'package:imrpo/features/home/domain/repositories/home_repository.dart';
import 'package:imrpo/features/home/domain/usecases/get_user_profile_usecase.dart';
import 'package:imrpo/features/home/domain/usecases/update_username_usecase.dart';
import 'package:imrpo/features/home/presentation/bloc/home_bloc.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  /// Supabase Client
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  getIt.registerLazySingleton<ReceiptStorageService>(
    () => ReceiptStorageService(client: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<AppLockService>(() => AppLockService());

  getIt.registerLazySingleton<CurrencyPreferences>(() => CurrencyPreferences());

  getIt.registerLazySingleton<LocalePreferences>(() => LocalePreferences());

  getIt.registerLazySingleton<ThemePreferences>(() => ThemePreferences());

  getIt.registerLazySingleton<OnboardingPreferences>(
    () => OnboardingPreferences(),
  );

  getIt.registerLazySingleton<AssociationInviteDisclaimerPrefs>(
    () => AssociationInviteDisclaimerPrefs(),
  );

  getIt.registerLazySingleton<HomeDateFilter>(() => HomeDateFilter());

  getIt.registerLazySingleton<AssociationContext>(
    () => AssociationContext(client: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<OfflineTransactionStore>(
    () => OfflineTransactionStore(),
  );

  getIt.registerLazySingleton<InitialBalanceStore>(
    () => InitialBalanceStore(),
  );

  getIt.registerLazySingleton<OfflineTransactionSyncService>(
    () => OfflineTransactionSyncService(),
  );

  getIt.registerLazySingleton<SmartImportDraftStore>(
    () => SmartImportDraftStore(),
  );
  getIt.registerLazySingleton<SharedTextImportStore>(
    () => SharedTextImportStore(),
  );
  getIt.registerLazySingleton<PaymentMethodsStore>(() => PaymentMethodsStore());
  getIt.registerLazySingleton<ExpenseShortcutsStore>(() => ExpenseShortcutsStore());
  getIt.registerLazySingleton<SmsImportService>(() => SmsImportService());

  getIt.registerLazySingleton<SmsImportedRegistry>(() => SmsImportedRegistry());

  getIt.registerLazySingleton<SmsBulkImportService>(
    () => SmsBulkImportService(
      addExpenseUsecase: getIt<AddExpenseUsecase>(),
      addIncomeUsecase: getIt<AddIncomeUsecase>(),
      importedRegistry: getIt<SmsImportedRegistry>(),
    ),
  );

  getIt.registerLazySingleton<AutoSmsImportPreferences>(
    () => AutoSmsImportPreferences(),
  );

  getIt.registerLazySingleton<BillReminderPreferences>(
    () => BillReminderPreferences(),
  );

  getIt.registerLazySingleton<DailyDigestPreferences>(
    () => DailyDigestPreferences(),
  );

  getIt.registerLazySingleton<NotificationInboxStore>(
    () => NotificationInboxStore(),
  );

  getIt.registerLazySingleton<NotificationInboxSyncService>(
    () => NotificationInboxSyncService(),
  );

  getIt.registerLazySingleton<BillReminderStore>(() => BillReminderStore());

  getIt.registerLazySingleton<BillReminderRepository>(
    () => BillReminderRepositoryImpl(store: getIt<BillReminderStore>()),
  );

  getIt.registerLazySingleton<BillRemindersBloc>(
    () => BillRemindersBloc(repository: getIt<BillReminderRepository>()),
  );

  getIt.registerLazySingleton<AutoSmsImportService>(
    () => AutoSmsImportService(
      preferences: getIt<AutoSmsImportPreferences>(),
      smsImport: getIt<SmsImportService>(),
      bulkImport: getIt<SmsBulkImportService>(),
      appLock: getIt<AppLockService>(),
    ),
  );

  /// Datasource
  getIt.registerLazySingleton<AuthDatasource>(
    () => AuthDatasourceImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  /// Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(authDatasource: getIt<AuthDatasource>()),
  );

  /// Usecases
  getIt.registerLazySingleton<LoginUsecase>(
    () => LoginUsecase(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<SignupUsecase>(
    () => SignupUsecase(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<ForgetPasswordUsecase>(
    () => ForgetPasswordUsecase(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton<VerifySetNewPassUsecase>(
    () => VerifySetNewPassUsecase(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton(
    () => LogoutUsecase(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton(
    () => DeleteAccountUsecase(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUsecase: getIt<LoginUsecase>(),
      signupUsecase: getIt<SignupUsecase>(),
      forgetPasswordUsecase: getIt<ForgetPasswordUsecase>(),
      verifySetNewPassUsecase: getIt<VerifySetNewPassUsecase>(),
      logoutUsecase: getIt<LogoutUsecase>(),
      deleteAccountUsecase: getIt<DeleteAccountUsecase>(),
    ),
  );

  //---------------------INCOMES-------------------------------------

  getIt.registerLazySingleton<IncomeDatasource>(
    () => IncomeDatasourceImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<IncomeRepository>(
    () => IncomeRepositoryImpl(incomeDatasource: getIt<IncomeDatasource>()),
  );

  getIt.registerLazySingleton(
    () => AddIncomeUsecase(incomeRepository: getIt<IncomeRepository>()),
  );

  getIt.registerLazySingleton(
    () => DeleteIncomeUsecase(incomeRepository: getIt<IncomeRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteAllIncomesUsecase(incomeRepository: getIt<IncomeRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpdateIncomeUsecase(incomeRepository: getIt<IncomeRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetAllIncomesUsecase(incomeRepository: getIt<IncomeRepository>()),
  );

  getIt.registerLazySingleton(
    () => RenameIncomeSourceUsecase(incomeRepository: getIt<IncomeRepository>()),
  );

  getIt.registerLazySingleton(
    () => DeleteIncomesBySourceUsecase(
      incomeRepository: getIt<IncomeRepository>(),
    ),
  );

  getIt.registerFactory<IncomesTabBloc>(
    () => IncomesTabBloc(
      addIncomeUsecase: getIt<AddIncomeUsecase>(),
      updateIncomeUsecase: getIt<UpdateIncomeUsecase>(),
      deleteIncomeUsecase: getIt<DeleteIncomeUsecase>(),
      deleteAllIncomesUsecase: getIt<DeleteAllIncomesUsecase>(),
      getAllIncomesUsecase: getIt<GetAllIncomesUsecase>(),
      renameIncomeSourceUsecase: getIt<RenameIncomeSourceUsecase>(),
      deleteIncomesBySourceUsecase: getIt<DeleteIncomesBySourceUsecase>(),
    ),
  );

  /// ------------------------------expenses-------------------------
  getIt.registerLazySingleton<ExpensesDatasource>(
    () => ExpensesDatasourceImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositroyImpl(
      expensesDatasource: getIt<ExpensesDatasource>(),
      budgetDatasource: getIt<BudgetDatasource>(),
    ),
  );

  getIt.registerLazySingleton(
    () => AddExpenseUsecase(expenseRepository: getIt<ExpenseRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteExpenseUsecase(expenseRepository: getIt<ExpenseRepository>()),
  );
  getIt.registerLazySingleton(
    () => DeleteAllExpensesUsecase(expenseRepository: getIt<ExpenseRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpdateExpenseUsecase(expenseRepository: getIt<ExpenseRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetAllExpensesUsecase(expenseRepository: getIt<ExpenseRepository>()),
  );

  getIt.registerLazySingleton(
    () => RenameExpenseCategoryUsecase(
      expenseRepository: getIt<ExpenseRepository>(),
    ),
  );

  getIt.registerLazySingleton(
    () => DeleteExpensesByCategoryUsecase(
      expenseRepository: getIt<ExpenseRepository>(),
    ),
  );

  getIt.registerFactory<ExpensesTabBloc>(
    () => ExpensesTabBloc(
      addExpenseUsecase: getIt<AddExpenseUsecase>(),
      updateExpenseUsecase: getIt<UpdateExpenseUsecase>(),
      deleteExpenseUsecase: getIt<DeleteExpenseUsecase>(),
      deleteAllExpensesUsecase: getIt<DeleteAllExpensesUsecase>(),
      getAllExpensesUsecase: getIt<GetAllExpensesUsecase>(),
      renameExpenseCategoryUsecase: getIt<RenameExpenseCategoryUsecase>(),
      deleteExpensesByCategoryUsecase: getIt<DeleteExpensesByCategoryUsecase>(),
    ),
  );

  //--------------------------BUDGETS--------------------------

  getIt.registerLazySingleton<BudgetDatasource>(
    () => BudgetDatasourceImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(budgetDatasource: getIt<BudgetDatasource>()),
  );

  getIt.registerLazySingleton(
    () => GetBudgetsUsecase(budgetRepository: getIt<BudgetRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpsertBudgetUsecase(budgetRepository: getIt<BudgetRepository>()),
  );

  getIt.registerLazySingleton(
    () => DeleteBudgetUsecase(budgetRepository: getIt<BudgetRepository>()),
  );

  getIt.registerFactory<BudgetsBloc>(
    () => BudgetsBloc(
      getBudgetsUsecase: getIt<GetBudgetsUsecase>(),
      upsertBudgetUsecase: getIt<UpsertBudgetUsecase>(),
      deleteBudgetUsecase: getIt<DeleteBudgetUsecase>(),
    ),
  );

  //--------------------------BALANCE--------------------------

  getIt.registerLazySingleton<BalanceRepository>(
    () => BalanceRepositoryImpl(
      incomeRepository: getIt<IncomeRepository>(),
      expenseRepository: getIt<ExpenseRepository>(),
    ),
  );

  getIt.registerLazySingleton(
    () => GetBalanceUsecase(balanceRepository: getIt<BalanceRepository>()),
  );

  getIt.registerFactory<BalanceTabBloc>(
    () => BalanceTabBloc(getBalanceUsecase: getIt<GetBalanceUsecase>()),
  );
  //--------------------------PLANS--------------------------

  getIt.registerLazySingleton<PlansDatasource>(
    () => PlansDatasourceImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<PlanRepository>(
    () => PlanRepositoryImpl(plansDatasource: getIt<PlansDatasource>()),
  );

  getIt.registerLazySingleton(
    () => AddPlanUsecase(planRepository: getIt<PlanRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpdatePlanUsecase(planRepository: getIt<PlanRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpdatePlanSavedUsecase(planRepository: getIt<PlanRepository>()),
  );

  getIt.registerLazySingleton(
    () => DeletePlanUsecase(planRepository: getIt<PlanRepository>()),
  );

  getIt.registerLazySingleton(
    () => GetAllPlansUsecase(planRepository: getIt<PlanRepository>()),
  );

  getIt.registerFactory<PlansTabBloc>(
    () => PlansTabBloc(
      getAllPlansUsecase: getIt<GetAllPlansUsecase>(),
      addPlanUsecase: getIt<AddPlanUsecase>(),
      updatePlanUsecase: getIt<UpdatePlanUsecase>(),
      updatePlanSavedUsecase: getIt<UpdatePlanSavedUsecase>(),
      deletePlanUsecase: getIt<DeletePlanUsecase>(),
      addExpenseUsecase: getIt<AddExpenseUsecase>(),
    ),
  );

  //--------------------------HOME--------------------------

  getIt.registerLazySingleton<HomeDatasource>(
    () => HomeDatasourceImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(homeDatasource: getIt<HomeDatasource>()),
  );

  getIt.registerLazySingleton(
    () => GetUserProfileUsecase(homeRepository: getIt<HomeRepository>()),
  );

  getIt.registerLazySingleton(
    () => UpdateUsernameUsecase(homeRepository: getIt<HomeRepository>()),
  );

  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(
      getUserProfileUsecase: getIt<GetUserProfileUsecase>(),
      updateUsernameUsecase: getIt<UpdateUsernameUsecase>(),
    ),
  );
}
