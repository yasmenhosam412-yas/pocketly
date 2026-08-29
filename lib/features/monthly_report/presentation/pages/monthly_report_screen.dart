import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/balance_breakdown_chart.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/balance_category_breakdown.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/balance_stat_tile.dart';
import 'package:imrpo/features/budgets/domain/entities/budget_period.dart';
import 'package:imrpo/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/monthly_report/domain/entities/monthly_report_snapshot.dart';
import 'package:imrpo/features/monthly_report/domain/services/monthly_report_calculator.dart';
import 'package:imrpo/features/monthly_report/presentation/widgets/report_budget_section.dart';
import 'package:imrpo/features/monthly_report/presentation/widgets/report_comparison_card.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  late BudgetPeriod _period;

  @override
  void initState() {
    super.initState();
    _period = BudgetPeriod.fromDateFilter(getIt<HomeDateFilter>());
    _loadBudgets();
  }

  void _loadBudgets() {
    context.read<BudgetsBloc>().add(
      LoadBudgetsEvent(year: _period.year, month: _period.month),
    );
  }

  String _monthLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMM(locale).format(_period.startDate);
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _period.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _period = BudgetPeriod(year: picked.year, month: picked.month);
    });
    _loadBudgets();
  }

  void _shiftMonth(int delta) {
    var period = _period;
    for (var i = 0; i < delta.abs(); i++) {
      period = delta > 0 ? period.next : period.previous;
    }
    final now = DateTime.now();
    if (period.year > now.year ||
        (period.year == now.year && period.month > now.month)) {
      return;
    }
    setState(() => _period = period);
    _loadBudgets();
  }

  Future<void> _refresh() async {
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent(force: true));
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent(force: true));
    context.read<BudgetsBloc>().add(
      LoadBudgetsEvent(year: _period.year, month: _period.month, force: true),
    );
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(
          l10n.monthlyReportTitle,
          style: TextStyle(color: AppColors.textColor, fontSize: 20),
        ),
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.textColor,
        elevation: 0,
      ),
      body: BlocBuilder<IncomesTabBloc, IncomesTabState>(
        builder: (context, incomeState) {
          return BlocBuilder<ExpensesTabBloc, ExpensesTabState>(
            builder: (context, expenseState) {
              return BlocBuilder<BudgetsBloc, BudgetsState>(
                builder: (context, budgetState) {
                  final isLoading =
                      incomeState.status == IncomesTabStatus.loadingAll ||
                      expenseState.status == ExpensesTabStatus.loadingAll ||
                      budgetState.status == BudgetsStatus.loading;

                  final snapshot = MonthlyReportCalculator.build(
                    period: _period,
                    incomes: incomeState.incomes,
                    expenses: expenseState.expenses,
                    budgets: budgetState.budgets,
                  );

                  return Column(
                    children: [
                      _MonthSelectorBar(
                        label: _monthLabel(context),
                        canGoForward: !_period.isCurrentMonth,
                        onPrevious: () => _shiftMonth(-1),
                        onNext: () => _shiftMonth(1),
                        onPick: _pickMonth,
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primaryInk,
                          onRefresh: _refresh,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                            children: [
                              if (isLoading)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryInk,
                                    ),
                                  ),
                                ),
                              _NetHeroCard(snapshot: snapshot),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  BalanceStatTile(
                                    label: l10n.balanceStatIncome,
                                    amount: snapshot.income,
                                    icon: Icons.south_west_rounded,
                                    color: AppColors.income,
                                  ),
                                  const SizedBox(width: 12),
                                  BalanceStatTile(
                                    label: l10n.balanceStatExpense,
                                    amount: snapshot.expenses,
                                    icon: Icons.north_east_rounded,
                                    color: AppColors.expense,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ReportComparisonCard(snapshot: snapshot),
                              const SizedBox(height: 16),
                              BalanceBreakdownChart(
                                income: snapshot.income,
                                expenses: snapshot.expenses,
                              ),
                              const SizedBox(height: 20),
                              if (snapshot.incomeBySource.isNotEmpty) ...[
                                BalanceCategoryBreakdown(
                                  title: l10n.incomeBySource,
                                  totals: snapshot.incomeBySource,
                                  accentColor: AppColors.income,
                                  accentLight: AppColors.incomeLight,
                                  accentDark: AppColors.incomeDark,
                                  selectedKey: null,
                                  onSelected: (_) {},
                                  localizeKey: localizeIncomeCategory,
                                ),
                                const SizedBox(height: 20),
                              ],
                              if (snapshot.expenseByCategory.isNotEmpty) ...[
                                BalanceCategoryBreakdown(
                                  title: l10n.expenseByCategory,
                                  totals: snapshot.expenseByCategory,
                                  accentColor: AppColors.expense,
                                  accentLight: AppColors.expenseLight,
                                  accentDark: AppColors.expenseDark,
                                  selectedKey: null,
                                  onSelected: (_) {},
                                  localizeKey: localizeExpenseCategory,
                                ),
                                const SizedBox(height: 20),
                              ],
                              ReportBudgetSection(rows: snapshot.budgetRows),
                              const SizedBox(height: 12),
                              Text(
                                l10n.monthlyReportEntrySummary(
                                  snapshot.incomeEntryCount,
                                  snapshot.expenseEntryCount,
                                ),
                                textAlign: TextAlign.center,
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
                    ],
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

class _MonthSelectorBar extends StatelessWidget {
  final String label;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  const _MonthSelectorBar({
    required this.label,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
              color: AppColors.textColor,
            ),
            Expanded(
              child: InkWell(
                onTap: onPick,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 20,
                        color: AppColors.primaryInk,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: AppColors.textColor.withValues(alpha: 0.45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: canGoForward ? onNext : null,
              icon: const Icon(Icons.chevron_right_rounded),
              color: AppColors.textColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _NetHeroCard extends StatelessWidget {
  final MonthlyReportSnapshot snapshot;

  const _NetHeroCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final net = snapshot.net;
    final savingsRate = snapshot.savingsRate;
    final isPositive = net >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isPositive ? AppColors.income : AppColors.expense,
            Color.lerp(
              isPositive ? AppColors.income : AppColors.expense,
              AppColors.primary,
              0.35,
            )!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.income : AppColors.expense)
                .withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.balanceNetBalance,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Money.format(net),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.balanceSavedPercent((savingsRate * 100).round()),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
