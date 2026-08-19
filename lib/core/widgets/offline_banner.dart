import 'package:flutter/material.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/offline_transaction_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/session/user_session.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Shown below the home header when ledgers could not be loaded (no network).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: Listenable.merge([
        getIt<AssociationContext>(),
        getIt<OfflineTransactionStore>(),
      ]),
      builder: (context, _) {
        final ctx = getIt<AssociationContext>();
        if (!ctx.isOffline) return const SizedBox.shrink();
        final pending = getIt<OfflineTransactionStore>().pendingCount;
        final message = pending > 0
            ? l10n.offlineWithPendingTransactions(pending)
            : l10n.noInternetConnection;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Material(
            color: AppColors.errorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                await ctx.load(forceNetwork: true);
                if (!context.mounted) return;
                if (!ctx.isOffline) {
                  await UserSession.syncOfflineTransactionsAndReload(context);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: AppColors.errorColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.refresh_rounded,
                      color: AppColors.errorColor.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
