import 'package:flutter/material.dart';
import 'package:imrpo/core/helpers/association_ledger_access.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/association_member_names.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Who recorded a row — only on family ledgers.
class FamilyAuthorMeta extends StatefulWidget {
  const FamilyAuthorMeta({
    super.key,
    required this.userId,
    this.style,
    this.iconColor,
  });

  final String? userId;
  final TextStyle? style;
  final Color? iconColor;

  @override
  State<FamilyAuthorMeta> createState() => _FamilyAuthorMetaState();
}

class _FamilyAuthorMetaState extends State<FamilyAuthorMeta> {
  @override
  void initState() {
    super.initState();
    getIt<AssociationMemberNames>().ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        getIt<AssociationContext>(),
        getIt<AssociationMemberNames>(),
      ]),
      builder: (context, _) {
        if (!AssociationLedgerAccess.isFamily) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context)!;
        final label = getIt<AssociationMemberNames>().label(
          widget.userId,
          l10n,
        );
        final metaStyle =
            widget.style ??
            TextStyle(
              fontSize: 12.5,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: AppColors.textColor.withValues(alpha: 0.55),
            );
        final iconColor =
            widget.iconColor ?? AppColors.textColor.withValues(alpha: 0.45);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.familyTransactionBy(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
