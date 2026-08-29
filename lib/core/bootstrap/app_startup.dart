import 'dart:async';

import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/services/app_lock_service.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/auto_sms_import_preferences.dart';
import 'package:imrpo/core/services/bill_reminder_bootstrap.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/daily_digest_bootstrap.dart';
import 'package:imrpo/core/services/expense_shortcuts_store.dart';
import 'package:imrpo/core/services/notification_inbox_store.dart';
import 'package:imrpo/core/services/notification_inbox_sync_service.dart';
import 'package:imrpo/core/services/initial_balance_store.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/offline_transaction_store.dart';
import 'package:imrpo/core/services/offline_transaction_sync_service.dart';
import 'package:imrpo/core/services/onboarding_preferences.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/share_text_import_bridge.dart';
import 'package:imrpo/core/services/sms_imported_registry.dart';
import 'package:imrpo/core/services/theme_preferences.dart';
import 'package:imrpo/core/utils/locale_date_format.dart';

/// Route, theme, locale, and lock — must finish before [runApp].
Future<void> loadCriticalAppStartup() {
  return Future.wait([
    getIt<LocalePreferences>().load(),
    getIt<ThemePreferences>().load(),
    getIt<OnboardingPreferences>().load(),
    getIt<AppLockService>().load(),
  ]);
}

/// Disk/network work that must not block the first frame.
Future<void> runDeferredAppStartup() async {
  unawaited(LocaleDateFormat.ensureAppLocales());
  unawaited(ShareTextImportBridge.instance.startListening());

  await Future.wait([
    getIt<CurrencyPreferences>().load(),
    getIt<ExpenseShortcutsStore>().load(),
    getIt<PaymentMethodsStore>().load(),
    getIt<SmsImportedRegistry>().load(),
    getIt<AutoSmsImportPreferences>().load(),
    getIt<NotificationInboxStore>().load(),
  ]);

  await bootstrapBillReminders();

  if (!SupabaseAuthHelper.isSignedIn) {
    await bootstrapDailyDigest();
    return;
  }

  await getIt<AssociationContext>().load();
  await getIt<OfflineTransactionStore>().load();
  await getIt<InitialBalanceStore>().load();

  final offline = getIt<AssociationContext>().isOffline;
  if (!offline) {
    await getIt<OfflineTransactionSyncService>().flushIfOnline();
    await getIt<NotificationInboxSyncService>().syncDelivered();
    await bootstrapDailyDigest();
  }
}
