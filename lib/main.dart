import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/config/app_router.dart';
import 'package:imrpo/core/services/app_lock_service.dart';
import 'package:imrpo/core/services/auto_sms_import_preferences.dart';
import 'package:imrpo/core/widgets/auto_sms_import_gate.dart';
import 'package:imrpo/core/widgets/shared_text_import_gate.dart';
import 'package:imrpo/core/services/share_text_import_bridge.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/expense_shortcuts_store.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/widgets/app_lock_gate.dart';
import 'package:imrpo/core/bootstrap/app_startup.dart';
import 'package:imrpo/core/services/bill_reminder_preferences.dart';
import 'package:imrpo/core/services/daily_digest_preferences.dart';
import 'package:imrpo/core/services/notification_inbox_store.dart';
import 'package:imrpo/core/utils/locale_date_format.dart';
import 'package:imrpo/core/widgets/bill_reminder_gate.dart';
import 'package:imrpo/features/bill_reminders/presentation/bloc/bill_reminders_bloc.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/theme_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/sms_imported_registry.dart';
import 'package:imrpo/core/theme/app_theme.dart';
import 'package:imrpo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:imrpo/features/auth/presentation/pages/login_screen.dart';
import 'package:imrpo/features/balance_tab/presentation/bloc/balance_tab_bloc.dart';
import 'package:imrpo/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/core/services/onboarding_preferences.dart';
import 'package:imrpo/features/home/presentation/pages/home_screen.dart';
import 'package:imrpo/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/home/presentation/bloc/home_bloc.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:upgrader/upgrader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);

  await Supabase.initialize(
    url: 'https://xtilikvogevzshsliwzp.supabase.co',
    anonKey: 'sb_publishable_hhAelFYJErvvdq9_HAkHgw_bwLBSG1K',
  );
  setupServiceLocator();
  await getIt<CurrencyPreferences>().load();
  await getIt<LocalePreferences>().load();
  await getIt<ThemePreferences>().load();
  getIt<ThemePreferences>().updatePlatformBrightness(
    WidgetsBinding.instance.platformDispatcher.platformBrightness,
  );
  await LocaleDateFormat.ensureAppLocales();
  await getIt<ExpenseShortcutsStore>().load();
  await getIt<PaymentMethodsStore>().load();
  await getIt<SmsImportedRegistry>().load();
  await getIt<AutoSmsImportPreferences>().load();
  await getIt<BillReminderPreferences>().load();
  await getIt<DailyDigestPreferences>().load();
  await getIt<NotificationInboxStore>().load();
  await getIt<OnboardingPreferences>().load();
  await getIt<AppLockService>().load();
  await ShareTextImportBridge.instance.startListening();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(create: (_) => getIt<HomeBloc>()),
        BlocProvider(create: (_) => getIt<IncomesTabBloc>()),
        BlocProvider(create: (_) => getIt<BalanceTabBloc>()),
        BlocProvider(create: (_) => getIt<ExpensesTabBloc>()),
        BlocProvider(create: (_) => getIt<BudgetsBloc>()),
        BlocProvider(create: (_) => getIt<PlansTabBloc>()),
        BlocProvider.value(value: getIt<BillRemindersBloc>()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  late Upgrader _upgrader;
  late String _upgraderLanguage;

  @override
  void initState() {
    super.initState();
    _upgrader = _createUpgrader(
      getIt<LocalePreferences>().locale.languageCode,
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runDeferredAppStartup();
    });
  }

  Upgrader _createUpgrader(String languageCode) {
    _upgraderLanguage = languageCode;
    return Upgrader(
      languageCode: languageCode,
      countryCode: 'EG',
      messages: UpgraderMessages(code: languageCode),
    );
  }

  Upgrader _upgraderFor(String languageCode) {
    if (_upgraderLanguage != languageCode) {
      _upgrader = _createUpgrader(languageCode);
    }
    return _upgrader;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    getIt<ThemePreferences>().updatePlatformBrightness(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  String _initialRoute() {
    if (!getIt<OnboardingPreferences>().completed) {
      return AppRoutes.onboarding;
    }
    return getIt<SupabaseClient>().auth.currentUser != null
        ? AppRoutes.home
        : AppRoutes.login;
  }

  Widget _initialHome() {
    if (!getIt<OnboardingPreferences>().completed) {
      return const OnboardingScreen();
    }
    return getIt<SupabaseClient>().auth.currentUser != null
        ? const HomeScreen()
        : const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        getIt<LocalePreferences>(),
        getIt<ThemePreferences>(),
      ]),
      builder: (context, _) {
        final locale = getIt<LocalePreferences>().locale;
        final themePrefs = getIt<ThemePreferences>();

        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          locale: locale,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themePrefs.themeMode,
          debugShowCheckedModeBanner: false,
          initialRoute: _initialRoute(),
          onGenerateRoute: AppRouter.generateRoute,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: UpgradeAlert(
                key: ValueKey(_upgraderLanguage),
                navigatorKey: rootNavigatorKey,
                upgrader: _upgraderFor(locale.languageCode),
                child: AppLockGate(
                  child: SharedTextImportGate(
                    child: AutoSmsImportGate(
                      child: BillReminderGate(child: child!),
                    ),
                  ),
                ),
              ),
            );
          },
          home: _initialHome(),
        );
      },
    );
  }
}
