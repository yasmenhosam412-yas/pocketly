import 'package:flutter/material.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class CategoryBarChart extends StatelessWidget {
  final String title;
  final Map<String, double> totals;
  final Color accentColor;
  final String Function(AppLocalizations l10n, String key) localizeKey;

  const CategoryBarChart({
    super.key,
    required this.title,
    required this.totals,
    required this.accentColor,
    required this.localizeKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (totals.isEmpty) return const SizedBox.shrink();

    final max = totals.values.fold<double>(0, (m, v) => v > m ? v : m);
    final scale = max <= 0 ? 1.0 : max;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 14),
          ...totals.entries.map((entry) {
            final label = localizeKey(l10n, entry.key);
            final ratio = entry.value / scale;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor,
                          ),
                        ),
                      ),
                      Text(
                        Money.format(entry.value),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.05, 1.0),
                        backgroundColor: AppColors.surface,
                        color: accentColor,
                        minHeight: 8,
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
