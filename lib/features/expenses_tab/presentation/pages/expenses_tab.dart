import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/services/smart_import_draft_store.dart';
import 'package:imrpo/features/expenses_tab/domain/entities/expense_shortcut.dart';
import 'package:imrpo/features/expenses_tab/presentation/widgets/expense_shortcuts_strip.dart';
import 'package:imrpo/features/expenses_tab/presentation/widgets/manage_expense_shortcuts_sheet.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/expenses_tab/data/models/expense_model.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/helpers/association_ledger_access.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/features/smart_import/presentation/widgets/smart_import_ai_tab.dart';
import 'package:imrpo/core/widgets/tab_centered_scroll.dart';
import 'package:imrpo/core/widgets/transaction_tab_loading_skeleton.dart';
import 'package:imrpo/core/widgets/tab_refresh_overlay.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/home/presentation/widgets/home_first_run_guide.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/expenses_tab/presentation/widgets/add_expense_sheet.dart';
import 'package:imrpo/features/budgets/domain/entities/budget_period.dart';
import 'package:imrpo/features/budgets/domain/services/budget_calculator.dart';
import 'package:imrpo/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:imrpo/features/budgets/presentation/widgets/budget_overview_section.dart';
import 'package:imrpo/features/expenses_tab/presentation/widgets/expense_list_tile.dart';
import 'package:imrpo/features/expenses_tab/presentation/widgets/manage_expense_category_sheet.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

