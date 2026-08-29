import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/tab_refresh_overlay.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/balance_breakdown_chart.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/balance_stat_tile.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/statistics_tab/domain/services/statistics_calculator.dart';
import 'package:imrpo/features/statistics_tab/presentation/widgets/category_bar_chart.dart';
import 'package:imrpo/features/statistics_tab/presentation/widgets/monthly_trend_bar_chart.dart';
import 'package:imrpo/features/statistics_tab/presentation/widgets/net_trend_chart.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {

  @override
  void initState() {
    super.initState();
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent());
  }

  Future<void> _refresh() async {
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent(force: true));
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent(force: true));
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<IncomesTabBloc, IncomesTabState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.incomes != curr.incomes,
      builder: (context, incomeState) {
        return BlocBuilder<ExpensesTabBloc, ExpensesTabState>(
          buildWhen: (prev, curr) =>
              prev.status != curr.status ||
              prev.expenses != curr.expenses,
          builder: (context, expenseState) {
            final loading = incomeState.status == IncomesTabStatus.loadingAll ||
                expenseState.status == ExpensesTabStatus.loadingAll;
            final snapshot = StatisticsCalculator.build(
              incomes: incomeState.incomes,
              expenses: expenseState.expenses,
            );

            final isRefreshing = loading;

            return TabRefreshOverlay(
              isRefreshing: isRefreshing,
              indicatorColor: AppColors.secondary,
              child: RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: _refresh,
                child: loading && !snapshot.hasData
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.35,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (!snapshot.hasData)
                            _EmptyStatistics(message: l10n.statisticsEmpty)
                          else ...[
                            _PeriodBanner(label: l10n.statisticsLast3Months),
                            const SizedBox(height: 12),
                            ListenableBuilder(
                              listenable: getIt<CurrencyPreferences>(),
                              builder: (context, _) {
                                return Row(
                                  children: [
                                    BalanceStatTile(
                                      label: l10n.statisticsTotalIncome,
                                      amount: snapshot.totalIncome,
                                      icon: Icons.south_west_rounded,
                                      color: AppColors.income,
                                    ),
                                    const SizedBox(width: 10),
                                    BalanceStatTile(
                                      label: l10n.statisticsTotalExpenses,
                                      amount: snapshot.totalExpenses,
                                      icon: Icons.north_east_rounded,
                                      color: AppColors.expense,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            ListenableBuilder(
                              listenable: getIt<CurrencyPreferences>(),
                              builder: (context, _) {
                                final net = snapshot.totalNet;
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: AppDecorations.card(
                                    borderColor: (net >= 0
                                            ? AppColors.income
                                            : AppColors.expense)
                                        .withValues(alpha: 0.25),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        net >= 0
                                            ? Icons.trending_up_rounded
                                            : Icons.trending_down_rounded,
                                        color: net >= 0
                                            ? AppColors.income
                                            : AppColors.expense,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.statisticsNet3Months,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textColor
                                                    .withValues(alpha: 0.55),
                                              ),
                                            ),
                                            Text(
                                              Money.format(net),
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: net >= 0
                                                    ? AppColors.income
                                                    : AppColors.expense,
                                              ),
                                            ),
                                            Text(
                                              l10n.statisticsAvgMonthlyNet(
                                                Money.format(
                                                  snapshot.averageMonthlyNet,
                                                ),
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textColor
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            MonthlyTrendBarChart(
                              months: snapshot.months,
                              maxValue: snapshot.maxMonthlyValue,
                            ),
                            const SizedBox(height: 16),
                            NetTrendChart(months: snapshot.months),
                            const SizedBox(height: 16),
                            ListenableBuilder(
                              listenable: getIt<CurrencyPreferences>(),
                              builder: (context, _) {
                                return BalanceBreakdownChart(
                                  income: snapshot.totalIncome,
                                  expenses: snapshot.totalExpenses,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            CategoryBarChart(
                              title: l10n.statisticsTopExpenses,
                              totals: snapshot.expenseByCategory,
                              accentColor: AppColors.expense,
                              localizeKey: localizeExpenseCategory,
                            ),
                            const SizedBox(height: 16),
                            CategoryBarChart(
                              title: l10n.statisticsTopIncomeSources,
                              totals: snapshot.incomeBySource,
                              accentColor: AppColors.income,
                              localizeKey: localizeIncomeCategory,
                            ),
                          ],
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PeriodBanner extends StatelessWidget {
  final String label;

  const _PeriodBanner({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 20,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStatistics extends StatelessWidget {
  final String message;

  const _EmptyStatistics({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 48,
            color: AppColors.textColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textColor.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
