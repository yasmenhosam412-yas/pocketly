import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';
import 'package:imrpo/features/loans_tab/presentation/bloc/loans_tab_bloc.dart';
import 'package:imrpo/features/year_in_review/domain/year_in_review_calculator.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class YearInReviewScreen extends StatefulWidget {
  const YearInReviewScreen({super.key});

  @override
  State<YearInReviewScreen> createState() => _YearInReviewScreenState();
}

class _YearInReviewScreenState extends State<YearInReviewScreen> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    context.read<ExpensesTabBloc>().add(const LoadExpensesEvent());
    context.read<LoansTabBloc>().add(const LoadLoansEvent());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(l10n.yearInReviewTitle),
        actions: [
          PopupMenuButton<int>(
            initialValue: _year,
            onSelected: (y) => setState(() => _year = y),
            itemBuilder: (_) {
              final now = DateTime.now().year;
              return [
                for (var y = now; y >= now - 4; y--)
                  PopupMenuItem(value: y, child: Text('$y')),
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '$_year',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<IncomesTabBloc, IncomesTabState>(
        builder: (context, incomesState) {
          return BlocBuilder<ExpensesTabBloc, ExpensesTabState>(
            builder: (context, expensesState) {
              return BlocBuilder<LoansTabBloc, LoansTabState>(
                builder: (context, loansState) {
                  final List<Loan> loans = loansState is LoansTabLoaded
                      ? loansState.loans
                      : const <Loan>[];
                  final snapshot = YearInReviewCalculator.build(
                    year: _year,
                    incomes: incomesState.incomes,
                    expenses: expensesState.expenses,
                    loans: loans,
                  );
                  return _YearInReviewBody(snapshot: snapshot);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _YearInReviewBody extends StatelessWidget {
  final YearInReviewSnapshot snapshot;

  const _YearInReviewBody({required this.snapshot});

  String _monthLabel(AppLocalizations l10n, int month) {
    // Keep short English month names; arb can localize later if needed.
    const en = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '$month';
    return en[month];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final empty = snapshot.totalIncome <= 0 && snapshot.totalExpenses <= 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppDecorations.card(
            borderColor: AppColors.primary.withValues(alpha: 0.25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.yearInReviewHero(snapshot.year),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                empty
                    ? l10n.yearInReviewEmpty
                    : l10n.yearInReviewHeroBody(
                        Money.format(snapshot.totalIncome),
                        Money.format(snapshot.totalExpenses),
                      ),
                style: TextStyle(
                  height: 1.45,
                  color: AppColors.textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        if (!empty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: l10n.yearInReviewNet,
                  value: Money.format(snapshot.net),
                  color: snapshot.net >= 0 ? AppColors.income : AppColors.expense,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: l10n.yearInReviewSavingsRate,
                  value: '${(snapshot.savingsRate * 100).toStringAsFixed(0)}%',
                  color: AppColors.primaryInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: l10n.yearInReviewLoansClosed,
                  value: '${snapshot.loansClosed}',
                  color: AppColors.loans,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: l10n.yearInReviewLoansOpen,
                  value: '${snapshot.loansStillOpen}',
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (snapshot.bestMonth != null) ...[
            const SizedBox(height: 14),
            _StoryCard(
              title: l10n.yearInReviewBestMonth,
              body: l10n.yearInReviewMonthNet(
                _monthLabel(l10n, snapshot.bestMonth!),
                Money.format(snapshot.bestMonthNet ?? 0),
              ),
              icon: Icons.trending_up_rounded,
              color: AppColors.income,
            ),
          ],
          if (snapshot.toughestMonth != null) ...[
            const SizedBox(height: 10),
            _StoryCard(
              title: l10n.yearInReviewToughMonth,
              body: l10n.yearInReviewMonthNet(
                _monthLabel(l10n, snapshot.toughestMonth!),
                Money.format(snapshot.toughestMonthNet ?? 0),
              ),
              icon: Icons.trending_down_rounded,
              color: AppColors.expense,
            ),
          ],
          if (snapshot.topCategories.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.yearInReviewTopCategories,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            ...snapshot.topCategories.entries.map(
              (e) => _RankRow(
                label: localizeExpenseCategory(l10n, e.key),
                amount: e.value,
              ),
            ),
          ],
          if (snapshot.topMerchants.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.yearInReviewTopMerchants,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            ...snapshot.topMerchants.entries.map(
              (e) => _RankRow(label: e.key, amount: e.value),
            ),
          ],
          if (snapshot.incomeBySource.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.yearInReviewIncomeSources,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            ...snapshot.incomeBySource.entries.map(
              (e) => _RankRow(
                label: localizeIncomeCategory(l10n, e.key),
                amount: e.value,
                color: AppColors.income,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(
        borderColor: color.withValues(alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textColor.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  const _StoryCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(
        borderColor: color.withValues(alpha: 0.18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    color: AppColors.textColor.withValues(alpha: 0.65),
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

class _RankRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;

  const _RankRow({
    required this.label,
    required this.amount,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecorations.card(borderColor: AppColors.border),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
          ),
          Text(
            Money.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color ?? AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}
