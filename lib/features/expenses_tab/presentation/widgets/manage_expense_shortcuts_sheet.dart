import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/services/expense_shortcuts_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/features/expenses_tab/domain/entities/expense_shortcut.dart';
import 'package:imrpo/features/expenses_tab/presentation/widgets/add_expense_shortcut_sheet.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Lists saved one-tap shortcuts; add / edit / delete.
class ManageExpenseShortcutsSheet extends StatelessWidget {
  const ManageExpenseShortcutsSheet({super.key});

  Future<void> _openEditor(BuildContext context, {ExpenseShortcut? editing}) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<IncomesTabBloc>(),
        child: AnimatedPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AddExpenseShortcutSheet(editing: editing),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ExpenseShortcut s) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.expenseShortcutDeleteConfirmTitle),
        content: Text(l10n.expenseShortcutDeleteConfirmMessage(s.displayLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorColor),
            child: Text(l10n.expenseShortcutDelete),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await getIt<ExpenseShortcutsStore>().remove(s.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final store = getIt<ExpenseShortcutsStore>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.expenseShortcutsManageTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.expenseShortcutsManageSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textColor.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: store,
              builder: (context, _) {
                final items = store.items;
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.expenseShortcutsEmptyBody,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textColor.withValues(alpha: 0.65),
                      ),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, unusedIndex) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = items[index];
                      final paid = s.incomeSource?.trim();
                      final paidLabel = paid == null || paid.isEmpty
                          ? l10n.expensePaidFromNone
                          : localizeIncomeCategory(l10n, paid);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          s.displayLabel,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${Money.format(s.amountBase)} · ${localizeExpenseCategory(l10n, s.category)} · $paidLabel\n${s.expenseTitle}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textColor.withValues(alpha: 0.6),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openEditor(context, editing: s),
                              color: AppColors.expense,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () => _confirmDelete(context, s),
                              color: AppColors.errorColor,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                l10n.expenseShortcutAddTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.expense,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
