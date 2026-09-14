import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/helpers/association_ledger_access.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/plans_balance_tab_loading_skeleton.dart';
import 'package:imrpo/core/widgets/tab_centered_scroll.dart';
import 'package:imrpo/core/widgets/tab_refresh_overlay.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';
import 'package:imrpo/features/loans_tab/presentation/bloc/loans_tab_bloc.dart';
import 'package:imrpo/features/loans_tab/presentation/widgets/add_loan_sheet.dart';
import 'package:imrpo/features/loans_tab/presentation/widgets/loan_list_tile.dart';
import 'package:imrpo/features/loans_tab/presentation/widgets/record_loan_payment_sheet.dart';
import 'package:imrpo/features/loans_tab/presentation/widgets/wallet_split_sheet.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class LoansTab extends StatefulWidget {
  const LoansTab({super.key});

  @override
  State<LoansTab> createState() => _LoansTabState();
}

class _LoansTabState extends State<LoansTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<LoansTabBloc>().add(const LoadLoansEvent());
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
            heroTag: 'fab-loans',
            onPressed: _openFabMenu,
            backgroundColor: AppColors.loans,
            elevation: 4,
            highlightElevation: 6,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              l10n.loanNewFab,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          );
        },
      ),
      body: BlocConsumer<LoansTabBloc, LoansTabState>(
        listener: (context, state) {
          if (state is! LoansTabLoaded || state.error.isEmpty) return;
          final listenerL10n = AppLocalizations.of(context)!;

          final showError = switch (state.status) {
            LoansTabStatus.error ||
            LoansTabStatus.errorAdd ||
            LoansTabStatus.errorUpdate ||
            LoansTabStatus.errorDelete ||
            LoansTabStatus.errorUpdateSaved =>
              true,
            _ => false,
          };

          if (showError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizeApiError(listenerL10n, state.error)),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, blocState) {
          if (blocState is! LoansTabLoaded) {
            return const PlansTabLoadingSkeleton();
          }

          final state = blocState;

          if (!state.hasData && state.status == LoansTabStatus.loading) {
            return const PlansTabLoadingSkeleton();
          }

          if (!state.hasData && state.status == LoansTabStatus.error) {
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
                      onPressed: () => context
                          .read<LoansTabBloc>()
                          .add(const LoadLoansEvent()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.loans,
                      ),
                      child: Text(l10n.errorTryAgainGeneric),
                    ),
                  ],
                ),
              ),
            );
          }

          final isRefreshing =
              state.status == LoansTabStatus.loading && state.hasData;
          final visible = List.of(state.visibleLoans)
            ..sort((a, b) {
              if (a.isSettled != b.isSettled) {
                return a.isSettled ? 1 : -1;
              }
              if (a.isOverdue != b.isOverdue) {
                return a.isOverdue ? -1 : 1;
              }
              return a.personName.toLowerCase().compareTo(
                b.personName.toLowerCase(),
              );
            });

          return TabRefreshOverlay(
            isRefreshing: isRefreshing,
            indicatorColor: AppColors.loans,
            child: RefreshIndicator(
              color: AppColors.loans,
              onRefresh: () async {
                context.read<LoansTabBloc>().add(const LoadLoansEvent());
                await Future.delayed(const Duration(milliseconds: 350));
              },
              child: CustomScrollView(
                physics: kHomeTabScrollPhysics,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: _DashboardCard(
                        owedToYou: state.owedToYou,
                        youOwe: state.youOwe,
                        netPosition: state.netPosition,
                      ),
                    ),
                  ),
                  if (state.hasData)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.handshake_outlined,
                                label: l10n.loanOpenCount,
                                value: '${state.openCount}',
                                color: AppColors.loans,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.warning_amber_rounded,
                                label: l10n.loanOverdueCount,
                                value: '${state.overdueCount}',
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniStatCard(
                                icon: Icons.check_circle_outline,
                                label: l10n.loanSettledCount,
                                value: '${state.settledCount}',
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: l10n.loanFilterAll,
                              selected: state.filter == LoansFilter.all,
                              onTap: () => context.read<LoansTabBloc>().add(
                                const SetLoansFilterEvent(LoansFilter.all),
                              ),
                            ),
                            _FilterChip(
                              label: l10n.loanFilterGiven,
                              selected: state.filter == LoansFilter.given,
                              onTap: () => context.read<LoansTabBloc>().add(
                                const SetLoansFilterEvent(LoansFilter.given),
                              ),
                            ),
                            _FilterChip(
                              label: l10n.loanFilterReceived,
                              selected: state.filter == LoansFilter.received,
                              onTap: () => context.read<LoansTabBloc>().add(
                                const SetLoansFilterEvent(
                                  LoansFilter.received,
                                ),
                              ),
                            ),
                            _FilterChip(
                              label: l10n.loanFilterOverdue,
                              selected: state.filter == LoansFilter.overdue,
                              onTap: () => context.read<LoansTabBloc>().add(
                                const SetLoansFilterEvent(LoansFilter.overdue),
                              ),
                            ),
                            _FilterChip(
                              label: l10n.loanFilterSettled,
                              selected: state.filter == LoansFilter.settled,
                              onTap: () => context.read<LoansTabBloc>().add(
                                const SetLoansFilterEvent(LoansFilter.settled),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.loans.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance_rounded,
                              size: 20,
                              color: AppColors.loans,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.loansSectionTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '${visible.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.loans,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!state.hasData)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(onAdd: _openAddSheet),
                    )
                  else if (visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            l10n.loanFilterEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textColor.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final loan = visible[index];
                            final canEdit = AssociationLedgerAccess.canEdit;
                            return LoanListTile(
                              loan: loan,
                              isDeleting: state.deletingLoanId == loan.id,
                              onTap: canEdit
                                  ? () => _openEditSheet(loan)
                                  : null,
                              onRecordPayment: canEdit && !loan.isSettled
                                  ? () => _openPaymentSheet(loan)
                                  : null,
                              onDelete: canEdit
                                  ? () {
                                      context.read<LoansTabBloc>().add(
                                        DeleteLoanEvent(loan.id),
                                      );
                                    }
                                  : null,
                            );
                          },
                          childCount: visible.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openFabMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.loans.withValues(alpha: 0.15),
                    child: const Icon(Icons.handshake_outlined,
                        color: AppColors.loans),
                  ),
                  title: Text(l10n.loanAddTitle),
                  subtitle: Text(l10n.loanEmptySubtitle),
                  onTap: () => Navigator.pop(ctx, 'loan'),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.income.withValues(alpha: 0.15),
                    child: Icon(Icons.qr_code_2_rounded,
                        color: AppColors.income),
                  ),
                  title: Text(l10n.walletSplitTitle),
                  subtitle: Text(l10n.walletSplitFabSubtitle),
                  onTap: () => Navigator.pop(ctx, 'split'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || choice == null) return;
    if (choice == 'loan') {
      _openAddSheet();
    } else if (choice == 'split') {
      _openSplitSheet();
    }
  }

  void _openAddSheet() => _showLoanSheet(const AddLoanSheet());

  void _openEditSheet(Loan loan) => _showLoanSheet(AddLoanSheet(loan: loan));

  void _openPaymentSheet(Loan loan) =>
      _showLoanSheet(RecordLoanPaymentSheet(loan: loan));

  Future<void> _openSplitSheet() async {
    final message = await showModalBottomSheet<String>(
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
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<LoansTabBloc>()),
            BlocProvider.value(value: context.read<ExpensesTabBloc>()),
            BlocProvider.value(value: context.read<IncomesTabBloc>()),
          ],
          child: const WalletSplitSheet(),
        ),
      ),
    );
    if (!mounted || message == null || message.isEmpty) return;
    AppToast.show(context, message);
  }

  void _showLoanSheet(Widget sheet) {
    showModalBottomSheet(
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
          value: context.read<LoansTabBloc>(),
          child: sheet,
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final double owedToYou;
  final double youOwe;
  final double netPosition;

  const _DashboardCard({
    required this.owedToYou,
    required this.youOwe,
    required this.netPosition,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ThemedSummaryCard(
      accent: AppColors.loans,
      padding: const EdgeInsets.all(22),
      child: Builder(
        builder: (context) {
          final on = SummaryCardColors.of(context);
          return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.loanOverview,
            style: TextStyle(
              color: on.foreground.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Money.format(netPosition.abs()),
            style: TextStyle(
              color: on.foreground,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            netPosition >= 0 ? l10n.loanNetPositive : l10n.loanNetNegative,
            style: TextStyle(
              color: on.foreground.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: on.foreground.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: on.foreground.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.loanOwedToYou,
                        style: TextStyle(
                          color: on.foreground.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Money.format(owedToYou),
                        style: TextStyle(
                          color: on.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.loanYouOwe,
                        style: TextStyle(
                          color: on.foreground.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Money.format(youOwe),
                        style: TextStyle(
                          color: on.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
          );
        },
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textColor.withValues(alpha: 0.5),
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
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.loans,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textColor,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppColors.surface,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
    final canEdit = AssociationLedgerAccess.canEdit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 56,
            color: AppColors.loans.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.loanEmptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.loanEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textColor.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.loanNewFab),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.loans,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
