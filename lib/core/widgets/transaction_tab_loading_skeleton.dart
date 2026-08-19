import 'package:flutter/material.dart';
import 'package:imrpo/core/services/home_date_filter.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Full-tab placeholder while incomes or expenses are first loading.
class TransactionTabLoadingSkeleton extends StatelessWidget {
  final bool forIncome;

  const TransactionTabLoadingSkeleton({
    super.key,
    required this.forIncome,
  });

  @override
  Widget build(BuildContext context) {
    final accent = forIncome ? AppColors.income : AppColors.expense;
    final gradient = forIncome
        ? [AppColors.incomeDark, AppColors.income, AppColors.incomeBill]
        : [AppColors.expenseDark, AppColors.expense, AppColors.primary];
    final icon = forIncome
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final amountSample = forIncome ? '+0.00' : '-0.00';
    final l10n = AppLocalizations.of(context)!;
    final periodLabel = getIt<HomeDateFilter>().summaryPeriodLabel(context);

    return Skeletonizer(
      enabled: true,
      ignoreContainers: true,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: _MockSummaryCard(
                gradient: gradient,
                trendIcon: forIncome
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                label: forIncome ? l10n.totalIncome : l10n.totalExpenses,
                periodLabel: periodLabel,
                amountPreview: Money.format(0),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _MockListRow(
                  accentColor: accent,
                  listIcon: icon,
                  amountSample: amountSample,
                ),
                childCount: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockSummaryCard extends StatelessWidget {
  final List<Color> gradient;
  final IconData trendIcon;
  final String label;
  final String periodLabel;
  final String amountPreview;

  const _MockSummaryCard({
    required this.gradient,
    required this.trendIcon,
    required this.label,
    required this.periodLabel,
    required this.amountPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.summaryCard(gradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  trendIcon,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  periodLabel,
                  style: TextStyle(
                    color: AppColors.card,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amountPreview,
            style: TextStyle(
              color: AppColors.card,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockListRow extends StatelessWidget {
  final Color accentColor;
  final IconData listIcon;
  final String amountSample;

  const _MockListRow({
    required this.accentColor,
    required this.listIcon,
    required this.amountSample,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecorations.card(
        borderColor: accentColor.withValues(alpha: 0.15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(listIcon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Source or category name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Note or detail line',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    color: AppColors.textColor.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jan 1',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textColor.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amountSample,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: accentColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dim overlay with a spinner while bulk clear or similar tab work runs.
class TabBusyOverlay extends StatelessWidget {
  final Color indicatorColor;

  const TabBusyOverlay({
    super.key,
    required this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: AppColors.scaffold.withValues(alpha: 0.72),
          child: Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: indicatorColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
