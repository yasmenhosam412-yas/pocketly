import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:imrpo/core/config/app_router.dart';
import 'package:imrpo/core/widgets/shared_text_import_gate.dart';
import 'package:imrpo/core/widgets/app_lock_gate.dart';
import 'package:imrpo/core/bootstrap/app_startup.dart';
import 'package:imrpo/core/widgets/bill_reminder_gate.dart';
import 'package:imrpo/core/services/pocketly_home_widget.dart';
import 'package:imrpo/core/services/firebase_notification_service.dart';
import 'package:imrpo/features/bill_reminders/presentation/bloc/bill_reminders_bloc.dart';
import 'package:imrpo/features/recurring_transactions/presentation/bloc/recurring_transactions_bloc.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/theme_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/theme/app_theme.dart';
import 'package:imrpo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:imrpo/features/balance_tab/presentation/bloc/balance_tab_bloc.dart';
import 'package:imrpo/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/home/presentation/bloc/home_bloc.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
import 'package:imrpo/features/loans_tab/presentation/bloc/loans_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:imrpo/core/widgets/upgrade_alert_when_ready.dart';
import 'package:imrpo/firebase_options.dart';
import 'package:app_upgrader_flutter/app_upgrader_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e, st) {
    debugPrint('Firebase init skipped: $e\n$st');
  }

  final supabaseReady = _initializeSupabase();
  setupServiceLocator();
  await loadCriticalAppStartup();
  getIt<ThemePreferences>().updatePlatformBrightness(
    WidgetsBinding.instance.platformDispatcher.platformBrightness,
  );

  runApp(MainApp(supabaseReady: supabaseReady));
}

Future<void> _initializeSupabase() {
  return Supabase.initialize(
    url: 'https://xtilikvogevzshsliwzp.supabase.co',
    anonKey: 'sb_publishable_hhAelFYJErvvdq9_HAkHgw_bwLBSG1K',
    authOptions: const FlutterAuthClientOptions(detectSessionInUri: true),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.supabaseReady});

  final Future<void> supabaseReady;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  Upgrader? _upgrader;
  String? _upgraderLanguage;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_finishStartup());
  }

  Future<void> _finishStartup() async {
    await widget.supabaseReady;
    if (!mounted) return;
    setState(() => _ready = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(runDeferredAppStartup());
    });
  }

  Upgrader _createUpgrader(String languageCode) {
    _upgraderLanguage = languageCode;
    return createPocketlyUpgrader(languageCode: languageCode);
  }

  Upgrader _upgraderFor(String languageCode) {
    if (_upgrader == null || _upgraderLanguage != languageCode) {
      _upgrader = _createUpgrader(languageCode);
    }
    return _upgrader!;
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

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const _StartupSplash();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(create: (_) => getIt<HomeBloc>()),
        BlocProvider(create: (_) => getIt<IncomesTabBloc>()),
        BlocProvider(create: (_) => getIt<BalanceTabBloc>()),
        BlocProvider(create: (_) => getIt<ExpensesTabBloc>()),
        BlocProvider(create: (_) => getIt<BudgetsBloc>()),
        BlocProvider(create: (_) => getIt<PlansTabBloc>()),
        BlocProvider(create: (_) => getIt<LoansTabBloc>()),
        BlocProvider(create: (_) => getIt<BillRemindersBloc>()),
        BlocProvider(create: (_) => getIt<RecurringTransactionsBloc>()),
      ],
      child: ListenableBuilder(
        listenable: Listenable.merge([
          getIt<LocalePreferences>(),
          getIt<ThemePreferences>(),
        ]),
        builder: (context, _) {
          final locale = getIt<LocalePreferences>().locale;
          final themePrefs = getIt<ThemePreferences>();
          final isDark = themePrefs.isDark;
          final theme = AppTheme.of(isDark: isDark);

          return MaterialApp(
            title: "Pocketly",
            navigatorKey: rootNavigatorKey,
            locale: locale,
            onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
            theme: theme,
            darkTheme: theme,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            onGenerateRoute: AppRouter.generateRoute,
            onGenerateInitialRoutes: (_) {
              return [
                AppRouter.generateRoute(RouteSettings(name: AppLaunch.routeName)),
              ];
            },
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
                child: UpgradeAlertWhenReady(
                  key: ValueKey('upgrade-${locale.languageCode}'),
                  navigatorKey: rootNavigatorKey,
                  appUpgrader: _upgraderFor(locale.languageCode),
                  child: AppLockGate(
                    child: SharedTextImportGate(
                      child: BillReminderGate(
                        child: HomeWidgetSyncGate(child: child!),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  static const _background = Color(0xFFF7F3EF);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _background,
      ),
      home: const Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Image(
            image: AssetImage('assets/wallet.png'),
            width: 192,
            height: 192,
          ),
        ),
      ),
    );
  }
}
