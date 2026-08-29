import 'package:flutter/material.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/statistics_tab/presentation/pages/statistics_tab.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(l10n.tabStatistics),
      ),
      body: const StatisticsTab(),
    );
  }
}
