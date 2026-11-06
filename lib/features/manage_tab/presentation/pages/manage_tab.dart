import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/expenses_tab/data/models/expense_model.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/expenses_tab/presentation/widgets/daily_budget_card.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Spending overview: budget card + period insights + bar chart + daily list.
class ManageTab extends StatefulWidget {
  const ManageTab({super.key});

  @override
  State<ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<ManageTab> {
  static const _ranges = [7, 14, 30];

  int _range = 7;
  int? _selectedIndex; // index into the current period's items (0 = today)

  DateTime _localDate(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  double _toEgp(double amount) => CurrencyConverter.fromBase(amount, 'EGP');

  /// Groups all expenses by local day, converted to EGP, in a single pass.
  Map<DateTime, double> _totalsByDay(List<ExpenseModel> expenses) {
    final map = <DateTime, double>{};
    for (final e in expenses) {
      final key = _localDate(e.date);
      map[key] = (map[key] ?? 0) + _toEgp(e.amount);
    }
    return map;
  }

  _PeriodStats _buildStats(List<ExpenseModel> expenses) {
    final byDay = _totalsByDay(expenses);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime dayAt(int offset) =>
        DateTime(today.year, today.month, today.day - offset);

    // items[0] = today, items[1] = yesterday, ...
    final items = List.generate(_range, (i) {
      final d = dayAt(i);
      return _DailyExpense(date: d, amount: byDay[d] ?? 0);
    });

    double previousTotal = 0;
    for (var i = _range; i < _range * 2; i++) {
      previousTotal += byDay[dayAt(i)] ?? 0;
    }

    final total = items.fold<double>(0, (s, e) => s + e.amount);
    final maxAmount = items.fold<double>(0, (m, e) => math.max(m, e.amount));

    int? peakIndex;
    if (maxAmount > 0) {
      peakIndex = items.indexWhere((e) => e.amount == maxAmount);
    }

    // Consecutive no-spend days counting back from today.
    var streak = 0;
    for (final item in items) {
      if (item.amount > 0) break;
      streak++;
    }

    return _PeriodStats(
      items: items,
      total: total,
      previousTotal: previousTotal,
      average: total / _range,
      maxAmount: maxAmount,
      peakIndex: peakIndex,
      noSpendDays: items.where((e) => e.amount == 0).length,
      noSpendStreak: streak,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ExpensesTabBloc, ExpensesTabState>(
        builder: (context, state) {
          final stats = _buildStats(state.expenses);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                DailyBudgetCard(expenses: state.expenses),
                const SizedBox(height: 8),
                _RangeSelector(
                  ranges: _ranges,
                  selected: _range,
                  onChanged: (value) => setState(() {
                    _range = value;
                    _selectedIndex = null;
                  }),
                ),
                _InsightsCard(stats: stats, range: _range),
                _SpendingChartCard(
                  stats: stats,
                  selectedIndex: _selectedIndex,
                  onSelect: (i) => setState(
                    () => _selectedIndex = _selectedIndex == i ? null : i,
                  ),
                ),
                _DailyExpensesList(
                  stats: stats,
                  selectedIndex: _selectedIndex,
                  onSelect: (i) => setState(
                    () => _selectedIndex = _selectedIndex == i ? null : i,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class _DailyExpense {
  final DateTime date;
  final double amount;

  const _DailyExpense({required this.date, required this.amount});
}

class _PeriodStats {
  final List<_DailyExpense> items; // 0 = today
  final double total;
  final double previousTotal;
  final double average;
  final double maxAmount;
  final int? peakIndex;
  final int noSpendDays;
  final int noSpendStreak;

  const _PeriodStats({
    required this.items,
    required this.total,
    required this.previousTotal,
    required this.average,
    required this.maxAmount,
    required this.peakIndex,
    required this.noSpendDays,
    required this.noSpendStreak,
  });

  /// % change vs. previous period, or null if there is nothing to compare to.
  double? get changePercent =>
      previousTotal > 0 ? (total - previousTotal) / previousTotal * 100 : null;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

bool _isArabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

String _t(BuildContext context, String en, String ar) =>
    _isArabic(context) ? ar : en;

String _fmtAmount(AppLocalizations l10n, double value) =>
    l10n.egpAmount(NumberFormat('#,##0.##', 'en_US').format(value));

BoxDecoration _cardDecoration(dynamic palette) => BoxDecoration(
  color: palette.card,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: palette.stroke.withValues(alpha: 0.22)),
);

// ---------------------------------------------------------------------------
// Range selector (7 / 14 / 30 days)
// ---------------------------------------------------------------------------

class _RangeSelector extends StatelessWidget {
  final List<int> ranges;
  final int selected;
  final ValueChanged<int> onChanged;

  const _RangeSelector({
    required this.ranges,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          for (final r in ranges) ...[
            ChoiceChip(
              label: Text(_t(context, '$r days', '$r يوم')),
              selected: r == selected,
              onSelected: (_) => onChanged(r),
              showCheckmark: false,
              selectedColor: primary.withValues(alpha: 0.18),
              backgroundColor: palette.card,
              labelStyle: TextStyle(
                color: r == selected ? primary : palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: palette.stroke.withValues(alpha: 0.22)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Insights: total, trend, average, peak day, no-spend days
// ---------------------------------------------------------------------------

class _InsightsCard extends StatelessWidget {
  final _PeriodStats stats;
  final int range;

  const _InsightsCard({required this.stats, required this.range});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.appPalette;
    final locale = Localizations.localeOf(context).toString();
    final change = stats.changePercent;

    // Spending less than the previous period is good news.
    final trendColor = change == null
        ? palette.textMuted
        : (change <= 0 ? Colors.green.shade600 : Colors.red.shade400);

    final peak = stats.peakIndex == null ? null : stats.items[stats.peakIndex!];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(context, 'Last $range days', 'آخر $range يوم'),
            style: TextStyle(color: palette.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _fmtAmount(l10n, stats.total),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        change <= 0
                            ? Icons.trending_down_rounded
                            : Icons.trending_up_rounded,
                        size: 16,
                        color: trendColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${change.abs().toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: trendColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (change != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _t(
                  context,
                  'vs previous $range days',
                  'مقارنة بالـ $range يوم السابقة',
                ),
                style: TextStyle(color: palette.textMuted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatTile(
                icon: Icons.show_chart_rounded,
                label: _t(context, 'Daily average', 'المتوسط اليومي'),
                value: _fmtAmount(l10n, stats.average),
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.local_fire_department_rounded,
                label: _t(context, 'Highest day', 'أعلى يوم'),
                value: peak == null ? '—' : _fmtAmount(l10n, peak.amount),
                caption: peak == null
                    ? null
                    : DateFormat('EEE d MMM', locale).format(peak.date),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatTile(
                icon: Icons.savings_rounded,
                label: _t(context, 'No-spend days', 'أيام بدون إنفاق'),
                value: '${stats.noSpendDays} / $range',
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.bolt_rounded,
                label: _t(context, 'Current streak', 'السلسلة الحالية'),
                value: _t(
                  context,
                  '${stats.noSpendStreak} day${stats.noSpendStreak == 1 ? '' : 's'}',
                  '${stats.noSpendStreak} يوم',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? caption;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.stroke.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: palette.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (caption != null)
              Text(
                caption!,
                style: TextStyle(color: palette.textMuted, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bar chart (no extra packages). Oldest day on the left, today on the right.
// ---------------------------------------------------------------------------

class _SpendingChartCard extends StatelessWidget {
  final _PeriodStats stats;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const _SpendingChartCard({
    required this.stats,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const double _chartHeight = 110;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.appPalette;
    final primary = Theme.of(context).colorScheme.primary;
    final locale = Localizations.localeOf(context).toString();

    final count = stats.items.length;
    final showWeekdayLabels = count <= 7;

    final selected = selectedIndex == null ? null : stats.items[selectedIndex!];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: palette.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t(context, 'Spending trend', 'اتجاه الإنفاق'),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 20,
            child: Text(
              selected == null
                  ? _t(
                      context,
                      'Tap a bar for details',
                      'اضغط على عمود للتفاصيل',
                    )
                  : '${DateFormat('EEE d MMM', locale).format(selected.date)}  •  ${_fmtAmount(l10n, selected.amount)}',
              style: TextStyle(
                color: selected == null ? palette.textMuted : primary,
                fontWeight: selected == null
                    ? FontWeight.w400
                    : FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _chartHeight + (showWeekdayLabels ? 22 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Reverse so the oldest day is first (left) and today last.
                for (var i = count - 1; i >= 0; i--)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            margin: EdgeInsets.symmetric(
                              horizontal: count > 14 ? 1 : 4,
                            ),
                            height: stats.maxAmount <= 0
                                ? 4
                                : math.max(
                                    4,
                                    stats.items[i].amount /
                                        stats.maxAmount *
                                        _chartHeight,
                                  ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: i == selectedIndex
                                  ? primary
                                  : (i == stats.peakIndex
                                        ? primary.withValues(alpha: 0.75)
                                        : (i == 0
                                              ? primary.withValues(alpha: 0.55)
                                              : palette.stroke.withValues(
                                                  alpha: 0.35,
                                                ))),
                            ),
                          ),
                          if (showWeekdayLabels) ...[
                            const SizedBox(height: 6),
                            Text(
                              DateFormat(
                                'E',
                                locale,
                              ).format(stats.items[i].date),
                              style: TextStyle(
                                color: i == 0
                                    ? palette.textPrimary
                                    : palette.textMuted,
                                fontWeight: i == 0
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
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

// ---------------------------------------------------------------------------
// Daily list with relative progress bars
// ---------------------------------------------------------------------------

class _DailyExpensesList extends StatelessWidget {
  final _PeriodStats stats;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const _DailyExpensesList({
    required this.stats,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.appPalette;
    final primary = Theme.of(context).colorScheme.primary;
    final locale = Localizations.localeOf(context).toString();
    final items = stats.items;

    String relativeLabel(int index, DateTime date) {
      if (index == 0) return _t(context, 'Today', 'اليوم');
      if (index == 1) return _t(context, 'Yesterday', 'أمس');
      return DateFormat('EEEE', locale).format(date);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: palette.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.dailyExpensesSummaryTitle,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < items.length; index++) ...[
            _DayRow(
              title: DateFormat('dd/MM/yyyy').format(items[index].date),
              subtitle: relativeLabel(index, items[index].date),
              amountText: _fmtAmount(l10n, items[index].amount),
              hasSpend: items[index].amount > 0,
              ratio: stats.maxAmount <= 0
                  ? 0
                  : items[index].amount / stats.maxAmount,
              isToday: index == 0,
              isPeak: index == stats.peakIndex,
              isSelected: index == selectedIndex,
              accent: primary,
              onTap: () => onSelect(index),
            ),
            if (index < items.length - 1)
              Divider(height: 1, color: palette.stroke.withValues(alpha: 0.15)),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amountText;
  final bool hasSpend;
  final double ratio;
  final bool isToday;
  final bool isPeak;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _DayRow({
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.hasSpend,
    required this.ratio,
    required this.isToday,
    required this.isPeak,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isToday
                  ? accent.withValues(alpha: 0.15)
                  : palette.stroke.withValues(alpha: 0.15),
              child: Icon(
                isToday
                    ? Icons.today_rounded
                    : (hasSpend
                          ? Icons.calendar_today_rounded
                          : Icons.check_rounded),
                color: isToday ? accent : palette.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isPeak) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 15,
                          color: accent,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasSpend
                        ? subtitle
                        : '$subtitle • ${_t(context, 'No spending', 'بدون إنفاق')}',
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                  if (hasSpend) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: palette.stroke.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(
                          accent.withValues(alpha: isPeak ? 0.9 : 0.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amountText,
              style: TextStyle(
                color: hasSpend ? palette.textPrimary : palette.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
