import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/initial_balance_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/features/balance_tab/domain/services/balance_summary_builder.dart';
import 'package:imrpo/features/balance_tab/domain/services/wallet_balance_calculator.dart';
import 'package:imrpo/features/balance_tab/presentation/widgets/wallet_overview_dialog.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/home/presentation/theme/home_header_theme.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Wallet chip in the home header action row (next to personal / association).
class HomeWalletHeaderButton extends StatelessWidget {
  const HomeWalletHeaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFilter = getIt<HomeDateFilter>();
    final theme = HomeHeaderScope.of(context);

    return BlocBuilder<IncomesTabBloc, IncomesTabState>(
      builder: (context, incomeState) {
        return BlocBuilder<ExpensesTabBloc, ExpensesTabState>(
          builder: (context, expenseState) {
            return ListenableBuilder(
              listenable: Listenable.merge([
                dateFilter,
                getIt<InitialBalanceStore>(),
              ]),
              builder: (context, _) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final summary = BalanceSummaryBuilder.build(
                        incomes: incomeState.incomes,
                        expenses: expenseState.expenses,
                        reference: dateFilter.date,
                        filterByDay: dateFilter.isDayMode,
                        includeAllDates: dateFilter.isAllMode,
                      );
                      final summaries = WalletBalanceCalculator.summaries(
                        activities: summary.activities,
                        initialBySource:
                            getIt<InitialBalanceStore>().totalsBySource,
                      );
                      showWalletOverviewDialog(
                        context,
                        summaries: summaries,
                        periodLabel: dateFilter.summaryPeriodLabel(context),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: theme.chipFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.chipBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: theme.foreground,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.balanceOpenWallet,
                            style: TextStyle(
                              color: theme.foreground,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
