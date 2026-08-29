import 'package:flutter/material.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/smart_import/presentation/widgets/magic_add_panel.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class SmartImportAiTab extends StatelessWidget {
  final ScrollController scrollController;

  const SmartImportAiTab({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return MagicAddPanel(scrollController: scrollController);
  }
}

Future<String?> showMagicAddSheet(
  BuildContext context, {
  FinancialEntryType? preferredType,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.92;
      return AnimatedPadding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.magicAddTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: MagicAddPanel(
                  preferredType: preferredType,
                  popOnSuccess: true,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
