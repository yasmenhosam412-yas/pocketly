import 'package:flutter/material.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Helpful income tools as one-tap chips (AI add, form, import, salary day…).
class IncomeToolsStrip extends StatelessWidget {
  final VoidCallback onMagicAdd;
  final VoidCallback onAddForm;
  final VoidCallback onSmartImport;
  final VoidCallback onSalaryDay;
  final VoidCallback onRecurring;

  const IncomeToolsStrip({
    super.key,
    required this.onMagicAdd,
    required this.onAddForm,
    required this.onSmartImport,
    required this.onSalaryDay,
    required this.onRecurring,
  });

  static const _color = AppColors.income;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final tools = <_IncomeTool>[
      _IncomeTool(
        icon: Icons.auto_awesome_rounded,
        label: l10n.magicAddShort,
        onTap: onMagicAdd,
      ),
      _IncomeTool(
        icon: Icons.edit_note_rounded,
        label: l10n.incomeToolsAddForm,
        onTap: onAddForm,
      ),
      _IncomeTool(
        icon: Icons.document_scanner_outlined,
        label: l10n.smartImportShort,
        onTap: onSmartImport,
      ),
      _IncomeTool(
        icon: Icons.payments_outlined,
        label: l10n.salaryDayTitle,
        onTap: onSalaryDay,
      ),
      _IncomeTool(
        icon: Icons.event_repeat_rounded,
        label: l10n.incomeToolsRecurring,
        onTap: onRecurring,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.incomeToolsSectionTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.incomeToolsSectionSubtitle,
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: AppColors.textColor.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final tool in tools)
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  child: ActionChip(
                    avatar: Icon(tool.icon, size: 18, color: _color),
                    label: Text(
                      tool.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                      ),
                    ),
                    onPressed: tool.onTap,
                    backgroundColor: _color.withValues(alpha: 0.1),
                    side: BorderSide(
                      color: _color.withValues(alpha: 0.22),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IncomeTool {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IncomeTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
