import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/show_app_bottom_sheet.dart';
import 'package:imrpo/features/balance_tab/presentation/bloc/balance_tab_bloc.dart';
import 'package:imrpo/features/commitments/data/commitment_ledger.dart';
import 'package:imrpo/features/commitments/data/commitment_store.dart';
import 'package:imrpo/features/commitments/domain/entities/payment_commitment.dart';
import 'package:imrpo/features/commitments/presentation/widgets/add_commitment_sheet.dart';
import 'package:imrpo/features/commitments/presentation/widgets/mark_commitment_paid_sheet.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class CommitmentsScreen extends StatefulWidget {
  /// Home tab: no back bar, because the home header already names the tab.
  final bool embedded;

  const CommitmentsScreen({super.key, this.embedded = false});

  @override
  State<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends State<CommitmentsScreen>
    with AutomaticKeepAliveClientMixin {
  final _store = getIt<CommitmentStore>();
  final _ledger = getIt<CommitmentLedger>();
  CommitmentKind _filter = CommitmentKind.gameya;
  List<PaymentCommitment> _items = [];
  bool _loading = true;
  bool _posting = false;

  @override
  bool get wantKeepAlive => widget.embedded;

  @override
  void initState() {
    super.initState();
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    });
  }

  Future<void> _reload() async {
    if (!SupabaseAuthHelper.isSignedIn) {
      setState(() {
        _items = [];
        _loading = false;
      });
      return;
    }
    final items = await _store.loadAll(SupabaseAuthHelper.requireUserId());
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _persist(List<PaymentCommitment> next) async {
    setState(() => _items = next);
    await _store.saveAll(SupabaseAuthHelper.requireUserId(), next);
  }

  List<PaymentCommitment> get _visible =>
      _items.where((item) => item.kind == _filter).toList()
        ..sort((a, b) {
          if (a.isFinished != b.isFinished) return a.isFinished ? 1 : -1;
          if (a.isMyTurnNext != b.isMyTurnNext) return a.isMyTurnNext ? -1 : 1;
          return a.dueDay.compareTo(b.dueDay);
        });

  double get _dueThisMonth {
    return _visible
        .where((item) => item.canMarkPaid())
        .fold(0.0, (sum, item) => sum + item.monthlyAmount);
  }

  Future<void> _openEditor({PaymentCommitment? item}) async {
    final result = await showAppBottomSheet<PaymentCommitment>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddCommitmentSheet(
        kind: item?.kind ?? _filter,
        item: item,
      ),
    );
    if (result == null) return;
    final next = [..._items];
    final index = next.indexWhere((e) => e.id == result.id);
    if (index >= 0) {
      next[index] = result;
    } else {
      next.add(result);
    }
    await _persist(next);
    if (!mounted) return;
    AppToast.success(
      context,
      AppLocalizations.of(context)!.commitmentsSaved,
    );
  }

  Future<void> _markPaid(PaymentCommitment item) async {
    if (_posting || !item.canMarkPaid()) return;
    final l10n = AppLocalizations.of(context)!;
    final draft = await showAppBottomSheet<CommitmentPaymentDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MarkCommitmentPaidSheet(item: item),
    );
    if (draft == null || !mounted) return;

    setState(() => _posting = true);
    final usedExpenses = _items.map((e) => e.lastExpenseId).where((id) => id.isNotEmpty).toSet();
    final usedIncomes = _items.map((e) => e.lastIncomeId).where((id) => id.isNotEmpty).toSet();
    final recordPayout = item.isMyTurnNext;
    final posted = await _ledger.post(
      expenseTitle: l10n.commitmentsExpenseTitle(
        item.title,
        item.nextCycle,
        item.safeTotal,
      ),
      category: draft.category,
      amount: item.monthlyAmount,
      payFrom: draft.payFrom,
      date: DateTime.now(),
      usedExpenseIds: usedExpenses,
      incomeTitle: recordPayout
          ? l10n.commitmentsIncomeTitle(item.title)
          : null,
      payout: item.payout,
      receiveInto: draft.receiveInto,
      usedIncomeIds: usedIncomes,
    );
    if (!mounted) return;
    final unlinked = posted.error == CommitmentLedger.missingLink;
    if (!posted.ok && !unlinked) {
      setState(() => _posting = false);
      final message = posted.error == CommitmentLedger.rolledBack
          ? l10n.errorGeneric
          : localizeApiError(l10n, posted.error ?? '');
      AppToast.error(context, message);
      return;
    }

    final next = _items
        .map(
          (e) => e.id == item.id
              ? e.recordPayment(
                  expenseId: posted.expenseId,
                  incomeId: posted.incomeId,
                  payFrom: draft.payFrom,
                  expenseCategory: draft.category,
                  receiveInto: draft.receiveInto,
                )
              : e,
        )
        .toList();
    await _persist(next);
    if (!mounted) return;
    setState(() => _posting = false);
    _refreshTabs();
    if (unlinked) {
      AppToast.error(context, l10n.commitmentsLedgerMissing);
    } else {
      AppToast.success(context, l10n.commitmentsPosted);
    }
  }

  Future<void> _undo(PaymentCommitment item) async {
    if (_posting) return;
    setState(() => _posting = true);
    if (item.lastExpenseId.isNotEmpty || item.lastIncomeId.isNotEmpty) {
      final error = await _ledger.remove(
        expenseId: item.lastExpenseId,
        incomeId: item.lastIncomeId,
      );
      if (!mounted) return;
      if (error != null) {
        setState(() => _posting = false);
        AppToast.error(
          context,
          localizeApiError(AppLocalizations.of(context)!, error),
        );
        return;
      }
    }
    final next = _items
        .map((e) => e.id == item.id ? e.undoLastPayment() : e)
        .toList();
    await _persist(next);
    if (!mounted) return;
    setState(() => _posting = false);
    _refreshTabs();
  }

  void _refreshTabs() {
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent(force: true));
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent(force: true));
    final filter = getIt<HomeDateFilter>();
    context.read<BalanceTabBloc>().add(
      LoadBalanceEvent(
        reference: filter.date,
        filterByDay: filter.isDayMode,
        includeAllDates: filter.isAllMode,
      ),
    );
  }

  Future<void> _delete(PaymentCommitment item) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commitmentsDeleteTitle),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.expenseShortcutDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _persist(_items.where((e) => e.id != item.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final visible = _visible;
    final accent = _filter == CommitmentKind.gameya
        ? AppColors.primaryInk
        : AppColors.expense;

    return Scaffold(
      backgroundColor:
          widget.embedded ? Colors.transparent : AppColors.scaffold,
      appBar: widget.embedded
          ? null
          : AppBar(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.commitmentsTitle,
          style: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-commitments',
        onPressed: () => _openEditor(),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _filter == CommitmentKind.gameya
              ? l10n.commitmentsAddGameya
              : l10n.commitmentsAddInstallment,
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
                Text(
                  l10n.commitmentsSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _FilterChip(
                        label: l10n.commitmentsGameyas,
                        selected: _filter == CommitmentKind.gameya,
                        color: AppColors.primaryInk,
                        onTap: () =>
                            setState(() => _filter = CommitmentKind.gameya),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: l10n.commitmentsInstallments,
                        selected: _filter == CommitmentKind.installment,
                        color: AppColors.expense,
                        onTap: () => setState(
                          () => _filter = CommitmentKind.installment,
                        ),
                      ),
                    ),
                  ],
                ),
                if (visible.isNotEmpty && _dueThisMonth > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withValues(alpha: 0.22)),
                    ),
                    child: Text(
                      l10n.commitmentsDueThisMonth(Money.format(_dueThisMonth)),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (visible.isEmpty)
                  _Empty(isGameya: _filter == CommitmentKind.gameya)
                else
                  ...visible.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CommitmentCard(
                        item: item,
                        onTap: () => _openEditor(item: item),
                        onMarkPaid: item.canMarkPaid() && !_posting
                            ? () => _markPaid(item)
                            : null,
                        onUndo:
                            item.paidThisMonth() ? () => _undo(item) : null,
                        onDelete: () => _delete(item),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.14) : AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool isGameya;

  const _Empty({required this.isGameya});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(
            isGameya ? Icons.groups_rounded : Icons.calendar_month_rounded,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            isGameya
                ? l10n.commitmentsEmptyGameya
                : l10n.commitmentsEmptyInstallment,
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitmentCard extends StatelessWidget {
  final PaymentCommitment item;
  final VoidCallback onTap;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onUndo;
  final VoidCallback onDelete;

  const _CommitmentCard({
    required this.item,
    required this.onTap,
    required this.onMarkPaid,
    required this.onUndo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = item.isGameya ? AppColors.primaryInk : AppColors.expense;
    final coach = _coachText(l10n);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isMyTurnNext
                  ? accent
                  : AppColors.stroke.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: AppDecorations.flatShadow(color: accent),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                Text(
                  Money.format(item.monthlyAmount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${localizeExpenseCategory(l10n, item.expenseCategory)} · ${l10n.commitmentsFromSource(localizeIncomeCategory(l10n, item.payFrom))}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.isGameya && item.receiveInto.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.commitmentsPayoutInto(
                      localizeIncomeCategory(l10n, item.receiveInto),
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 8,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    color: item.isFinished ? AppColors.success : accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.commitmentsProgress(
                    item.safePaid,
                    item.safeTotal,
                    Money.format(item.remainingMoney),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.isGameya) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.commitmentsPayout(Money.format(item.payout)),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColor,
                    ),
                  ),
                  if (item.members.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _MemberTurns(item: item),
                  ],
                ],
                if (coach != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    coach,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: item.isMyTurnNext ? accent : AppColors.textSecondary,
                    ),
                  ),
                ],
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (onMarkPaid != null)
                      FilledButton.tonal(
                        onPressed: onMarkPaid,
                        child: Text(l10n.commitmentsMarkPaid),
                      )
                    else if (item.isFinished)
                      Text(
                        l10n.commitmentsFinished,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      )
                    else
                      Text(
                        l10n.commitmentsPaidThisMonth,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    if (onUndo != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onUndo,
                        child: Text(l10n.commitmentsUndo),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _coachText(AppLocalizations l10n) {
    if (item.isFinished) return null;
    if (!item.isGameya) {
      return l10n.commitmentsDueDay(item.dueDay);
    }
    if (item.isMyTurnNow()) {
      return item.members.isEmpty ? l10n.commitmentsYourTurn : null;
    }
    if (item.members.isNotEmpty) {
      if (item.turnAlreadyPassed) return l10n.commitmentsTurnPassed;
      final left = item.cyclesUntilMyTurn;
      if (left > 0) return l10n.commitmentsTurnsLeft(left);
      return null;
    }
    if (item.turnAlreadyPassed) return l10n.commitmentsTurnPassed;
    final left = item.cyclesUntilMyTurn;
    if (left > 0) return l10n.commitmentsTurnsLeft(left);
    return l10n.commitmentsDueDay(item.dueDay);
  }
}

class _MemberTurns extends StatelessWidget {
  final PaymentCommitment item;

  const _MemberTurns({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = AppColors.primaryInk;
    final current = item.activeTurn();
    final mine = item.myTurn.clamp(1, item.safeTotal);
    final headline = item.isFinished
        ? null
        : item.isMyTurnNow()
            ? l10n.commitmentsYourTurn
            : item.activeTurnName().isEmpty
                ? null
                : l10n.commitmentsTurnIs(item.activeTurnName());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headline != null) ...[
          Text(
            headline,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: item.isMyTurnNow() ? accent : AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: item.members.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final turn = index + 1;
              final isCurrent = !item.isFinished && turn == current;
              final isMe = turn == mine;
              final done = item.isFinished || turn < current;
              final label = isMe
                  ? '${item.members[index]} · ${l10n.commitmentsMemberMe}'
                  : item.members[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? accent
                      : done
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isCurrent
                        ? accent
                        : isMe
                            ? accent.withValues(alpha: 0.45)
                            : AppColors.border,
                  ),
                ),
                child: Text(
                  '$turn  $label',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isCurrent
                        ? Colors.white
                        : done
                            ? AppColors.success
                            : AppColors.textColor,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
