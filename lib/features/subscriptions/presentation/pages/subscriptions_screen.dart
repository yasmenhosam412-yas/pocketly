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

/// Subscriptions = recurring expenses, with a “due this week” focus.
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
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
        child: AddRecurringTransactionSheet(
          item: item,
          lockKind: RecurringKind.expense,
        ),
      ),
    );
  }

  List<RecurringTransaction> _subs(List<RecurringTransaction> all) =>
      all.where((e) => e.kind == RecurringKind.expense).toList();

  DateTime _nextDue(RecurringTransaction item, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final dayThisMonth = BillReminderDayHelper.effectiveDay(
      now.year,
      now.month,
      item.dayOfMonth,
    );
    var due = DateTime(now.year, now.month, dayThisMonth);
    if (due.isBefore(today)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      due = DateTime(
        nextYear,
        nextMonth,
        BillReminderDayHelper.effectiveDay(
          nextYear,
          nextMonth,
          item.dayOfMonth,
        ),
      );
    }
    return due;
  }

  bool _dueThisWeek(RecurringTransaction item, DateTime now) {
    if (!item.isEnabled) return false;
    final due = _nextDue(item, now);
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 7));
    return !due.isBefore(today) && due.isBefore(end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        title: Text(
          l10n.subscriptionsTitle,
          style: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.expense,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.subscriptionsAdd),
      ),
      body: BlocBuilder<RecurringTransactionsBloc, RecurringTransactionsState>(
        builder: (context, state) {
          if (state is! RecurringTransactionsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final subs = _subs(state.items);
          final dueSoon = subs.where((s) => _dueThisWeek(s, now)).toList()
            ..sort(
              (a, b) => _nextDue(a, now).compareTo(_nextDue(b, now)),
            );
          final monthly = subs
              .where((s) => s.isEnabled)
              .fold<double>(0, (sum, s) => sum + s.amount);

          if (subs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.subscriptions_outlined,
                      size: 48,
                      color: AppColors.textColor.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.subscriptionsEmptyTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.subscriptionsEmptySubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textColor.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _openEditor(),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.subscriptionsAdd),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.card(
                  borderColor: AppColors.expense.withValues(alpha: 0.2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.subscriptionsMonthlyTotal,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textColor.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Money.format(monthly),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      l10n.subscriptionsCount(subs.length),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              if (dueSoon.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  l10n.subscriptionsDueThisWeek,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...dueSoon.map((item) {
                  final due = _nextDue(item, now);
                  return _SubTile(
                    item: item,
                    dueLabel: DateFormat.MMMd(locale).format(due),
                    highlight: true,
                    onTap: () => _openEditor(item: item),
                    onDelete: () {
                      context.read<RecurringTransactionsBloc>().add(
                        DeleteRecurringTransactionEvent(id: item.id),
                      );
                    },
                  );
                }),
              ],
              const SizedBox(height: 18),
              Text(
                l10n.subscriptionsAll,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              ...subs.map((item) {
                final due = _nextDue(item, now);
                return _SubTile(
                  item: item,
                  dueLabel: DateFormat.MMMd(locale).format(due),
                  highlight: false,
                  onTap: () => _openEditor(item: item),
                  onDelete: () {
                    context.read<RecurringTransactionsBloc>().add(
                      DeleteRecurringTransactionEvent(id: item.id),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _SubTile extends StatelessWidget {
  final RecurringTransaction item;
  final String dueLabel;
  final bool highlight;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SubTile({
    required this.item,
    required this.dueLabel,
    required this.highlight,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: AppDecorations.card(
              borderColor: highlight
                  ? AppColors.expense.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.expense.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.subscriptions_outlined,
                    color: AppColors.expense,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${localizeExpenseCategory(l10n, item.category)} · ${l10n.subscriptionsDueOn(dueLabel)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textColor.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Money.format(item.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
