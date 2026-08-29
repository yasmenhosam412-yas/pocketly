import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/initial_balance_store.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/balance_tab/domain/services/balance_summary_builder.dart';
import 'package:imrpo/features/expenses_tab/data/models/expense_model.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/data/models/income_model.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Android home-screen widget: net balance + today's expenses.
class PocketlyHomeWidget {
  PocketlyHomeWidget._();

  static const androidName = 'PocketlyHomeWidgetProvider';
  static const qualifiedAndroidName =
      'com.yasmen.pocketly.PocketlyHomeWidgetProvider';
  static const quickAndroidName = 'PocketlyQuickExpenseWidgetProvider';
  static const quickQualifiedAndroidName =
      'com.yasmen.pocketly.PocketlyQuickExpenseWidgetProvider';

  static const addExpenseUri = 'pocketly://widget/add-expense';

  static const keyTitle = 'hw_title';
  static const keyBalanceLabel = 'hw_balance_label';
  static const keyBalanceValue = 'hw_balance_value';
  static const keyTodayLabel = 'hw_today_label';
  static const keyTodayValue = 'hw_today_value';
  static const keyTodayDate = 'hw_today_date';
  static const keyTodayZero = 'hw_today_zero';
  static const keyRtl = 'hw_rtl';
  static const keyHasData = 'hw_has_data';
  static const keyAddExpense = 'hw_add_expense';
  static const keyQuickTitle = 'hw_quick_title';

  /// Set when the launcher widget asks to open the add-expense sheet.
  static final ValueNotifier<bool> addExpenseLaunch = ValueNotifier(false);

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static Future<void> syncFromBlocs({
    required List<IncomeModel> incomes,
    required List<ExpenseModel> expenses,
  }) async {
    if (!isAndroid) return;

    if (!SupabaseAuthHelper.isSignedIn) {
      await clear();
      return;
    }

    final now = DateTime.now();
    final l10n = lookupAppLocalizations(getIt<LocalePreferences>().locale);
    final month = BalanceSummaryBuilder.build(
      incomes: incomes,
      expenses: expenses,
      reference: now,
    );
    final today = BalanceSummaryBuilder.build(
      incomes: incomes,
      expenses: expenses,
      reference: now,
      filterByDay: true,
    );
    final initial = getIt<InitialBalanceStore>().amount;
    final net = initial + month.monthlyIncome - month.monthlyExpenses;
    final balance = net < 0 ? 0.0 : net;

    await _write(
      title: l10n.appTitle,
      balanceLabel: l10n.tabBalance,
      balanceValue: Money.format(balance),
      todayLabel: l10n.homeWidgetTodayExpenses,
      todayValue: Money.format(today.monthlyExpenses),
      todayZero: Money.format(0),
      todayDate: _dateKey(now),
      rtl: getIt<LocalePreferences>().locale.languageCode == 'ar',
      hasData: true,
      addExpenseLabel: l10n.addExpense,
      quickTitle: l10n.homeWidgetQuickName,
    );
  }

  static Future<void> clear() async {
    if (!isAndroid) return;
    final l10n = lookupAppLocalizations(getIt<LocalePreferences>().locale);
    await _write(
      title: l10n.appTitle,
      balanceLabel: l10n.tabBalance,
      balanceValue: '—',
      todayLabel: l10n.homeWidgetTodayExpenses,
      todayValue: '—',
      todayZero: Money.format(0),
      todayDate: _dateKey(DateTime.now()),
      rtl: getIt<LocalePreferences>().locale.languageCode == 'ar',
      hasData: false,
      addExpenseLabel: l10n.addExpense,
      quickTitle: l10n.homeWidgetQuickName,
    );
  }

  static Future<bool> requestPin({bool quickExpense = false}) async {
    if (!isAndroid) return false;
    final supported = await HomeWidget.isRequestPinWidgetSupported();
    if (supported != true) return false;
    await pinToHome(quickExpense: quickExpense);
    return true;
  }

  static Future<void> pinToHome({bool quickExpense = false}) {
    if (quickExpense) {
      return HomeWidget.requestPinWidget(
        name: quickAndroidName,
        androidName: quickAndroidName,
        qualifiedAndroidName: quickQualifiedAndroidName,
      );
    }
    return HomeWidget.requestPinWidget(
      name: androidName,
      androidName: androidName,
      qualifiedAndroidName: qualifiedAndroidName,
    );
  }

