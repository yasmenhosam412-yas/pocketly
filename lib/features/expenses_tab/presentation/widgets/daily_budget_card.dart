import 'package:flutter/material.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/daily_budget_store.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/expenses_tab/data/models/expense_model.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class DailyBudgetCard extends StatefulWidget {
  final List<ExpenseModel> expenses;
  final VoidCallback? onAddExpense;

  const DailyBudgetCard({super.key, required this.expenses, this.onAddExpense});

  @override
  State<DailyBudgetCard> createState() => _DailyBudgetCardState();
}

class _DailyBudgetCardState extends State<DailyBudgetCard> {
  final DailyBudgetStore _store = DailyBudgetStore();

  double _dailyBudget = DailyBudgetStore.defaultDailyBudget;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final budget = await _store.loadDailyBudget();

    if (!mounted) return;

    setState(() {
      _dailyBudget = budget;
      _loading = false;
    });
  }

  DateTime _localDate(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  double _toEgp(double amount) {
    return CurrencyConverter.fromBase(amount, 'EGP');
  }

  double _sumForDay(DateTime today) {
    return widget.expenses
        .where((expense) => _localDate(expense.date) == today)
        .fold<double>(0, (sum, expense) => sum + _toEgp(expense.amount));
  }

  Future<void> _editBudget() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _BudgetEditDialog(initialBudget: _dailyBudget),
    );

    if (amount == null || !mounted) return;

    final saved = await _store.saveDailyBudget(amount);

    if (!mounted) return;

    if (saved) {
      setState(() => _dailyBudget = amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.appPalette;
    final today = _localDate(DateTime.now());
    final currency = NumberFormat('#,##0.##', 'en_US');

    final todaySpent = _sumForDay(today);
    final remaining = _dailyBudget - todaySpent;
    final safeRemaining = remaining > 0 ? remaining : 0.0;

    final progress = _dailyBudget > 0
        ? (todaySpent / _dailyBudget).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final exceeded = todaySpent > _dailyBudget;

    final remainingText = l10n.egpAmount(currency.format(safeRemaining));
    final spentText = l10n.egpAmount(currency.format(todaySpent));

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      elevation: 0,
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.stroke.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: palette.scaffold,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.dailyBudgetTitle,
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.dailyBudgetSubtitle,
                              style: TextStyle(
                                color: palette.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.editDailyBudget,
                        onPressed: _editBudget,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _BudgetValue(
                          label: l10n.remainingToday,
                          value: remainingText,
                          color: exceeded
                              ? Colors.redAccent
                              : const Color(0xFF21865B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BudgetValue(
                          label: l10n.expensesToday,
                          value: spentText,
                          color: palette.textPrimary,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 9,
                      backgroundColor: palette.stroke.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        exceeded ? Colors.redAccent : const Color(0xFF398568),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.dailyBudgetAmount(currency.format(_dailyBudget)),
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.budgetUsedPercent(
                          (progress * 100).round().toString(),
                        ),
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onAddExpense,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF398568,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(
                              0xFF398568,
                            ).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF398568,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Color(0xFF398568),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.addExpense,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    l10n.trackBudgetSubtitle,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                              color: Color(0xFF398568),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.scaffold,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          exceeded
                              ? Icons.warning_amber_rounded
                              : Icons.lightbulb_outline_rounded,
                          color: exceeded ? Colors.orange : palette.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exceeded
                                ? l10n.dailyBudgetExceededMessage(
                                    currency.format(todaySpent - _dailyBudget),
                                  )
                                : l10n.dailyBudgetRemainingMessage(
                                    currency.format(safeRemaining),
                                  ),
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BudgetValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  const _BudgetValue({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: palette.textMuted, fontSize: 12)),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BudgetEditDialog extends StatefulWidget {
  final double initialBudget;

  const _BudgetEditDialog({required this.initialBudget});

  @override
  State<_BudgetEditDialog> createState() => _BudgetEditDialogState();
}

class _BudgetEditDialogState extends State<_BudgetEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialBudget.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim().replaceAll(',', '.'));

    if (value == null || !value.isFinite || value <= 0) {
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.dailyBudgetTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.dailyBudgetInputLabel,
          suffixText: l10n.currencyEgyptianPound,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
