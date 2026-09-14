import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/helpers/association_ledger_access.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/tab_centered_scroll.dart';
import 'package:imrpo/core/widgets/transaction_tab_loading_skeleton.dart';
import 'package:imrpo/core/widgets/tab_refresh_overlay.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/home/presentation/widgets/home_first_run_guide.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/domain/entities/income.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/widgets/add_income_sheet.dart';
import 'package:imrpo/features/incomes_tab/presentation/widgets/income_list_tile.dart';
import 'package:imrpo/features/incomes_tab/presentation/widgets/manage_income_source_sheet.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
import 'package:imrpo/features/salary_day/presentation/widgets/salary_day_sheet.dart';
import 'package:imrpo/features/smart_import/presentation/widgets/smart_import_ai_tab.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class IncomesTab extends StatefulWidget {
  const IncomesTab({super.key});

  @override
  State<IncomesTab> createState() => _IncomesTabState();
}

class _IncomesTabState extends State<IncomesTab>
    with AutomaticKeepAliveClientMixin {
  String? _selectedSource;
  bool _initialLoadDone = false;

  @override
  bool get wantKeepAlive => true;

  static String _sourceKey(Income income) {
    final category = income.category.trim();
    return category.isEmpty ? 'Other' : category;
  }

  @override
  void initState() {
    super.initState();
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: ListenableBuilder(
        listenable: getIt<AssociationContext>(),
        builder: (context, _) {
          if (!AssociationLedgerAccess.canEdit) {
            return const SizedBox.shrink();
          }
          return GestureDetector(
            onLongPress: _openAddSheet,
            child: FloatingActionButton.extended(
              key: HomeGuideTargets.addIncome,
              heroTag: 'fab-incomes',
              onPressed: _openMagicAdd,
              backgroundColor: AppColors.income,
              elevation: 2,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                l10n.addIncome,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<IncomesTabBloc, IncomesTabState>(
            listenWhen: (previous, current) =>
                current.status == IncomesTabStatus.errorDelete ||
                current.status == IncomesTabStatus.errorAll ||
                current.status == IncomesTabStatus.errorClearAll ||
                current.status == IncomesTabStatus.errorSource,
            listener: (context, state) {
              final msgL10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizeApiError(msgL10n, state.message)),
                  backgroundColor: AppColors.error,
                ),
              );
            },
          ),
          BlocListener<IncomesTabBloc, IncomesTabState>(
            listenWhen: (previous, current) =>
                previous.status == IncomesTabStatus.loadingClearAll &&
                current.status == IncomesTabStatus.loaded,
            listener: (context, state) {
              final msgL10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msgL10n.clearAllIncomesSuccess),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          BlocListener<IncomesTabBloc, IncomesTabState>(
            listenWhen: (previous, current) =>
                previous.status == IncomesTabStatus.loadingSource &&
                current.status == IncomesTabStatus.loaded,
            listener: (context, state) {
              final msgL10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msgL10n.incomeSourceUpdatedSuccess),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          BlocListener<IncomesTabBloc, IncomesTabState>(
            listenWhen: (previous, current) =>
                current.status == IncomesTabStatus.loaded &&
                previous.status != IncomesTabStatus.loaded,
            listener: (context, state) {
              if (!_initialLoadDone) {
                setState(() => _initialLoadDone = true);
              }
            },
          ),
        ],
        child: BlocBuilder<IncomesTabBloc, IncomesTabState>(
          builder: (context, state) {
            if (state.incomes.isEmpty &&
                state.status == IncomesTabStatus.loadingAll &&
                !_initialLoadDone) {
              return const TransactionTabLoadingSkeleton(forIncome: true);
            }

            if (state.incomes.isEmpty &&
                state.status == IncomesTabStatus.loadingAll) {
              return tabCenteredScroll(
                Stack(
                  children: [
                    _EmptyState(onAdd: _openMagicAdd),
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.income),
                    ),
                  ],
                ),
              );
            }

            final sorted = [...state.incomes]
              ..sort((a, b) => b.date.compareTo(a.date));

            final isRefreshing =
                state.incomes.isNotEmpty &&
                state.status == IncomesTabStatus.loadingAll;
            final isClearingAll =
                state.status == IncomesTabStatus.loadingClearAll;

            return ListenableBuilder(
              listenable: getIt<HomeDateFilter>(),
              builder: (context, _) {
                final dateFilter = getIt<HomeDateFilter>();
                final dateFiltered = sorted
                    .where((income) => dateFilter.matches(income.date))
                    .toList();
                final availableSources =
                    dateFiltered.map(_sourceKey).toSet().toList()..sort();
                final activeSource =
                    _selectedSource != null &&
                        availableSources.contains(_selectedSource)
                    ? _selectedSource
                    : null;
                final filtered = activeSource == null
                    ? dateFiltered
                    : dateFiltered
                          .where((income) => _sourceKey(income) == activeSource)
                          .toList();
                final periodTotal = filtered.fold<double>(
                  0,
                  (sum, income) => sum + income.amount,
                );
                final sourceTotals = _totalsBySource(dateFiltered);
                final sourceEntryCounts = _entryCountsBySource(dateFiltered);

                return Stack(
                  children: [
                    TabRefreshOverlay(
                      isRefreshing: isRefreshing,
                      indicatorColor: AppColors.income,
                      child: RefreshIndicator(
                        color: AppColors.income,
                        onRefresh: () async {
                          context.read<IncomesTabBloc>().add(
                            const LoadIncomesEvent(),
                          );
                          await Future.delayed(
                            const Duration(milliseconds: 350),
                          );
                        },
                        child: CustomScrollView(
                          physics: kHomeTabScrollPhysics,
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  8,
                                ),
                                child: _SummaryCard(
                                  total: periodTotal,
                                  periodLabel: dateFilter.summaryPeriodLabel(
                                    context,
                                  ),
                                  sourceLabel: activeSource == null
                                      ? null
                                      : localizeIncomeCategory(
                                          l10n,
                                          activeSource,
                                        ),
                                ),
                              ),
                            ),

                            if (availableSources.length > 1)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    12,
                                    20,
                                    0,
                                  ),
                                  child: _SourceFilterBar(
                                    sources: availableSources,
                                    selectedSource: activeSource,
                                    onSelected: (source) {
                                      setState(() => _selectedSource = source);
                                    },
                                  ),
                                ),
                              ),

                            if (sourceTotals.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    0,
                                  ),
                                  child: _SourceBreakdown(
                                    sourceTotals: sourceTotals,
                                    sourceEntryCounts: sourceEntryCounts,
                                    selectedSource: activeSource,
                                    isBusy:
                                        state.status ==
                                        IncomesTabStatus.loadingSource,
                                    onSourceSelected: (source) {
                                      setState(() {
                                        _selectedSource = activeSource == source
                                            ? null
                                            : source;
                                      });
                                    },
                                    onRenameSource:
                                        AssociationLedgerAccess.canEdit
                                        ? (source) => _renameIncomeSource(
                                            source,
                                            availableSources,
                                          )
                                        : null,
                                    onRemoveSource:
                                        AssociationLedgerAccess.canEdit
                                        ? (source, count) =>
                                              _removeIncomeSource(source, count)
                                        : null,
                                  ),
                                ),
                              ),

                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l10n.recentIncomes,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textColor,
                                        ),
                                      ),
                                    ),
                                    if (sorted.isNotEmpty &&
                                        AssociationLedgerAccess.canEdit) ...[
                                      TextButton(
                                        onPressed: isClearingAll
                                            ? null
                                            : () => _confirmClearAll(
                                                sorted.length,
                                              ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.income,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        child: Text(l10n.clearAllIncomes),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      l10n.listEntryCount(filtered.length),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (filtered.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: sorted.isEmpty
                                    ? _EmptyState(onAdd: _openMagicAdd)
                                    : _FilteredEmptyState(
                                        message: activeSource != null
                                            ? l10n.incomeFilterNoSourceEntries
                                            : l10n.homeFilterNoEntries,
                                        onClearFilter: activeSource != null
                                            ? () => setState(
                                                () => _selectedSource = null,
                                              )
                                            : null,
                                      ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  100,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final income = filtered[index];

                                    final canEdit =
                                        AssociationLedgerAccess.canEdit;
                                    return IncomeListTile(
                                      income: income,
                                      onTap: canEdit
                                          ? () => _openEditSheet(income)
                                          : null,
                                      onDelete: canEdit
                                          ? () {
                                              context
                                                  .read<IncomesTabBloc>()
                                                  .add(
                                                    DeleteIncomeEvent(
                                                      income.id,
                                                    ),
                                                  );
                                            }
                                          : null,
                                    );
                                  }, childCount: filtered.length),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (isClearingAll)
                      const TabBusyOverlay(indicatorColor: AppColors.income),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(int count) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearAllIncomesConfirmTitle),
        content: Text(l10n.clearAllIncomesConfirmMessage(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.income),
            child: Text(l10n.clearAllIncomes),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    context.read<IncomesTabBloc>().add(const ClearAllIncomesEvent());
  }

  void _openAddSheet() => _showIncomeSheet(const AddIncomeSheet());

  Future<void> _openMagicAdd() {
    return showMagicAddSheet(
      context,
      preferredType: FinancialEntryType.income,
    );
  }

  void _openEditSheet(Income income) =>
      _showIncomeSheet(AddIncomeSheet(income: income));

  static Map<String, double> _totalsBySource(List<Income> incomes) {
    final totals = <String, double>{};
    for (final income in incomes) {
      final key = _sourceKey(income);
      totals[key] = (totals[key] ?? 0) + income.amount;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  static Map<String, int> _entryCountsBySource(List<Income> incomes) {
    final counts = <String, int>{};
    for (final income in incomes) {
      final key = _sourceKey(income);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _renameIncomeSource(
    String source,
    List<String> existingSources,
  ) async {
    final newName = await showRenameIncomeSourceSheet(
      context,
      currentSource: source,
      existingSources: existingSources,
    );
    if (newName == null || !mounted) return;

    context.read<IncomesTabBloc>().add(
      RenameIncomeSourceEvent(fromSource: source, toSource: newName),
    );

    if (_selectedSource == source) {
      setState(() => _selectedSource = newName);
    }
  }

  Future<void> _removeIncomeSource(String source, int entryCount) async {
    final l10n = AppLocalizations.of(context)!;
    final label = localizeIncomeCategory(l10n, source);

    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
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
            const SizedBox(height: 20),
            Text(
              l10n.incomeSourceRemoveTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.incomeSourceRemoveMessage(entryCount, label),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColor.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outline),
              title: Text(l10n.incomeSourceMoveToOther),
              onTap: () => Navigator.pop(sheetContext, 'move'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.errorColor,
              ),
              title: Text(
                l10n.incomeSourceDeleteAll,
                style: TextStyle(color: AppColors.errorColor),
              ),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'move') {
      context.read<IncomesTabBloc>().add(
        RenameIncomeSourceEvent(fromSource: source, toSource: 'Other'),
      );
      if (_selectedSource == source) {
        setState(() => _selectedSource = 'Other');
      }
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.incomeSourceDeleteConfirmTitle),
          content: Text(l10n.incomeSourceDeleteConfirmMessage(entryCount)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.errorColor,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.incomeSourceDeleteConfirmAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      context.read<IncomesTabBloc>().add(DeleteIncomesBySourceEvent(source));
      if (_selectedSource == source) {
        setState(() => _selectedSource = null);
      }
    }
  }

  Future<void> _showIncomeSheet(Widget sheet) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => AnimatedPadding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: BlocProvider.value(
          value: context.read<IncomesTabBloc>(),
          child: sheet,
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (result.startsWith('added_salary:')) {
      AppToast.success(context, l10n.incomeAddedSuccess);
      final amount = double.tryParse(result.substring('added_salary:'.length));
      final plans = context.read<PlansTabBloc>();
      final expenses = context.read<ExpensesTabBloc>();
      await showSalaryDaySheet(
        context,
        initialAmountInBase: amount,
        plansBloc: plans,
        expensesBloc: expenses,
      );
      return;
    }

    final message = switch (result) {
      'added' => l10n.incomeAddedSuccess,
      'updated' => l10n.incomeUpdatedSuccess,
      _ => null,
    };
    if (message != null) {
      AppToast.success(context, message);
    }
  }
}

class _SourceFilterBar extends StatelessWidget {
  final List<String> sources;
  final String? selectedSource;
  final ValueChanged<String?> onSelected;

  const _SourceFilterBar({
    required this.sources,
    required this.selectedSource,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.incomeSourceField,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: Text(l10n.incomeFilterAllSources),
                selected: selectedSource == null,
                onSelected: (_) => onSelected(null),
                selectedColor: AppColors.income,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selectedSource == null
                      ? Colors.white
                      : AppColors.textColor,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 8),
              ...sources.map((source) {
                final selected = selectedSource == source;
                final label = localizeIncomeCategory(l10n, source);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => onSelected(source),
                    selectedColor: AppColors.income,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: AppColors.surface,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceBreakdown extends StatelessWidget {
  final Map<String, double> sourceTotals;
  final Map<String, int> sourceEntryCounts;
  final String? selectedSource;
  final bool isBusy;
  final ValueChanged<String> onSourceSelected;
  final ValueChanged<String>? onRenameSource;
  final void Function(String source, int entryCount)? onRemoveSource;

  const _SourceBreakdown({
    required this.sourceTotals,
    required this.sourceEntryCounts,
    required this.selectedSource,
    required this.isBusy,
    required this.onSourceSelected,
    this.onRenameSource,
    this.onRemoveSource,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.incomeBySource,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 10),
        ...sourceTotals.entries.map((entry) {
          final label = localizeIncomeCategory(l10n, entry.key);
          final isSelected = selectedSource == entry.key;
          final count = sourceEntryCounts[entry.key] ?? 0;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isBusy ? null : () => onSourceSelected(entry.key),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: AppDecorations.card(
                  borderColor: isSelected
                      ? AppColors.income
                      : AppColors.income.withValues(alpha: 0.12),
                ).copyWith(color: isSelected ? AppColors.incomeLight : null),
                child: Row(
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.income.withValues(alpha: 0.15)
                            : AppColors.incomeLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.filter_alt_rounded
                            : Icons.payments_outlined,
                        color: AppColors.income,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.incomeDark
                                  : AppColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.listEntryCount(count),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Money.format(entry.value),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.income,
                      ),
                    ),
                    if (onRenameSource != null || onRemoveSource != null)
                      PopupMenuButton<String>(
                        enabled: !isBusy,
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.textColor.withValues(alpha: 0.45),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onRenameSource?.call(entry.key);
                          } else if (value == 'remove') {
                            onRemoveSource?.call(entry.key, count);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 20),
                                const SizedBox(width: 10),
                                Text(l10n.incomeSourceManageEdit),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: AppColors.errorColor,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.incomeSourceManageRemove,
                                  style: TextStyle(color: AppColors.errorColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double total;
  final String periodLabel;
  final String? sourceLabel;

  const _SummaryCard({
    required this.total,
    required this.periodLabel,
    this.sourceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ThemedSummaryCard(
      accent: AppColors.income,
      child: Builder(
        builder: (context) {
          final on = SummaryCardColors.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: on.overlayStrong,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: on.foreground,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: on.overlayStrong,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      periodLabel,
                      style: TextStyle(
                        color: on.foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (sourceLabel != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: on.overlayStrong,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sourceLabel!,
                    style: TextStyle(
                      color: on.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                l10n.totalIncome,
                style: TextStyle(
                  color: on.muted,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                Money.format(total),
                style: TextStyle(
                  color: on.foreground,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onClearFilter;

  const _FilteredEmptyState({required this.message, this.onClearFilter});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 48,
              color: AppColors.textColor.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textColor.withValues(alpha: 0.6),
              ),
            ),
            if (onClearFilter != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onClearFilter,
                style: TextButton.styleFrom(foregroundColor: AppColors.income),
                child: Text(l10n.incomeFilterAllSources),
              ),
            ],
          ],
        ),
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.incomeLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: AppColors.income,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noIncomesTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noIncomesSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColor.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addIncome),
              style: TextButton.styleFrom(foregroundColor: AppColors.income),
            ),
          ],
        ),
      ),
    );
  }
}
