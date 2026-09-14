import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/initial_balance_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/plans_balance_tab_loading_skeleton.dart';
import 'package:imrpo/core/widgets/tab_centered_scroll.dart';
import 'package:imrpo/core/widgets/tab_refresh_overlay.dart';
import 'package:imrpo/features/balance_tab/domain/entities/balance_activity.dart';
import 'package:imrpo/features/balance_tab/domain/entities/balance_summary.dart';
import 'package:imrpo/features/balance_tab/domain/services/balance_summary_builder.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/balance_activity_filter_bar.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/balance_activity_tile.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/balance_breakdown_chart.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/balance_category_breakdown.dart';
import 'package:imrpo/features/balance_tab/domain/services/wallet_balance_calculator.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/balance_wallet_breakdown.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/balance_stat_tile.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/edit_initial_balance_sheet.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/features/balance_tab/domain/balance_source_constants.dart';
import 'package:imrpo/features/budgets/domain/services/budget_calculator.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/plans_tab/presentation/widgets/add_to_plan_from_balance_sheet.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class BalanceTab extends StatefulWidget {
  const BalanceTab({super.key});

  @override
  State<BalanceTab> createState() => _BalanceTabState();
}

class _BalanceTabState extends State<BalanceTab>
    with AutomaticKeepAliveClientMixin {
  BalanceActivityFilter _activityFilter = BalanceActivityFilter.all;
  String? _selectedIncomeSource;
  String? _selectedExpenseCategory;

  @override
  bool get wantKeepAlive => true;

  late final HomeDateFilter _dateFilter;

  static String _categoryKey(BalanceActivity activity) {
    final category = activity.category.trim();
    return category.isEmpty ? 'Other' : category;
  }

  static Map<String, double> _totalsByCategory(
    List<BalanceActivity> activities,
    BalanceActivityType type,
  ) {
    final totals = <String, double>{};
    for (final activity in activities.where((a) => a.type == type)) {
      final key = _categoryKey(activity);
      totals[key] = (totals[key] ?? 0) + activity.amount;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  List<BalanceActivity> _filterActivities(List<BalanceActivity> activities) {
    return activities.where((activity) {
      if (_selectedIncomeSource != null) {
        if (activity.type == BalanceActivityType.income) {
          return _categoryKey(activity) == _selectedIncomeSource;
        }
        if (activity.type == BalanceActivityType.expense) {
          if (_selectedIncomeSource == BalanceSourceConstants.unassigned) {
            final s = activity.incomeSource?.trim();
            return s == null || s.isEmpty;
          }
          final raw = activity.incomeSource?.trim();
          if (raw == null || raw.isEmpty) return false;
          return BudgetCalculator.categoryKey(raw) == _selectedIncomeSource;
        }
        return false;
      }
      if (_selectedExpenseCategory != null) {
        if (activity.type == BalanceActivityType.expense) {
          return _categoryKey(activity) == _selectedExpenseCategory;
        }
        if (activity.type == BalanceActivityType.income) {
          return false;
        }
      }
      if (_activityFilter == BalanceActivityFilter.income &&
          activity.type != BalanceActivityType.income) {
        return false;
      }
      if (_activityFilter == BalanceActivityFilter.expense &&
          activity.type != BalanceActivityType.expense) {
        return false;
      }
      return true;
    }).toList();
  }

  void _clearCategoryFilters() {
    setState(() {
      _selectedIncomeSource = null;
      _selectedExpenseCategory = null;
    });
  }

  void _onWalletSourceSelected(String? source) {
    setState(() {
      _activityFilter = BalanceActivityFilter.all;
      _selectedExpenseCategory = null;
      _selectedIncomeSource = source;
    });
  }

  void _onExpenseCategorySelected(String category) {
    setState(() {
      _activityFilter = BalanceActivityFilter.expense;
      _selectedIncomeSource = null;
      _selectedExpenseCategory =
          _selectedExpenseCategory == category ? null : category;
    });
  }

  void _onActivityFilterChanged(BalanceActivityFilter filter) {
    setState(() {
      _activityFilter = filter;
      if (filter == BalanceActivityFilter.all) {
        _selectedIncomeSource = null;
        _selectedExpenseCategory = null;
      } else if (filter == BalanceActivityFilter.income) {
        _selectedExpenseCategory = null;
        if (_selectedIncomeSource == BalanceSourceConstants.unassigned) {
          _selectedIncomeSource = null;
        }
      } else {
        _selectedIncomeSource = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _dateFilter = getIt<HomeDateFilter>();
  }

  Future<void> _refreshTransactions() async {
    if (!SupabaseAuthHelper.isSignedIn) return;
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent(force: true));
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent(force: true));
    await Future.delayed(const Duration(milliseconds: 350));
  }

  double _netBalance(BalanceSummary summary, double initialBalance) {
    final net = initialBalance + summary.monthlyIncome - summary.monthlyExpenses;
    return net < 0 ? 0 : net;
  }

  double _savingsRate(BalanceSummary summary) {
    if (summary.monthlyIncome <= 0) return 0;
    return ((summary.monthlyIncome - summary.monthlyExpenses) /
            summary.monthlyIncome)
        .clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<IncomesTabBloc, IncomesTabState>(
        builder: (context, incomeState) {
          return BlocBuilder<ExpensesTabBloc, ExpensesTabState>(
            builder: (context, expenseState) {
              final hasData = incomeState.incomes.isNotEmpty ||
                  expenseState.expenses.isNotEmpty;
              final isInitialLoading =
                  (incomeState.status == IncomesTabStatus.loadingAll &&
                      incomeState.incomes.isEmpty) ||
                  (expenseState.status == ExpensesTabStatus.loadingAll &&
                      expenseState.expenses.isEmpty);

              if (isInitialLoading) {
                return const BalanceTabLoadingSkeleton();
              }

              final loadError = !hasData &&
                  (incomeState.status == IncomesTabStatus.errorAll ||
                      expenseState.status == ExpensesTabStatus.errorAll);
              if (loadError) {
                final l10n = AppLocalizations.of(context)!;
                final message = incomeState.status == IncomesTabStatus.errorAll
                    ? incomeState.message
                    : expenseState.error;
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
                          localizeApiError(l10n, message),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _refreshTransactions,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.balance,
                          ),
                          child: Text(l10n.errorTryAgainGeneric),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final isRefreshing =
                  incomeState.status == IncomesTabStatus.loadingAll ||
                  expenseState.status == ExpensesTabStatus.loadingAll;

              final l10n = AppLocalizations.of(context)!;

              return ListenableBuilder(
                listenable: Listenable.merge([
                  _dateFilter,
                  getIt<InitialBalanceStore>(),
                ]),
                builder: (context, _) {
                  final summary = BalanceSummaryBuilder.build(
                    incomes: incomeState.incomes,
                    expenses: expenseState.expenses,
                    reference: _dateFilter.date,
                    filterByDay: _dateFilter.isDayMode,
                    includeAllDates: _dateFilter.isAllMode,
                  );
                  final initialBalance = getIt<InitialBalanceStore>().amount;
                  final initialBySource =
                      getIt<InitialBalanceStore>().totalsBySource;
                  final netBalance = _netBalance(summary, initialBalance);
                  final periodLabel = _dateFilter.summaryPeriodLabel(context);

                  final sorted = List.of(summary.activities)
                    ..sort((a, b) => b.date.compareTo(a.date));
                  final incomeGrossBySource =
                      _totalsByCategory(sorted, BalanceActivityType.income);
                  final walletSummaries = WalletBalanceCalculator.summaries(
                    activities: sorted,
                    initialBySource: initialBySource,
                  );
                  final expenseByCategory =
                      _totalsByCategory(sorted, BalanceActivityType.expense);
                  final filteredActivities = _filterActivities(sorted);
                  final incomeFilterChipSources =
                      incomeGrossBySource.keys.toList()..sort();
                  final expenseCategories =
                      expenseByCategory.keys.toList()..sort();
                  final activeIncomeSource =
                      _selectedIncomeSource != null &&
                          walletSummaries.any(
                            (row) => row.source == _selectedIncomeSource,
                          )
                      ? _selectedIncomeSource
                      : null;
                  final activeExpenseCategory =
                      _selectedExpenseCategory != null &&
                          expenseCategories.contains(_selectedExpenseCategory)
                      ? _selectedExpenseCategory
                      : null;

                  return TabRefreshOverlay(
                    isRefreshing: isRefreshing && hasData,
                    indicatorColor: AppColors.balance,
                    child: RefreshIndicator(
                      color: AppColors.balance,
                      onRefresh: _refreshTransactions,
                      child: CustomScrollView(
                        physics: kHomeTabScrollPhysics,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                              child: _NetBalanceCard(
                                balance: netBalance,
                                initialBalance: initialBalance,
                                initialBySource: initialBySource,
                                savingsRate: _savingsRate(summary),
                                periodLabel: periodLabel,
                                onEditInitialBalance: () =>
                                    showEditInitialBalanceSheet(context),
                                onAddToPlan: () =>
                                    showAddToPlanFromBalanceSheet(context),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                              child: Row(
                                children: [
                                  BalanceStatTile(
                                    label: l10n.balanceStatIncome,
                                    amount: summary.monthlyIncome,
                                    icon: Icons.trending_up_rounded,
                                    color: AppColors.income,
                                  ),
                                  const SizedBox(width: 12),
                                  BalanceStatTile(
                                    label: l10n.balanceStatExpense,
                                    amount: summary.monthlyExpenses,
                                    icon: Icons.trending_down_rounded,
                                    color: AppColors.expense,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (walletSummaries.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                child: BalanceWalletBreakdown(
                                  summaries: walletSummaries,
                                  selectedSource: activeIncomeSource,
                                  onSourceSelected: _onWalletSourceSelected,
                                  localizeKey: localizeIncomeCategory,
                                ),
                              ),
                            ),
                          if (expenseByCategory.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                child: BalanceCategoryBreakdown(
                                  title: l10n.expenseByCategory,
                                  totals: expenseByCategory,
                                  accentColor: AppColors.expense,
                                  accentLight: AppColors.expenseLight,
                                  accentDark: AppColors.expenseDark,
                                  selectedKey: activeExpenseCategory,
                                  onSelected: _onExpenseCategorySelected,
                                  localizeKey: localizeExpenseCategory,
                                ),
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                              child: BalanceBreakdownChart(
                                income: summary.monthlyIncome,
                                expenses: summary.monthlyExpenses,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        l10n.balanceRecentActivity,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textColor,
                                        ),
                                      ),
                                      Text(
                                        l10n.itemsCount(filteredActivities.length),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textColor
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  BalanceActivityFilterBar(
                                    selected: _activityFilter,
                                    onTypeChanged: _onActivityFilterChanged,
                                  ),
                                  if (_activityFilter ==
                                          BalanceActivityFilter.income &&
                                      incomeFilterChipSources.length > 1) ...[
                                    const SizedBox(height: 12),
                                    BalanceCategoryFilterChips(
                                      categories: incomeFilterChipSources,
                                      selectedCategory: activeIncomeSource ==
                                              BalanceSourceConstants.unassigned
                                          ? null
                                          : activeIncomeSource,
                                      accentColor: AppColors.income,
                                      allLabel: l10n.incomeFilterAllSources,
                                      onSelected: (source) {
                                        setState(
                                          () => _selectedIncomeSource = source,
                                        );
                                      },
                                      localizeKey: localizeIncomeCategory,
                                    ),
                                  ],
                                  if (_activityFilter ==
                                          BalanceActivityFilter.expense &&
                                      expenseCategories.length > 1) ...[
                                    const SizedBox(height: 12),
                                    BalanceCategoryFilterChips(
                                      categories: expenseCategories,
                                      selectedCategory: activeExpenseCategory,
                                      accentColor: AppColors.expense,
                                      allLabel: l10n.expenseFilterAllCategories,
                                      onSelected: (category) {
                                        setState(
                                          () => _selectedExpenseCategory =
                                              category,
                                        );
                                      },
                                      localizeKey: localizeExpenseCategory,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (filteredActivities.isEmpty && sorted.isNotEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.filter_alt_off_outlined,
                                        size: 48,
                                        color: AppColors.textColor.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.balanceNoFilteredActivity,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: AppColors.textColor.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _activityFilter =
                                                BalanceActivityFilter.all;
                                            _clearCategoryFilters();
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.balance,
                                        ),
                                        child: Text(l10n.balanceFilterAll),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => BalanceActivityTile(
                                    activity: filteredActivities[index],
                                  ),
                                  childCount: filteredActivities.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NetBalanceCard extends StatelessWidget {
  final double balance;
  final double initialBalance;
  final Map<String, double> initialBySource;
  final double savingsRate;
  final String periodLabel;
  final VoidCallback onEditInitialBalance;
  final VoidCallback? onAddToPlan;

  const _NetBalanceCard({
    required this.balance,
    required this.initialBalance,
    required this.initialBySource,
    required this.savingsRate,
    required this.periodLabel,
    required this.onEditInitialBalance,
    this.onAddToPlan,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final l10n = AppLocalizations.of(context)!;

    return ThemedSummaryCard(
      accent: isPositive ? AppColors.balance : AppColors.expense,
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
                  color: on.foreground.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: on.foreground,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: on.foreground.withValues(alpha: 0.2),
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
          const SizedBox(height: 20),
          Text(
            l10n.balanceNetBalance,
            style: TextStyle(
              color: on.foreground.withValues(alpha: 0.85),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${isPositive ? '' : '-'}${Money.format(balance.abs())}',
            style: TextStyle(
              color: on.foreground,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEditInitialBalance,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: on.foreground.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: on.foreground.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.balanceInitialBalanceTitle,
                            style: TextStyle(
                              color: on.foreground.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          Money.format(initialBalance),
                          style: TextStyle(
                            color: on.foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: on.foreground.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                    if (initialBySource.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...initialBySource.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  localizeIncomeCategory(l10n, entry.key),
                                  style: TextStyle(
                                    color:
                                        on.foreground.withValues(alpha: 0.82),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                Money.format(entry.value),
                                style: TextStyle(
                                  color: on.foreground.withValues(alpha: 0.95),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: savingsRate,
              minHeight: 6,
              backgroundColor: on.foreground.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation<Color>(on.foreground),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.balanceSavedPercent((savingsRate * 100).round()),
            style: TextStyle(
              color: on.foreground.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          if (onAddToPlan != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddToPlan,
                style: OutlinedButton.styleFrom(
                  foregroundColor: on.foreground,
                  side: BorderSide(color: on.foreground.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.savings_outlined, size: 20),
                label: Text(
                  l10n.balanceAddToPlan,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
          );
        },
      ),
    );
  }
}
