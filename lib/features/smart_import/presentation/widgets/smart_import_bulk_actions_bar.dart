import 'package:flutter/material.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class SmartImportBulkActionsBar extends StatelessWidget {
  final bool disabled;
  final int expenseCount;
  final int incomeCount;
  final int selectedCount;
  final bool hasSelection;
  final VoidCallback onAddAllExpenses;
  final VoidCallback onAddAllIncomes;
  final VoidCallback onAddSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final int importedCount;
  final VoidCallback? onClearAllAdded;

  const SmartImportBulkActionsBar({
    super.key,
    required this.disabled,
    required this.expenseCount,
    required this.incomeCount,
    required this.selectedCount,
    required this.hasSelection,
    required this.onAddAllExpenses,
    required this.onAddAllIncomes,
    required this.onAddSelected,
    required this.onSelectAll,
    required this.onClearSelection,
    this.importedCount = 0,
    this.onClearAllAdded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _BulkChip(
              label: l10n.smartImportAddAllExpenses(expenseCount),
              icon: Icons.north_east_rounded,
              color: AppColors.expense,
              onTap: disabled || expenseCount == 0 ? null : onAddAllExpenses,
            ),
            _BulkChip(
              label: l10n.smartImportAddAllIncomes(incomeCount),
              icon: Icons.south_west_rounded,
              color: AppColors.income,
              onTap: disabled || incomeCount == 0 ? null : onAddAllIncomes,
            ),
          ],
        ),
        if (onClearAllAdded != null && importedCount > 0) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: disabled ? null : onClearAllAdded,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: Text(l10n.smartImportSmsClearAllAdded),
              style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            ),
          ),
        ],
        if (hasSelection) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: disabled || selectedCount == 0
                      ? null
                      : onAddSelected,
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 20),
                  label: Text(l10n.smartImportAddSelected(selectedCount)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: disabled ? null : onClearSelection,
                child: Text(l10n.smartImportClearSelection),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: disabled ? null : onSelectAll,
              icon: const Icon(Icons.select_all_rounded, size: 18),
              label: Text(l10n.smartImportSelectAll),
            ),
          ),
        ],
      ],
    );
  }
}

class _BulkChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _BulkChip({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
