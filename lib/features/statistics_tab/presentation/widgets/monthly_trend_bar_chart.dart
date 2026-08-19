import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/statistics_tab/domain/entities/month_statistics.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class MonthlyTrendBarChart extends StatelessWidget {
  final List<MonthStatistics> months;
  final double maxValue;

  const MonthlyTrendBarChart({
    super.key,
    required this.months,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final scaleMax = maxValue <= 0 ? 1.0 : maxValue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statisticsMonthlyTrend,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: AppColors.income, label: l10n.balanceStatIncome),
              const SizedBox(width: 16),
              _LegendDot(
                color: AppColors.expense,
                label: l10n.balanceStatExpense,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((month) {
                final label = DateFormat.MMM(locale).format(month.period.startDate);
                final incomeH = (month.income / scaleMax) * 130;
                final expenseH = (month.expenses / scaleMax) * 130;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Bar(
                              height: incomeH.clamp(4, 130),
                              color: AppColors.income,
                            ),
                            const SizedBox(width: 4),
                            _Bar(
                              height: expenseH.clamp(4, 130),
                              color: AppColors.expense,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;

  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