  static bool isAddExpenseLaunch(Uri? uri) {
    if (uri == null) return false;
    return uri.toString().contains('add-expense');
  }

  static void handleLaunch(Uri? uri) {
    if (!isAddExpenseLaunch(uri)) return;
    addExpenseLaunch.value = true;
  }

  static bool takeAddExpenseLaunch() {
    if (!addExpenseLaunch.value) return false;
    addExpenseLaunch.value = false;
    return true;
  }

  static Future<void> consumeInitialLaunch() async {
    if (!isAndroid) return;
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      handleLaunch(uri);
    } catch (error, stack) {
      debugPrint('Pocketly widget launch check failed: $error\n$stack');
    }
  }

  static String _dateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  static Future<void> _write({
    required String title,
    required String balanceLabel,
    required String balanceValue,
    required String todayLabel,
    required String todayValue,
    required String todayZero,
    required String todayDate,
    required bool rtl,
    required bool hasData,
    required String addExpenseLabel,
    required String quickTitle,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>(keyTitle, title);
      await HomeWidget.saveWidgetData<String>(keyBalanceLabel, balanceLabel);
      await HomeWidget.saveWidgetData<String>(keyBalanceValue, balanceValue);
      await HomeWidget.saveWidgetData<String>(keyTodayLabel, todayLabel);
      await HomeWidget.saveWidgetData<String>(keyTodayValue, todayValue);
      await HomeWidget.saveWidgetData<String>(keyTodayZero, todayZero);
      await HomeWidget.saveWidgetData<String>(keyTodayDate, todayDate);
      await HomeWidget.saveWidgetData<String>(keyRtl, rtl ? '1' : '0');
      await HomeWidget.saveWidgetData<String>(keyHasData, hasData ? '1' : '0');
      await HomeWidget.saveWidgetData<String>(keyAddExpense, addExpenseLabel);
      await HomeWidget.saveWidgetData<String>(keyQuickTitle, quickTitle);
      await HomeWidget.updateWidget(
        name: androidName,
        androidName: androidName,
        qualifiedAndroidName: qualifiedAndroidName,
      );
      await HomeWidget.updateWidget(
        name: quickAndroidName,
        androidName: quickAndroidName,
        qualifiedAndroidName: quickQualifiedAndroidName,
      );
    } catch (error, stack) {
      debugPrint('Pocketly home widget sync failed: $error\n$stack');
    }
  }
}

/// Keeps the launcher widget in sync with the signed-in ledger.
class HomeWidgetSyncGate extends StatefulWidget {
  final Widget child;

  const HomeWidgetSyncGate({super.key, required this.child});

  @override
  State<HomeWidgetSyncGate> createState() => _HomeWidgetSyncGateState();
}

class _HomeWidgetSyncGateState extends State<HomeWidgetSyncGate>
    with WidgetsBindingObserver {
  Timer? _debounce;
  StreamSubscription<Uri?>? _clicks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getIt<InitialBalanceStore>().addListener(_schedule);
    getIt<LocalePreferences>().addListener(_schedule);
    getIt<CurrencyPreferences>().addListener(_schedule);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _schedule();
      unawaited(PocketlyHomeWidget.consumeInitialLaunch());
    });
    if (PocketlyHomeWidget.isAndroid) {
      _clicks = HomeWidget.widgetClicked.listen(PocketlyHomeWidget.handleLaunch);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_clicks?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    getIt<InitialBalanceStore>().removeListener(_schedule);
    getIt<LocalePreferences>().removeListener(_schedule);
    getIt<CurrencyPreferences>().removeListener(_schedule);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _schedule();
    }
  }

  void _schedule() {
    if (!PocketlyHomeWidget.isAndroid) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _sync);
  }

  void _sync() {
    if (!mounted) return;
    final incomes = context.read<IncomesTabBloc>().state;
    final expenses = context.read<ExpensesTabBloc>().state;
    if (incomes.status == IncomesTabStatus.initial &&
        expenses.status == ExpensesTabStatus.initial) {
      return;
    }
    unawaited(
      PocketlyHomeWidget.syncFromBlocs(
        incomes: incomes.incomes,
        expenses: expenses.expenses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IncomesTabBloc, IncomesTabState>(
      listener: (_, _) => _schedule(),
      child: BlocListener<ExpensesTabBloc, ExpensesTabState>(
        listener: (_, _) => _schedule(),
        child: widget.child,
      ),
    );
  }
}
