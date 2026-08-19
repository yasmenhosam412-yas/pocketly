import 'package:flutter/material.dart';
import 'package:imrpo/core/services/expense_shortcuts_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/expenses_tab/domain/entities/expense_shortcut.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Horizontal one-tap expense chips + manage control.
class ExpenseShortcutsStrip extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onManage;
  final void Function(ExpenseShortcut shortcut) onApply;

  const ExpenseShortcutsStrip({
    super.key,
    required this.isBusy,
    required this.onManage,
    required this.onApply,
  });

  static const _color = AppColors.expense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = getIt<ExpenseShortcutsStore>();

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.items;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.expenseShortcutsSectionTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onManage,
                  tooltip: l10n.expenseShortcutsManageTitle,
                  icon: Icon(
                    Icons.tune_rounded,
                    color: _color.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            if (items.isEmpty)
              TextButton.icon(
                onPressed: onManage,
                icon: Icon(Icons.add_circle_outline_rounded, color: _color),
                label: Text(l10n.expenseShortcutsEmptyCta),
                style: TextButton.styleFrom(
                  foregroundColor: _color,
                  padding: EdgeInsets.zero,
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final s in items)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        child: ActionChip(
                          avatar: Icon(
                            Icons.bolt_rounded,
                            size: 18,
                            color: isBusy
                                ? AppColors.textColor.withValues(alpha: 0.35)
                                : _color,
                          ),
                          label: Text(
                            '${s.displayLabel} · ${Money.format(s.amountBase)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isBusy
                                  ? AppColors.textColor.withValues(alpha: 0.45)
                                  : AppColors.textColor,
                            ),
                          ),
                          onPressed: isBusy ? null : () => onApply(s),
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
      },
    );
  }
}
