import 'package:flutter/material.dart';
import 'package:imrpo/core/config/oauth_config.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/services/onboarding_preferences.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:imrpo/features/auth/presentation/pages/forget_password_screen.dart';
import 'package:imrpo/features/auth/presentation/pages/login_screen.dart';
import 'package:imrpo/features/auth/presentation/pages/oauth_callback_screen.dart';
import 'package:imrpo/features/auth/presentation/pages/set_new_passwod_screen.dart';
import 'package:imrpo/features/auth/presentation/pages/signup_screen.dart';
import 'package:imrpo/features/home/presentation/pages/calculator_screen.dart';
import 'package:imrpo/features/home/presentation/pages/home_screen.dart';
import 'package:imrpo/features/monthly_report/presentation/pages/monthly_report_screen.dart';
import 'package:imrpo/features/search/presentation/pages/global_search_screen.dart';
import 'package:imrpo/features/bill_reminders/presentation/pages/bill_reminders_screen.dart';
import 'package:imrpo/features/recurring_transactions/presentation/pages/recurring_transactions_screen.dart';
import 'package:imrpo/features/subscriptions/presentation/pages/subscriptions_screen.dart';
import 'package:imrpo/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:imrpo/features/smart_import/presentation/pages/smart_import_screen.dart';
import 'package:imrpo/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:imrpo/features/zakat/presentation/pages/zakat_screen.dart';
import 'package:imrpo/features/statistics_tab/presentation/pages/statistics_screen.dart';
import 'package:imrpo/features/year_in_review/presentation/pages/year_in_review_screen.dart';
import 'package:imrpo/features/association_invites/presentation/pages/invite_members_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/features/bill_reminders/presentation/bloc/bill_reminders_bloc.dart';
import 'package:imrpo/features/recurring_transactions/presentation/bloc/recurring_transactions_bloc.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/loans_tab/presentation/bloc/loans_tab_bloc.dart';

export 'package:imrpo/core/config/root_navigator.dart';

class AppRoutes {
  static const String home = '/home';
  static const String search = '/search';
  static const String smartImport = '/smart-import';
  static const String calculator = '/calculator';
  static const String monthlyReport = '/monthly-report';
  static const String billReminders = '/bill-reminders';
  static const String recurring = '/recurring';
  static const String subscriptions = '/subscriptions';
  static const String notifications = '/notifications';
  static const String zakat = '/zakat';
  static const String statistics = '/statistics';
  static const String yearInReview = '/year-in-review';
  static const String inviteMembers = '/invite-members';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgetPassword = '/forget-password';
  static const String verifyOtp = '/verify-otp';
}

class AppLaunch {
  static String get routeName {
    if (!getIt<OnboardingPreferences>().completed) {
      return AppRoutes.onboarding;
    }
    return SupabaseAuthHelper.isSignedIn ? AppRoutes.home : AppRoutes.login;
  }

  static Widget get screen {
    switch (routeName) {
      case AppRoutes.onboarding:
        return const OnboardingScreen();
      case AppRoutes.home:
        return const HomeScreen();
      default:
        return const LoginScreen();
    }
  }
}

class AppRouter {
  static MaterialPageRoute generateRoute(RouteSettings settings) {
    if (OAuthConfig.isCallbackRoute(settings.name)) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => OAuthCallbackScreen(routeName: settings.name),
      );
    }

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          settings: RouteSettings(name: AppLaunch.routeName),
          builder: (_) => AppLaunch.screen,
        );
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => AppLaunch.screen,
        );
      case AppRoutes.search:
        return MaterialPageRoute(builder: (_) => const GlobalSearchScreen());
      case AppRoutes.smartImport:
        return MaterialPageRoute(
          settings: const RouteSettings(name: AppRoutes.smartImport),
          builder: (_) => const SmartImportScreen(),
        );
      case AppRoutes.calculator:
        return MaterialPageRoute(builder: (_) => const CalculatorScreen());
      case AppRoutes.monthlyReport:
        return MaterialPageRoute(builder: (_) => const MonthlyReportScreen());
      case AppRoutes.billReminders:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<BillRemindersBloc>()..add(const LoadBillRemindersEvent()),
            child: const BillRemindersScreen(),
          ),
        );
      case AppRoutes.recurring:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<RecurringTransactionsBloc>()
              ..add(const LoadRecurringTransactionsEvent()),
            child: const RecurringTransactionsScreen(),
          ),
        );
      case AppRoutes.subscriptions:
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<RecurringTransactionsBloc>()
              ..add(const LoadRecurringTransactionsEvent()),
            child: const SubscriptionsScreen(),
          ),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case AppRoutes.zakat:
        return MaterialPageRoute(builder: (_) => const ZakatScreen());
      case AppRoutes.statistics:
        return MaterialPageRoute(builder: (_) => const StatisticsScreen());
      case AppRoutes.yearInReview:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: getIt<IncomesTabBloc>()),
              BlocProvider.value(value: getIt<ExpensesTabBloc>()),
              BlocProvider.value(value: getIt<LoansTabBloc>()),
            ],
            child: const YearInReviewScreen(),
          ),
        );
      case AppRoutes.inviteMembers:
        final args = settings.arguments as InviteMembersArgs;
        return MaterialPageRoute(
          settings: const RouteSettings(name: AppRoutes.inviteMembers),
          builder: (_) => InviteMembersScreen(
            associationId: args.associationId,
            associationName: args.associationName,
          ),
        );
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => SignupScreen());
      case AppRoutes.forgetPassword:
        return MaterialPageRoute(builder: (_) => ForgetPasswordScreen());
      case AppRoutes.verifyOtp:
        final email = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => SetNewPasswodScreen(email: email),
        );
      default:
        return MaterialPageRoute(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: Center(
                child: Text(l10n.noRouteForName(settings.name ?? '')),
              ),
            );
          },
        );
    }
  }
}
