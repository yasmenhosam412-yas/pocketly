import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/show_app_bottom_sheet.dart';
import 'package:imrpo/features/bill_reminders/domain/bill_reminder_day_helper.dart';
import 'package:imrpo/features/recurring_transactions/domain/entities/recurring_transaction.dart';
import 'package:imrpo/features/recurring_transactions/presentation/bloc/recurring_transactions_bloc.dart';
import 'package:imrpo/features/recurring_transactions/presentation/widgets/add_recurring_transaction_sheet.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RecurringTransactionsBloc>().add(
      const LoadRecurringTransactionsEvent(),
    );
  }

  Future<void> _openEditor({RecurringTransaction? item}) async {
    await showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<RecurringTransactionsBloc>(),
        child: AddRecurringTransactionSheet(item: item),
      ),
    );
  }

  Future<bool> _askDelete(RecurringTransaction item) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recurringTransactionsDeleteConfirmTitle),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.expenseShortcutDelete),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _delete(RecurringTransaction item) {
    final l10n = AppLocalizations.of(context)!;
    context.read<RecurringTransactionsBloc>().add(
      DeleteRecurringTransactionEvent(id: item.id),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.recurringTransactionsDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.recurringTransactionsTitle,
          style: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton:
          BlocBuilder<RecurringTransactionsBloc, RecurringTransactionsState>(
        builder: (context, state) {
          final showFab =
              state is RecurringTransactionsLoaded && state.items.isNotEmpty;
          if (!showFab) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _openEditor(),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.recurringTransactionsAdd),
          );
        },
      ),
      body: BlocBuilder<RecurringTransactionsBloc, RecurringTransactionsState>(
        builder: (context, state) {
          if (state is RecurringTransactionsLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primaryInk),
            );
          }
          if (state is RecurringTransactionsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  localizeApiError(l10n, state.message),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (state is! RecurringTransactionsLoaded) {
            return const SizedBox.shrink();
          }

          if (state.items.isEmpty) {
            return _EmptyState(onAdd: () => _openEditor());
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: state.items.length + 1,
            separatorBuilder: (_, index) =>
                SizedBox(height: index == 0 ? 16 : 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _IntroHeader(
                  subtitle: l10n.recurringTransactionsSubtitle,
                  count: state.items.length,
                );
              }
              final item = state.items[index - 1];
              return _RecurringRuleCard(
                item: item,
                onTap: () => _openEditor(item: item),
                onToggle: (enabled) {
                  context.read<RecurringTransactionsBloc>().add(
                    ToggleRecurringTransactionEvent(
                      id: item.id,
                      enabled: enabled,
                    ),
                  );
                },
                confirmDelete: () => _askDelete(item),
                onDeleted: () => _delete(item),
              );
            },
          );
        },
      ),
    );
  }
}

class _IntroHeader extends StatelessWidget {
  final String subtitle;
  final int count;

  const _IntroHeader({required this.subtitle, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryInk.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryInk.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryInk.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryInk.withValues(alpha: 0.22),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.repeat_rounded,
                size: 40,
                color: AppColors.primaryInk,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              l10n.recurringTransactionsTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.recurringTransactionsEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDecorations.buttonRadius,
                  ),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                l10n.recurringTransactionsAdd,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringRuleCard extends StatelessWidget {
  final RecurringTransaction item;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final Future<bool> Function() confirmDelete;
  final VoidCallback onDeleted;

  const _RecurringRuleCard({
    required this.item,
    required this.onTap,
    required this.onToggle,
    required this.confirmDelete,
    required this.onDeleted,
  });

  bool get _postedThisMonth {
    final ym = RecurringTransaction.yearMonth(DateTime.now());
    return item.lastPostedYm == ym;
  }

  DateTime _nextDue() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var year = now.year;
    var month = now.month;
    if (_postedThisMonth ||
        BillReminderDayHelper.effectiveDay(year, month, item.dayOfMonth) <
            today.day) {
      if (month == 12) {
        year += 1;
        month = 1;
      } else {
        month += 1;
      }
    }
    final day = BillReminderDayHelper.effectiveDay(
      year,
      month,
      item.dayOfMonth,
    );
    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome = item.kind == RecurringKind.income;
    final accent = isIncome ? AppColors.income : AppColors.expense;
    final muted = !item.isEnabled;
    final category = isIncome
        ? localizeIncomeCategory(l10n, item.category)
        : localizeExpenseCategory(l10n, item.category);
    final locale = Localizations.localeOf(context).toString();
    final nextDue = DateFormat.MMMd(locale).format(_nextDue());

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(),
      onDismissed: (_) => onDeleted(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: muted
                    ? AppColors.stroke.withValues(alpha: 0.1)
                    : accent.withValues(alpha: 0.22),
                width: 1.5,
              ),
              boxShadow: AppDecorations.flatShadow(
                color: muted ? AppColors.stroke : accent,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: muted
                          ? AppColors.textMuted.withValues(alpha: 0.45)
                          : accent,
                      borderRadius: const BorderRadiusDirectional.only(
                        topStart: Radius.circular(18),
                        bottomStart: Radius.circular(18),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: (muted ? AppColors.textMuted : accent)
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isIncome
                                      ? Icons.south_west_rounded
                                      : Icons.north_east_rounded,
                                  size: 18,
                                  color: muted
                                      ? AppColors.textSecondary
                                      : accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: muted
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Money.format(item.amount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        letterSpacing: -0.3,
                                        color: muted
                                            ? AppColors.textSecondary
                                            : accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: item.isEnabled,
                                activeThumbColor: accent,
                                onChanged: onToggle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _MetaChip(
                                label: isIncome
                                    ? l10n.tabIncomes
                                    : l10n.tabExpenses,
                                color: accent,
                                muted: muted,
                              ),
                              _MetaChip(
                                label: nextDue,
                                icon: Icons.event_rounded,
                                muted: muted,
                              ),
                              _MetaChip(
                                label: category,
                                muted: muted,
                              ),
                              if (_postedThisMonth)
                                _MetaChip(
                                  label: l10n.recurringTransactionsPostedThisMonth,
                                  color: AppColors.income,
                                  muted: muted,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool muted;

  const _MetaChip({
    required this.label,
    this.icon,
    this.color,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = muted
        ? AppColors.textSecondary
        : (color ?? AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
