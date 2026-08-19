import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/bill_reminder_bootstrap.dart';
import 'package:imrpo/core/services/daily_digest_bootstrap.dart';
import 'package:imrpo/core/services/notification_inbox_sync_service.dart';
import 'package:imrpo/core/services/initial_balance_store.dart';
import 'package:imrpo/core/services/offline_transaction_store.dart';
import 'package:imrpo/core/services/offline_transaction_sync_service.dart';
import 'package:imrpo/core/services/service_locator.dart';

/// Network/heavy startup work — run after [runApp] so the UI is not blocked.
Future<void> runDeferredAppStartup() async {
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