enum ExpenseListSort { newest, highestAmount }

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab>
    with AutomaticKeepAliveClientMixin {
  static const _expenseColor = AppColors.expense;
  static const _undoDuration = Duration(seconds: 5);

  String? _selectedCategory;
  String? _pendingShortcutLogLabel;
  bool _initialLoadDone = false;
  ExpenseListSort _listSort = ExpenseListSort.newest;
  ExpenseModel? _pendingUndoExpense;
  bool _isRestoringUndo = false;
  Timer? _undoTimer;
  late final HomeDateFilter _dateFilter;

  @override
  bool get wantKeepAlive => true;

  static String _categoryKey(ExpenseModel expense) {
    final category = expense.category.trim();
    return category.isEmpty ? 'Other' : category;
  }

  @override
  void initState() {
    super.initState();
    _dateFilter = getIt<HomeDateFilter>();
    _dateFilter.addListener(_onDateFilterChanged);
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent());
    _loadBudgets();
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _dateFilter.removeListener(_onDateFilterChanged);
    super.dispose();
  }

  static List<ExpenseModel> _sortExpenses(
    List<ExpenseModel> expenses,
    ExpenseListSort sort,
  ) {
    final copy = List<ExpenseModel>.from(expenses);
    switch (sort) {
      case ExpenseListSort.newest:
        copy.sort((a, b) => b.date.compareTo(a.date));
      case ExpenseListSort.highestAmount:
        copy.sort((a, b) {
          final byAmount = b.amount.compareTo(a.amount);
          if (byAmount != 0) return byAmount;
          return b.date.compareTo(a.date);
        });
    }
    return copy;
  }

  void _deleteExpense(ExpenseModel expense) {
    _undoTimer?.cancel();
    _pendingUndoExpense = expense;
    context.read<ExpensesTabBloc>().add(DeleteExpenseEvent(expense.id));
  }

  void _restorePendingExpense() {
    final expense = _pendingUndoExpense;
    if (expense == null) return;
    _undoTimer?.cancel();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _isRestoringUndo = true;
    context.read<ExpensesTabBloc>().add(
      AddExpenseEvent(
        title: expense.title,
        category: expense.category,
        amount: expense.amount,
        date: expense.date,
        incomeSource: expense.incomeSource,
      ),
    );
  }

  void _showUndoSnackBar(AppLocalizations l10n) {
    if (_pendingUndoExpense == null) return;
    _undoTimer?.cancel();
    _undoTimer = Timer(_undoDuration, () {
      if (mounted) setState(() => _pendingUndoExpense = null);
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.expenseDeletedSnack),
        duration: _undoDuration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: l10n.expenseUndoAction,
          textColor: Colors.white,
          onPressed: _restorePendingExpense,
        ),
      ),
    );
  }

  void _onDateFilterChanged() {
    if (!mounted) return;
    _loadBudgets();
    setState(() {});
  }

  void _loadBudgets() {
    final period = BudgetPeriod.fromDateFilter(_dateFilter);
    context.read<BudgetsBloc>().add(
      LoadBudgetsEvent(year: period.year, month: period.month),
    );
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
          return FloatingActionButton.extended(
            key: HomeGuideTargets.addExpense,
            heroTag: 'fab-expenses',
            onPressed: _onExpenseFabPressed,
            backgroundColor: _expenseColor,
            elevation: 2,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              l10n.addExpense,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ExpensesTabBloc, ExpensesTabState>(
            listenWhen: (previous, current) =>
                previous.status == ExpensesTabStatus.loadingDelete &&
                current.status == ExpensesTabStatus.loaded &&
                _pendingUndoExpense != null,
            listener: (context, state) {
              final pending = _pendingUndoExpense!;
              if (state.expenses.any((e) => e.id == pending.id)) {
                setState(() => _pendingUndoExpense = null);
                return;
              }
              _showUndoSnackBar(l10n);
            },
          ),
          BlocListener<ExpensesTabBloc, ExpensesTabState>(
            listenWhen: (previous, current) =>
                current.status == ExpensesTabStatus.errorDelete,
            listener: (context, state) {
              _undoTimer?.cancel();
              setState(() => _pendingUndoExpense = null);
            },
          ),
          BlocListener<ExpensesTabBloc, ExpensesTabState>(
            listenWhen: (previous, current) =>
                _isRestoringUndo &&
                previous.status == ExpensesTabStatus.loadingAdd &&
                current.status == ExpensesTabStatus.loaded,
            listener: (context, state) {
              _undoTimer?.cancel();
              setState(() {
                _pendingUndoExpense = null;
                _isRestoringUndo = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.expenseRestoredSnack),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          BlocListener<ExpensesTabBloc, ExpensesTabState>(
            listenWhen: (previous, current) =>
                _isRestoringUndo &&
                current.status == ExpensesTabStatus.errorAdd,
            listener: (context, state) {
              setState(() => _isRestoringUndo = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizeApiError(l10n, state.error)),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          BlocListener<ExpensesTabBloc, ExpensesTabState>(
            listenWhen: (previous, current) =>
                current.status == ExpensesTabStatus.errorDelete ||
                current.status == ExpensesTabStatus.errorAll ||
                current.status == ExpensesTabStatus.errorClearAll ||
                (previous.status == ExpensesTabStatus.loadingClearAll &&
                    current.status == ExpensesTabStatus.loaded) ||
                (previous.status != ExpensesTabStatus.loaded &&
                    current.status == ExpensesTabStatus.loaded),
            listener: (BuildContext context, ExpensesTabState state) {
              if (state.status == ExpensesTabStatus.errorDelete ||
                  state.status == ExpensesTabStatus.errorAll ||
                  state.status == ExpensesTabStatus.errorClearAll) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizeApiError(l10n, state.error)),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              _loadBudgets();
            },
          ),
          BlocListener<ExpensesTabBloc, ExpensesTabState>(
            listenWhen: (previous, current) =>
                previous.status == ExpensesTabStatus.loadingClearAll &&
                current.status == ExpensesTabStatus.loaded,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.clearAllExpensesSuccess),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          BlocListener<ExpensesTabBloc, ExpensesTabState>(
            listenWhen: (previous, current) =>
                current.status == ExpensesTabStatus.loaded &&
                previous.status != ExpensesTabStatus.loaded,
            listener: (context, state) {
              if (!_initialLoadDone) {
                setState(() => _initialLoadDone = true);
              }
            },
          ),
          BlocListener<BudgetsBloc, BudgetsState>(
            listenWhen: (previous, current) =>
                current.status == BudgetsStatus.error &&
                current.error.isNotEmpty,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizeApiError(l10n, state.error)),
                  backgroundColor: AppColors.error,
                ),
              );
            },
          ),
          BlocListener<ExpensesTabBloc, ExpensesTabState>(
            listenWhen: (previous, current) =>
                previous.status == ExpensesTabStatus.loadingCategory &&
                current.status == ExpensesTabStatus.loaded,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.expenseCategoryUpdatedSuccess),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _loadBudgets();
            },
          ),
          BlocListener<ExpensesTabBloc, ExpensesTabState>(
            listenWhen: (previous, current) =>
                current.status == ExpensesTabStatus.errorCategory,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizeApiError(l10n, state.error)),
                  backgroundColor: AppColors.error,
                ),
              );
            },
          ),
          BlocListener<ExpensesTabBloc, ExpensesTabState>(
            listenWhen: (previous, current) =>
                current.status == ExpensesTabStatus.errorAdd,
            listener: (context, state) {
              if (_pendingShortcutLogLabel == null) return;
              _pendingShortcutLogLabel = null;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localizeApiError(l10n, state.error)),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          BlocListener<ExpensesTabBloc, ExpensesTabState>(
            listenWhen: (previous, current) =>
                previous.status == ExpensesTabStatus.loadingAdd &&
                current.status == ExpensesTabStatus.loaded,
            listener: (context, state) {
              final label = _pendingShortcutLogLabel;
              if (label == null) return;
              _pendingShortcutLogLabel = null;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.expenseShortcutLogged(label)),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
        child: BlocBuilder<ExpensesTabBloc, ExpensesTabState>(
          builder: (context, state) {
            if (state.expenses.isEmpty &&
                state.status == ExpensesTabStatus.loadingAll &&
                !_initialLoadDone) {
              return const TransactionTabLoadingSkeleton(forIncome: false);
            }

            if (state.expenses.isEmpty &&
                state.status == ExpensesTabStatus.loadingAll) {
              return tabCenteredScroll(
                Stack(
                  children: [
                    _EmptyState(onAdd: _openMagicAdd),
                    const Center(
                      child: CircularProgressIndicator(color: _expenseColor),
                    ),
                  ],
                ),
              );
            }

            if (state.expenses.isEmpty &&
                state.status == ExpensesTabStatus.errorAll) {
              return tabCenteredScroll(
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.textColor.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizeApiError(l10n, state.error),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => context.read<ExpensesTabBloc>().add(
                          const LoadExpensesEvent(),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _expenseColor,
                        ),
                        child: Text(l10n.errorTryAgainGeneric),
                      ),
                    ],
                  ),
                ),
              );
            }

            final isRefreshing =
                state.expenses.isNotEmpty &&
                state.status == ExpensesTabStatus.loadingAll &&
                (state.deletingExpenseId ?? '').isEmpty;
            final isClearingAll =
                state.status == ExpensesTabStatus.loadingClearAll;

            return ListenableBuilder(
              listenable: _dateFilter,
              builder: (context, _) {
                final dateFilter = _dateFilter;
                final budgetPeriod = BudgetPeriod.fromDateFilter(dateFilter);
                final monthLabel = DateFormat.yMMMM(
                  Localizations.localeOf(context).toString(),
                ).format(DateTime(budgetPeriod.year, budgetPeriod.month));
                final dateFiltered = state.expenses
                    .where((expense) => dateFilter.matches(expense.date))
                    .toList();
                final availableCategories =
                    dateFiltered.map(_categoryKey).toSet().toList()..sort();
                final activeCategory =
                    _selectedCategory != null &&
                        availableCategories.contains(_selectedCategory)
                    ? _selectedCategory
                    : null;
                final filtered = _sortExpenses(
                  activeCategory == null
                      ? dateFiltered
                      : dateFiltered
                            .where(
                              (expense) =>
                                  _categoryKey(expense) == activeCategory,
                            )
                            .toList(),
                  _listSort,
                );
                final hasExpensesInPeriod = dateFiltered.isNotEmpty;
                final periodTotal = filtered.fold<double>(
                  0,
                  (sum, expense) => sum + expense.amount,
                );
                final categoryTotals = _totalsByCategory(dateFiltered);
                final categoryEntryCounts = _entryCountsByCategory(
                  dateFiltered,
                );

                return Stack(
                  children: [
                    TabRefreshOverlay(
                      isRefreshing: isRefreshing,
                      indicatorColor: _expenseColor,
                      child: RefreshIndicator(
                        color: _expenseColor,
                        onRefresh: () async {
                          context.read<ExpensesTabBloc>().add(
                            const LoadExpensesEvent(),
                          );
                          _loadBudgets();
                          await Future.delayed(
                            const Duration(milliseconds: 350),
                          );
                        },
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
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
                                  categoryLabel: activeCategory == null
                                      ? null
                                      : localizeExpenseCategory(
                                          l10n,
                                          activeCategory,
                                        ),
                                ),
                              ),
                            ),

                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  0,
                                ),
                                child: BlocBuilder<BudgetsBloc, BudgetsState>(
                                  builder: (context, budgetState) {
                                    final spent =
                                        BudgetCalculator.spentByCategoryForMonth(
                                          state.expenses,
                                          year: budgetPeriod.year,
                                          month: budgetPeriod.month,
                                        );
                                    final budgetRows = BudgetCalculator.merge(
                                      budgets: budgetState.budgets,
                                      spentByCategory: spent,
                                    );
                                    final categories =
                                        state.expenses
                                            .where(
                                              (e) =>
                                                  e.date.year ==
                                                      budgetPeriod.year &&
                                                  e.date.month ==
                                                      budgetPeriod.month,
                                            )
                                            .map((e) => _categoryKey(e))
                                            .toSet()
                                            .toList()
                                          ..sort();

                                    return BudgetOverviewSection(
                                      period: budgetPeriod,
                                      rows: budgetRows,
                                      suggestedCategories: categories,
                                      periodLabel: monthLabel,
                                      isLoading:
                                          budgetState.status ==
                                              BudgetsStatus.loading ||
                                          budgetState.status ==
                                              BudgetsStatus.saving,
                                    );
                                  },
                                ),
                              ),
                            ),

                            if (availableCategories.length > 1)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    12,
                                    20,
                                    0,
                                  ),
                                  child: _CategoryFilterBar(
                                    categories: availableCategories,
                                    selectedCategory: activeCategory,
                                    onSelected: (category) {
                                      setState(
                                        () => _selectedCategory = category,
                                      );
                                    },
                                  ),
                                ),
                              ),

                            if (categoryTotals.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    0,
                                  ),
                                  child: _CategoryBreakdown(
                                    categoryTotals: categoryTotals,
                                    categoryEntryCounts: categoryEntryCounts,
                                    selectedCategory: activeCategory,
                                    isBusy:
                                        state.status ==
                                        ExpensesTabStatus.loadingCategory,
                                    onCategorySelected: (category) {
                                      setState(() {
                                        _selectedCategory =
                                            activeCategory == category
                                            ? null
                                            : category;
                                      });
                                    },
                                    onRenameCategory: (category) =>
                                        _renameCategory(
                                          category,
                                          availableCategories,
                                        ),
                                    onRemoveCategory: (category, count) =>
                                        _removeCategory(category, count),
                                  ),
                                ),
                              ),

                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  0,
                                ),
                                child: ExpenseShortcutsStrip(
                                  isBusy:
                                      state.status ==
                                      ExpensesTabStatus.loadingAdd,
                                  onManage: _openManageExpenseShortcuts,
                                  onApply: _applyExpenseShortcut,
                                ),
                              ),
                            ),

                            /// HEADER
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
                                        l10n.recentExpenses,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textColor,
                                        ),
                                      ),
                                    ),
                                    if (hasExpensesInPeriod &&
                                        AssociationLedgerAccess.canEdit) ...[
                                      TextButton(
                                        onPressed: isClearingAll
                                            ? null
                                            : () => _confirmClearAll(
                                                state.expenses.length,
                                              ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.expense,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        child: Text(l10n.clearAllExpenses),
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

                            if (hasExpensesInPeriod && filtered.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    4,
                                  ),
                                  child: _ExpenseSortBar(
                                    sort: _listSort,
                                    onSortChanged: (sort) =>
                                        setState(() => _listSort = sort),
                                  ),
                                ),
                              ),

                            if (filtered.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: state.expenses.isEmpty
                                    ? _EmptyState(onAdd: _openMagicAdd)
                                    : _FilteredEmptyState(
                                        message: activeCategory != null
                                            ? l10n.expenseFilterNoCategoryEntries
                                            : l10n.homeFilterNoEntries,
                                        onClearFilter: activeCategory != null
                                            ? () => setState(
                                                () => _selectedCategory = null,
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
                                    final expense = filtered[index];

                                    final canEdit =
                                        AssociationLedgerAccess.canEdit;
                                    return ExpenseListTile(
                                      expense: expense,
                                      onTap: canEdit
                                          ? () => _openEditSheet(expense)
                                          : null,
                                      onDelete: canEdit
                                          ? () => _deleteExpense(expense)
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
                      const TabBusyOverlay(indicatorColor: _expenseColor),
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
        title: Text(l10n.clearAllExpensesConfirmTitle),
        content: Text(l10n.clearAllExpensesConfirmMessage(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _expenseColor),
            child: Text(l10n.clearAllExpenses),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    context.read<ExpensesTabBloc>().add(const ClearAllExpensesEvent());
  }

  static Map<String, double> _totalsByCategory(List<ExpenseModel> expenses) {
    final totals = <String, double>{};
    for (final expense in expenses) {
      final key = _categoryKey(expense);
      totals[key] = (totals[key] ?? 0) + expense.amount;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  static Map<String, int> _entryCountsByCategory(List<ExpenseModel> expenses) {
    final counts = <String, int>{};
    for (final expense in expenses) {
      final key = _categoryKey(expense);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _onExpenseFabPressed() async {
    final draft = getIt<SmartImportDraftStore>().lastExpenseDraft;
    if (draft == null) {
      await _openMagicAdd();
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
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
                l10n.expenseFabMenuTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.auto_awesome_rounded,
                  color: _expenseColor,
                ),
                title: Text(l10n.expenseFabAiOption),
                subtitle: Text(
                  l10n.expenseFabAiOptionSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textColor.withValues(alpha: 0.55),
                  ),
                ),
                onTap: () => Navigator.pop(ctx, 'ai'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.edit_note_outlined,
                  color: _expenseColor,
                ),
                title: Text(l10n.expenseFabBlankOption),
                onTap: () => Navigator.pop(ctx, 'blank'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.content_paste_go_rounded,
                  color: _expenseColor,
                ),
                title: Text(l10n.expenseFabFromLastPaste),
                subtitle: Text(
                  l10n.expenseFabFromLastPasteSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textColor.withValues(alpha: 0.55),
                  ),
                ),
                onTap: () => Navigator.pop(ctx, 'scan'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (choice == 'ai') {
      await _openMagicAdd();
    } else if (choice == 'scan') {
      _openFromLastReceiptDraft();
    } else if (choice == 'blank') {
      _openAddSheet();
    }
  }

  Future<void> _openMagicAdd() {
    return showMagicAddSheet(
      context,
      preferredType: FinancialEntryType.expense,
    );
  }

  void _openFromLastReceiptDraft() {
    final entry = getIt<SmartImportDraftStore>().lastExpenseDraft;
    final l10n = AppLocalizations.of(context)!;
    if (entry == null) {
      _openAddSheet();
      return;
    }

    final displayAmount = entry.amountInBase != null
        ? getIt<CurrencyPreferences>().displayAmount(entry.amountInBase!)
        : null;
    final rawTitle = entry.title?.trim();
    _showExpenseSheet(
      AddExpenseSheet(
        initialTitle: (rawTitle != null && rawTitle.isNotEmpty)
            ? rawTitle
            : l10n.smartImportDefaultBillTitle,
        initialAmount: displayAmount,
        initialDate: entry.date,
      ),
    );
  }

  Future<void> _openManageExpenseShortcuts() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: context.read<IncomesTabBloc>(),
        child: const ManageExpenseShortcutsSheet(),
      ),
    );
  }

  void _applyExpenseShortcut(ExpenseShortcut s) {
    setState(() => _pendingShortcutLogLabel = s.displayLabel);
    context.read<ExpensesTabBloc>().add(
      AddExpenseEvent(
        title: s.expenseTitle,
        category: s.category,
        amount: s.amountBase,
        date: DateTime.now(),
        incomeSource: s.incomeSource,
      ),
    );
  }

  void _openAddSheet() => _showExpenseSheet(const AddExpenseSheet());

  void _openEditSheet(ExpenseModel expense) =>
      _showExpenseSheet(AddExpenseSheet(expense: expense));

  Future<void> _renameCategory(
    String category,
    List<String> existingCategories,
  ) async {
    final newName = await showRenameExpenseCategorySheet(
      context,
      currentCategory: category,
      existingCategories: existingCategories,
    );
    if (newName == null || !mounted) return;

    context.read<ExpensesTabBloc>().add(
      RenameExpenseCategoryEvent(fromCategory: category, toCategory: newName),
    );

    if (_selectedCategory == category) {
      setState(() => _selectedCategory = newName);
    }
  }

  Future<void> _removeCategory(String category, int entryCount) async {
    final l10n = AppLocalizations.of(context)!;
    final label = localizeExpenseCategory(l10n, category);

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
              l10n.expenseCategoryRemoveTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.expenseCategoryRemoveMessage(entryCount, label),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColor.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outline),
              title: Text(l10n.expenseCategoryMoveToOther),
              onTap: () => Navigator.pop(sheetContext, 'move'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.errorColor,
              ),
              title: Text(
                l10n.expenseCategoryDeleteAll,
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
      context.read<ExpensesTabBloc>().add(
        RenameExpenseCategoryEvent(fromCategory: category, toCategory: 'Other'),
      );
      if (_selectedCategory == category) {
        setState(() => _selectedCategory = 'Other');
      }
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.expenseCategoryDeleteConfirmTitle),
          content: Text(l10n.expenseCategoryDeleteConfirmMessage(entryCount)),
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
              child: Text(l10n.expenseCategoryDeleteConfirmAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      context.read<ExpensesTabBloc>().add(
        DeleteExpensesByCategoryEvent(category),
      );
      if (_selectedCategory == category) {
        setState(() => _selectedCategory = null);
      }
    }
  }

  Future<void> _showExpenseSheet(Widget sheet) async {
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
          value: context.read<ExpensesTabBloc>(),
          child: sheet,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final message = switch (result) {
      'added' => l10n.expenseAddedSuccess,
      'updated' => l10n.expenseUpdatedSuccess,
      _ => null,
    };
    if (message != null) {
      AppToast.success(context, message);
    }
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  static const _expenseColor = AppColors.expense;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.categoryField,
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
                label: Text(l10n.expenseFilterAllCategories),
                selected: selectedCategory == null,
                onSelected: (_) => onSelected(null),
                selectedColor: _expenseColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selectedCategory == null
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
              ...categories.map((category) {
                final selected = selectedCategory == category;
                final label = localizeExpenseCategory(l10n, category);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => onSelected(category),
                    selectedColor: _expenseColor,
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

class _CategoryBreakdown extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final Map<String, int> categoryEntryCounts;
  final String? selectedCategory;
  final bool isBusy;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onRenameCategory;
  final void Function(String category, int entryCount) onRemoveCategory;

  static const _expenseColor = AppColors.expense;

  const _CategoryBreakdown({
    required this.categoryTotals,
    required this.categoryEntryCounts,
    required this.selectedCategory,
    required this.isBusy,
    required this.onCategorySelected,
    required this.onRenameCategory,
    required this.onRemoveCategory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expenseByCategory,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 10),
        ...categoryTotals.entries.map((entry) {
          final label = localizeExpenseCategory(l10n, entry.key);
          final isSelected = selectedCategory == entry.key;
          final count = categoryEntryCounts[entry.key] ?? 0;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isBusy ? null : () => onCategorySelected(entry.key),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: AppDecorations.card(
                  borderColor: isSelected
                      ? _expenseColor
                      : _expenseColor.withValues(alpha: 0.12),
                ).copyWith(color: isSelected ? AppColors.expenseLight : null),
                child: Row(
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _expenseColor.withValues(alpha: 0.15)
                            : AppColors.expenseLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.filter_alt_rounded
                            : Icons.receipt_outlined,
                        color: _expenseColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.expenseDark
                              : AppColors.textColor,
                        ),
                      ),
                    ),
                    Text(
                      Money.format(entry.value),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _expenseColor,
                      ),
                    ),
                    PopupMenuButton<String>(
                      enabled: !isBusy,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textColor.withValues(alpha: 0.45),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          onRenameCategory(entry.key);
                        } else if (value == 'remove') {
                          onRemoveCategory(entry.key, count);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 20),
                              const SizedBox(width: 10),
                              Text(l10n.expenseCategoryEdit),
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
                                l10n.expenseCategoryRemove,
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
  final String? categoryLabel;

  const _SummaryCard({
    required this.total,
    required this.periodLabel,
    this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ThemedSummaryCard(
      accent: AppColors.expense,
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
                      Icons.trending_down_rounded,
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
              if (categoryLabel != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: on.overlayStrong,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    categoryLabel!,
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
                l10n.totalExpenses,
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

  static const _expenseColor = AppColors.expense;

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
                style: TextButton.styleFrom(foregroundColor: _expenseColor),
                child: Text(l10n.expenseFilterAllCategories),
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

  static const _expenseColor = AppColors.expense;

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
                color: AppColors.expenseLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: _expenseColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noExpensesTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noExpensesSubtitle,
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
              label: Text(l10n.addExpense),
              style: TextButton.styleFrom(foregroundColor: _expenseColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseSortBar extends StatelessWidget {
  final ExpenseListSort sort;
  final ValueChanged<ExpenseListSort> onSortChanged;

  static const _expenseColor = AppColors.expense;

  const _ExpenseSortBar({required this.sort, required this.onSortChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(
          Icons.sort_rounded,
          size: 18,
          color: AppColors.textColor.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text(l10n.expenseSortNewest),
          selected: sort == ExpenseListSort.newest,
          onSelected: (_) => onSortChanged(ExpenseListSort.newest),
          selectedColor: _expenseColor,
          labelStyle: TextStyle(
            color: sort == ExpenseListSort.newest
                ? Colors.white
                : AppColors.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          backgroundColor: AppColors.surface,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text(l10n.expenseSortHighestAmount),
          selected: sort == ExpenseListSort.highestAmount,
          onSelected: (_) => onSortChanged(ExpenseListSort.highestAmount),
          selectedColor: _expenseColor,
          labelStyle: TextStyle(
            color: sort == ExpenseListSort.highestAmount
                ? Colors.white
                : AppColors.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          backgroundColor: AppColors.surface,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
