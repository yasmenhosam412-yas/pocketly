import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/statistics_tab/domain/entities/month_statistics.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Net income − expenses per month (last 3 months).
class NetTrendChart extends StatelessWidget {
  final List<MonthStatistics> months;

  const NetTrendChart({super.key, required this.months});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final maxAbs = months.fold<double>(
      0,
      (max, m) {
        final abs = m.net.abs();
        return abs > max ? abs : max;
      },
    );
    final scale = maxAbs <= 0 ? 1.0 : maxAbs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(
        borderColor: AppColors.secondary.withValues(alpha: 0.25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statisticsNetPerMonth,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          ...months.map((month) {
            final label =
                DateFormat.yMMM(locale).format(month.period.startDate);
            final net = month.net;
            final ratio = (net.abs() / scale).clamp(0.0, 1.0);
            final positive = net >= 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                AppColors.textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Text(
                        Money.format(net),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: positive ? AppColors.income : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 10,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final barWidth = constraints.maxWidth * ratio;
                          return Stack(
                            children: [
                              Container(
                                width: constraints.maxWidth,
                                color: AppColors.surface,
                              ),
                              Container(
                                width: barWidth.clamp(0, constraints.maxWidth),
                                color: (positive
                                        ? AppColors.income
                                        : AppColors.expense)
                                    .withValues(alpha: 0.85),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
