import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class SmartImportHeader extends StatelessWidget {
  final TabController tabController;

  const SmartImportHeader({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textColor,
              ),
              Expanded(
                child: Text(
                  l10n.smartImportTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: tabController,
                tabAlignment: TabAlignment.fill,
                indicator: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppDecorations.flatShadow(
                    color: AppColors.stroke,
                    offset: const Offset(0, 2),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.textColor,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                labelPadding: EdgeInsets.zero,
                tabs: [
                  _LabeledTab(
                    icon: Icons.auto_awesome_rounded,
                    label: l10n.magicAddTab,
                  ),
                  _LabeledTab(
                    icon: Icons.content_paste_go_rounded,
                    label: l10n.smartImportPasteTab,
                  ),
                  _LabeledTab(
                    icon: Icons.bolt_rounded,
                    label: l10n.smartImportQuickTab,
                  ),
                  _LabeledTab(
                    icon: Icons.sms_outlined,
                    label: l10n.smartImportSmsTab,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LabeledTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
