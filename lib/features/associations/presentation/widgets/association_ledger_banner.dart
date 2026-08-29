import 'package:flutter/material.dart';
import 'package:imrpo/core/helpers/association_ledger_access.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Context chip for family / treasurer / view-only shared ledgers.
class AssociationLedgerBanner extends StatelessWidget {
  const AssociationLedgerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: getIt<AssociationContext>(),
      builder: (context, _) {
        final item = AssociationLedgerAccess.activeItem;
        if (item == null || item.isPersonal) return const SizedBox.shrink();

        final String message;
        final IconData icon;
        final Color tint;
        if (item.isFamily) {
          message = l10n.associationFamilyBanner;
          icon = Icons.groups_rounded;
          tint = AppColors.primary;
        } else if (item.isTreasurer) {
          message = l10n.associationTreasurerBannerBody(item.name);
          icon = Icons.manage_accounts_outlined;
          tint = AppColors.primary;
        } else if (item.isMemberViewOnly) {
          message = l10n.associationMemberReadOnlyBanner(item.name);
          icon = Icons.visibility_outlined;
          tint = AppColors.textMuted;
        } else {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Material(
            color: tint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, color: tint, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
