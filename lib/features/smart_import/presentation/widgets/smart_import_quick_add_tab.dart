import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/models/parsed_financial_entry.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/sms_bulk_import_service.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/expenses_tab/domain/expense_categories.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/widgets/payment_method_chips_section.dart';
import 'package:imrpo/features/smart_import/presentation/utils/smart_import_actions.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

typedef _QuickAddPayload = ({
  FinancialEntryType type,
  double amountInBase,
  String? title,
  DateTime date,
  String? expenseCategory,
  String? expensePaidFrom,
  String? incomeSource,
});

class SmartImportQuickAddTab extends StatefulWidget {
  final ScrollController scrollController;

  const SmartImportQuickAddTab({
    super.key,
    required this.scrollController,
  });

  @override
  State<SmartImportQuickAddTab> createState() => _SmartImportQuickAddTabState();
}

class _SmartImportQuickAddTabState extends State<SmartImportQuickAddTab> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _bulkImportService = getIt<SmsBulkImportService>();
  final _currencyPrefs = getIt<CurrencyPreferences>();

  FinancialEntryType _type = FinancialEntryType.expense;
  DateTime _date = DateTime.now();
  String _expenseCategory = 'Food';
  String _expensePaidFrom = PaymentMethodsStore.defaultPresets.first;
  String _incomeSource = PaymentMethodsStore.defaultPresets.first;
  String _currencyCode = CurrencyConverter.defaultDisplayCode;
  bool _saving = false;

  bool get _isExpense => _type == FinancialEntryType.expense;

  @override
  void initState() {
    super.initState();
    _currencyCode = _currencyPrefs.displayCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _amountController.clear();
      _titleController.clear();
      _type = FinancialEntryType.expense;
      _date = DateTime.now();
      _expenseCategory = 'Food';
      _expensePaidFrom = PaymentMethodsStore.defaultPresets.first;
      _incomeSource = PaymentMethodsStore.defaultPresets.first;
      _currencyCode = _currencyPrefs.displayCode;
    });
  }

  _QuickAddPayload? _buildPayload(AppLocalizations l10n) {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      showSmartImportSnack(context, l10n.errorEnterValidAmount, isError: true);
      return null;
    }

    final amountInBase = CurrencyConverter.toBase(amount, _currencyCode);
    final title = _titleController.text.trim();

    if (_isExpense) {
      if (_expensePaidFrom.trim().isEmpty) {
        showSmartImportSnack(
          context,
          l10n.smartImportBulkSelectPaidFrom,
          isError: true,
        );
        return null;
      }
      return (
        type: FinancialEntryType.expense,
        amountInBase: amountInBase,
        title: title.isEmpty ? null : title,
        date: _date,
        expenseCategory: _expenseCategory,
        expensePaidFrom: _expensePaidFrom,
        incomeSource: null,
      );
    }

    if (_incomeSource.trim().isEmpty) {
      showSmartImportSnack(
        context,
        l10n.smartImportBulkSelectIncomeSource,
        isError: true,
      );
      return null;
    }

    return (
      type: FinancialEntryType.income,
      amountInBase: amountInBase,
      title: title.isEmpty ? null : title,
      date: _date,
      expenseCategory: null,
      expensePaidFrom: null,
      incomeSource: _incomeSource,
    );
  }

  ParsedFinancialEntry _entryFromPayload(_QuickAddPayload payload) {
    return ParsedFinancialEntry(
      title: payload.title,
      amount: _currencyPrefs.displayAmount(payload.amountInBase),
      currencyCode: _currencyPrefs.displayCode,
      date: payload.date,
      type: payload.type,
      rawText: 'quick-add',
    );
  }

  Future<void> _addNow(_QuickAddPayload payload) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final result = await _bulkImportService.importParsedEntries(
        [_entryFromPayload(payload)],
        expenseCategory: payload.expenseCategory,
        incomeSource: payload.incomeSource,
        expensePaidFrom: payload.expensePaidFrom,
      );
      if (!mounted) return;

      reloadTransactionTabs(context);

      if (result.hasAny) {
        _resetForm();
        showSmartImportSnack(context, l10n.smartImportQuickAdded);
      } else {
        showSmartImportSnack(
          context,
          l10n.smartImportBulkNothingToAdd,
          isError: true,
        );
      }
    } catch (_) {
      if (mounted) {
        showSmartImportSnack(context, l10n.smartImportSmsFailed, isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openFullForm(_QuickAddPayload payload) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showSmartImportEntrySheet(
      context,
      type: payload.type,
      title: smartImportFallbackTitle(l10n, payload.title),
      amountInBase: payload.amountInBase,
      date: payload.date,
    );

    if (!mounted) return;
    if (isSmartImportSheetSuccess(result)) {
      _resetForm();
      showSmartImportSnack(context, l10n.smartImportQuickAdded);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit(Future<void> Function(_QuickAddPayload) action) async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final payload = _buildPayload(l10n);
    if (payload == null) return;
    await action(payload);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final disabled = _saving;
    final accent = _isExpense ? AppColors.expense : AppColors.income;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 88),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: AppDecorations.card(
            borderColor: AppColors.primaryInk.withValues(alpha: 0.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryInk.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primaryInk,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n.smartImportQuickHint,
                  style: TextStyle(
                    color: AppColors.textColor.withValues(alpha: 0.72),
                    height: 1.45,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.smartImportQuickTypeLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _TypeChip(
                label: l10n.tabExpenses,
                icon: Icons.north_east_rounded,
                color: AppColors.expense,
                selected: _isExpense,
                onTap: disabled
                    ? null
                    : () => setState(() => _type = FinancialEntryType.expense),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TypeChip(
                label: l10n.tabIncomes,
                icon: Icons.south_west_rounded,
                color: AppColors.income,
                selected: !_isExpense,
                onTap: disabled
                    ? null
                    : () => setState(() => _type = FinancialEntryType.income),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        CurrencyAmountField(
          label: l10n.smartImportQuickAmountLabel,
          controller: _amountController,
          accentColor: accent,
          initialCurrencyCode: _currencyCode,
          onCurrencyChanged: (c) => _currencyCode = c.code,
        ),
        const SizedBox(height: 14),
        CustomFormField(
          controller: _titleController,
          label: l10n.titleField,
          hint: l10n.smartImportQuickTitleHint,
          icon: Icons.label_outline_rounded,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 14),
        Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: disabled ? null : _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: AppColors.textColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.smartImportDateField,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textColor.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          DateFormat.yMMMd(locale).format(_date),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textColor.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isExpense) ...[
          const SizedBox(height: 20),
          Text(
            l10n.smartImportBulkExpenseCategory,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategories.presets.map((cat) {
              final selected = _expenseCategory == cat;
              return ChoiceChip(
                label: Text(localizeExpenseCategory(l10n, cat)),
                selected: selected,
                onSelected: disabled
                    ? null
                    : (_) => setState(() => _expenseCategory = cat),
                selectedColor: AppColors.expense,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textColor,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          PaymentMethodChipsSection(
            label: l10n.expensePaidFromField,
            hint: l10n.smartImportBulkExpensePaidFromHint,
            selected: _expensePaidFrom,
            onSelected: disabled
                ? (_) {}
                : (src) => setState(() => _expensePaidFrom = src),
            accentColor: AppColors.expense,
            enabled: !disabled,
          ),
        ] else ...[
          const SizedBox(height: 20),
          PaymentMethodChipsSection(
            label: l10n.smartImportBulkIncomeSource,
            hint: l10n.smartImportBulkIncomeSourceHint,
            selected: _incomeSource,
            onSelected: disabled
                ? (_) {}
                : (src) => setState(() => _incomeSource = src),
            accentColor: AppColors.income,
            enabled: !disabled,
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: disabled ? null : () => _submit(_addNow),
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(l10n.smartImportQuickAddNow),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: disabled ? null : () => _submit(_openFullForm),
          icon: const Icon(Icons.edit_note_rounded, size: 20),
          label: Text(l10n.smartImportQuickReview),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    this.onTap,
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
