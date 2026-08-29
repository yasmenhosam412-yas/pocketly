import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/core/widgets/payment_method_chips_section.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/bill_reminders/domain/bill_reminder_day_helper.dart';
import 'package:imrpo/features/expenses_tab/domain/expense_categories.dart';
import 'package:imrpo/features/recurring_transactions/domain/entities/recurring_transaction.dart';
import 'package:imrpo/features/recurring_transactions/presentation/bloc/recurring_transactions_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AddRecurringTransactionSheet extends StatefulWidget {
  final RecurringTransaction? item;

  const AddRecurringTransactionSheet({super.key, this.item});

  @override
  State<AddRecurringTransactionSheet> createState() =>
      _AddRecurringTransactionSheetState();
}

class _AddRecurringTransactionSheetState
    extends State<AddRecurringTransactionSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late RecurringKind _kind;
  late String _category;
  String? _incomeSource;
  late int _dayOfMonth;
  late String _currencyCode;
  late int _referenceYear;
  late int _referenceMonth;

  bool get _isEditing => widget.item != null;

  bool get _isExpense => _kind == RecurringKind.expense;

  int get _maxDayInReferenceMonth =>
      BillReminderDayHelper.daysInMonth(_referenceYear, _referenceMonth);

  bool get _usesLastDayInSomeMonths => _dayOfMonth > 28;

  List<String> get _expenseCategories {
    final cats = [...ExpenseCategories.presets];
    if (_category.isNotEmpty && !cats.contains(_category)) {
      cats.add(_category);
    }
    return cats;
  }

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    final now = DateTime.now();
    _referenceYear = now.year;
    _referenceMonth = now.month;

    final item = widget.item;
    if (item != null) {
      _kind = item.kind;
      _titleController.text = item.title;
      _category = item.category;
      _incomeSource = item.incomeSource;
      _dayOfMonth = BillReminderDayHelper.clampStoredDay(item.dayOfMonth);
      final display = CurrencyConverter.fromBase(item.amount, _currencyCode);
      _amountController.text = display == display.roundToDouble()
          ? display.toInt().toString()
          : display.toStringAsFixed(2);
    } else {
      _kind = RecurringKind.expense;
      _category = ExpenseCategories.presets.first;
      _incomeSource = null;
      _dayOfMonth = now.day.clamp(1, _maxDayInReferenceMonth);
    }
    _clampDayToReferenceMonth();
  }

  void _clampDayToReferenceMonth() {
    final max = _maxDayInReferenceMonth;
    if (_dayOfMonth > max) {
      _dayOfMonth = max;
    }
  }

  void _shiftReferenceMonth(int delta) {
    final date = DateTime(_referenceYear, _referenceMonth + delta, 1);
    setState(() {
      _referenceYear = date.year;
      _referenceMonth = date.month;
      _clampDayToReferenceMonth();
    });
  }

  String _referenceMonthLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMM(locale).format(
      DateTime(_referenceYear, _referenceMonth),
    );
  }

  void _setKind(RecurringKind kind) {
    if (_kind == kind) return;
    setState(() {
      _kind = kind;
      if (kind == RecurringKind.income) {
        _category = _incomeSource?.trim().isNotEmpty == true
            ? _incomeSource!
            : PaymentMethodsStore.defaultPresets.first;
        _incomeSource = null;
      } else {
        _incomeSource = _category;
        _category = ExpenseCategories.presets.first;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _applyPreset(String title, {String? expenseCategory}) {
    setState(() {
      _titleController.text = title;
      if (_isExpense && expenseCategory != null) {
        _category = expenseCategory;
      }
    });
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorEnterTitle)),
      );
      return;
    }

    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorEnterValidAmount)),
      );
      return;
    }

    final amount = CurrencyConverter.toBase(parsed, _currencyCode);
    final id = widget.item?.id ??
        '${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}';

    String category;
    String? incomeSource;
    if (_isExpense) {
      category = _category;
      final paid = _incomeSource?.trim();
      incomeSource = (paid == null || paid.isEmpty) ? null : paid;
    } else {
      category = _category.trim().isEmpty
          ? PaymentMethodsStore.defaultPresets.first
          : _category.trim();
      incomeSource = null;
    }

    context.read<RecurringTransactionsBloc>().add(
      SaveRecurringTransactionEvent(
        item: RecurringTransaction(
          id: id,
          kind: _kind,
          title: title,
          amount: amount,
          category: category,
          incomeSource: incomeSource,
          dayOfMonth: BillReminderDayHelper.clampStoredDay(_dayOfMonth),
          isEnabled: widget.item?.isEnabled ?? true,
          lastPostedYm: widget.item?.lastPostedYm ?? '',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = _isExpense ? AppColors.expense : AppColors.income;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing
                  ? l10n.recurringTransactionsEdit
                  : l10n.recurringTransactionsAdd,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _KindChip(
                    label: l10n.tabExpenses,
                    icon: Icons.north_east_rounded,
                    color: AppColors.expense,
                    selected: _isExpense,
                    onTap: () => _setKind(RecurringKind.expense),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KindChip(
                    label: l10n.tabIncomes,
                    icon: Icons.south_west_rounded,
                    color: AppColors.income,
                    selected: !_isExpense,
                    onTap: () => _setKind(RecurringKind.income),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _isExpense
                  ? [
                      ActionChip(
                        label: Text(l10n.billRemindersPresetRent),
                        onPressed: () => _applyPreset(
                          l10n.billRemindersPresetRent,
                          expenseCategory: 'Rent',
                        ),
                      ),
                      ActionChip(
                        label: Text(l10n.billRemindersPresetInternet),
                        onPressed: () => _applyPreset(
                          l10n.billRemindersPresetInternet,
                          expenseCategory: 'Bills',
                        ),
                      ),
                      ActionChip(
                        label: Text(l10n.billRemindersPresetElectricity),
                        onPressed: () => _applyPreset(
                          l10n.billRemindersPresetElectricity,
                          expenseCategory: 'Bills',
                        ),
                      ),
                    ]
                  : [
                      ActionChip(
                        label: Text(l10n.demoSalary),
                        onPressed: () {
                          _applyPreset(l10n.demoSalary);
                          setState(() {
                            _category = 'Salary';
                          });
                        },
                      ),
                    ],
            ),
            const SizedBox(height: 12),
            CustomFormField(
              label: l10n.titleField,
              controller: _titleController,
              hint: l10n.recurringTransactionsTitleHint,
              icon: Icons.label_outline_rounded,
            ),
            const SizedBox(height: 16),
            CurrencyAmountField(
              label: l10n.amountField,
              controller: _amountController,
              accentColor: accent,
              initialCurrencyCode: _currencyCode,
              onCurrencyChanged: (c) => _currencyCode = c.code,
            ),
            if (_isExpense) ...[
              const SizedBox(height: 16),
              Text(
                l10n.categoryField,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _expenseCategories.map((cat) {
                  final selected = _category == cat;
                  return ChoiceChip(
                    label: Text(localizeExpenseCategory(l10n, cat)),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = cat),
                    selectedColor: AppColors.expense,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: AppColors.surface,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
              PaymentMethodChipsSection(
                label: l10n.expensePaidFromField,
                selected: _incomeSource ?? '',
                allowNone: true,
                onClearSelection: () => setState(() => _incomeSource = null),
                onSelected: (src) => setState(() => _incomeSource = src),
                accentColor: AppColors.expense,
              ),
            ] else ...[
              const SizedBox(height: 16),
              PaymentMethodChipsSection(
                label: l10n.incomeSourceField,
                selected: _category.trim().isEmpty
                    ? PaymentMethodsStore.defaultPresets.first
                    : _category.trim(),
                onSelected: (src) => setState(() => _category = src),
                accentColor: AppColors.income,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.billRemindersDayOfMonth,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _shiftReferenceMonth(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                          color: AppColors.primaryInk,
                        ),
                        Expanded(
                          child: Text(
                            _referenceMonthLabel(context),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _shiftReferenceMonth(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: AppColors.primaryInk,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          l10n.billRemindersDayOfMonthValue(_dayOfMonth),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          ' / $_maxDayInReferenceMonth',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _dayOfMonth.toDouble(),
                            min: 1,
                            max: _maxDayInReferenceMonth.toDouble(),
                            divisions: _maxDayInReferenceMonth - 1,
                            activeColor: AppColors.primaryInk,
                            onChanged: (v) =>
                                setState(() => _dayOfMonth = v.round()),
                          ),
                        ),
                      ],
                    ),
                    if (_usesLastDayInSomeMonths)
                      Text(
                        l10n.billRemindersDayOfMonthShortMonthHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isEditing ? l10n.save : l10n.recurringTransactionsAdd,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _KindChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.14) : AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.textColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
