import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/helpers/association_ledger_access.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/plans_balance_tab_loading_skeleton.dart';
import 'package:imrpo/core/widgets/tab_centered_scroll.dart';
import 'package:imrpo/core/widgets/tab_refresh_overlay.dart';
import 'package:imrpo/features/plans_tab/domain/entities/plan.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/plans_tab/presentation/widgets/add_plan_sheet.dart';
import 'package:imrpo/features/plans_tab/presentation/widgets/plan_list_tile.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class PlansTab extends StatefulWidget {
  const PlansTab({super.key});

  @override
  State<PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends State<PlansTab> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<PlansTabBloc>().add(const LoadPlansEvent());
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
            heroTag: 'fab-plans',
            onPressed: _openAddSheet,
            backgroundColor: AppColors.plans,
            elevation: 4,
            highlightElevation: 6,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              l10n.planNewFab,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          );
        },
      ),
      body: BlocConsumer<PlansTabBloc, PlansTabState>(
        listener: (context, state) {
          if (state is! PlansTabLoaded || state.error.isEmpty) return;
          final listenerL10n = AppLocalizations.of(context)!;

          final showError = switch (state.status) {
            PlansTabStatus.error ||
            PlansTabStatus.errorAdd ||
            PlansTabStatus.errorUpdate ||
            PlansTabStatus.errorDelete ||
            PlansTabStatus.errorUpdateSaved =>
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
          if (blocState is! PlansTabLoaded) {
            return const PlansTabLoadingSkeleton();
          }

          final state = blocState;

          if (!state.hasData && state.status == PlansTabStatus.loading) {
            return const PlansTabLoadingSkeleton();
          }

          if (!state.hasData && state.status == PlansTabStatus.error) {
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
                          .read<PlansTabBloc>()
                          .add(const LoadPlansEvent()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.plans,
                      ),
                      child: Text(l10n.errorTryAgainGeneric),
                    ),
                  ],
                ),
              ),
            );
          }

          final isRefreshing =
              state.status == PlansTabStatus.loading && state.hasData;

          final sorted = List.of(state.plans)
            ..sort((a, b) => b.progress.compareTo(a.progress));
          final remaining = state.totalTarget - state.totalSaved;

          return TabRefreshOverlay(
            isRefreshing: isRefreshing,
            indicatorColor: AppColors.plans,
            child: RefreshIndicator(
              color: AppColors.plans,
              onRefresh: () async {
                context.read<PlansTabBloc>().add(const LoadPlansEvent());
                await Future.delayed(const Duration(milliseconds: 350));
              },
              child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: _DashboardCard(
                      totalSaved: state.totalSaved,
                      totalTarget: state.totalTarget,
                      overallProgress: state.overallProgress,
                      completedCount: state.completedCount,
                      planCount: state.plans.length,
                      remaining: remaining > 0 ? remaining : 0,
                    ),
                  ),
                ),
                if (sorted.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _MiniStatCard(
                              icon: Icons.flag_outlined,
                              label: l10n.plansActive,
                              value: '${state.plans.length - state.completedCount}',
                              color: AppColors.plans,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniStatCard(
                              icon: Icons.check_circle_outline,
                              label: l10n.plansDone,
                              value: '${state.completedCount}',
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniStatCard(
                              icon: Icons.savings_outlined,
                              label: l10n.plansRemaining,
                              value: Money.format(remaining > 0 ? remaining : 0),
                              color: AppColors.plansDark,
                            ),
                          ),
                        ],
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
                            color: AppColors.plans.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.track_changes_rounded,
                            size: 20,
                            color: AppColors.plans,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.plansSavingsGoalsSection,
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
                            '${sorted.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.plans,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (sorted.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(onAdd: _openAddSheet),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final plan = sorted[index];
                          final canEdit = AssociationLedgerAccess.canEdit;
                          return PlanListTile(
                            plan: plan,
                            isDeleting: state.deletingPlanId == plan.id,
                            onTap: canEdit ? () => _openEditSheet(plan) : null,
                            onDelete: canEdit
                                ? () {
                                    context.read<PlansTabBloc>().add(
                                      DeletePlanEvent(plan.id),
                                    );
                                  }
                                : null,
                          );
                        },
                        childCount: sorted.length,
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

  void _openAddSheet() => _showPlanSheet(const AddPlanSheet());

  void _openEditSheet(Plan plan) => _showPlanSheet(AddPlanSheet(plan: plan));

  void _showPlanSheet(Widget sheet) {
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
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<PlansTabBloc>()),
            BlocProvider.value(value: context.read<IncomesTabBloc>()),
          ],
          child: sheet,
        ),
      ),
    );
  }

}

class _DashboardCard extends StatelessWidget {
  final double totalSaved;
  final double totalTarget;
  final double overallProgress;
  final int completedCount;
  final int planCount;
  final double remaining;

  const _DashboardCard({
    required this.totalSaved,
    required this.totalTarget,
    required this.overallProgress,
    required this.completedCount,
    required this.planCount,
    required this.remaining,
  });


  @override
  Widget build(BuildContext context) {
    final progressPercent = (overallProgress * 100).round();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.summaryCard([
        AppColors.plans,
        AppColors.plansDark,
        AppColors.secondary,
      ]),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.plansGoalsOverview,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Money.format(totalSaved),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.plansSavedOfTarget(Money.format(totalTarget)),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 88,
                width: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 88,
                      width: 88,
                      child: CircularProgressIndicator(
                        value: overallProgress,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$progressPercent%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.plansDonePercentLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.plansGoalsCompletedSummary(completedCount, planCount),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  l10n.plansMoneyLeft(Money.format(remaining)),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        boxShadow: [
          BoxShadow(
            color: AppColors.stroke.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.plans.withValues(alpha: 0.12),
                    AppColors.plansDark.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.rocket_launch_outlined,
                size: 48,
                color: AppColors.plans,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.plansEmptyTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.plansEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textColor.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.plans,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  l10n.plansCreateGoalButton,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
