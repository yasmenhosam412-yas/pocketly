import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/expense_shortcuts_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/core/widgets/payment_method_chips_section.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/expenses_tab/domain/entities/expense_shortcut.dart';
import 'package:imrpo/features/expenses_tab/domain/expense_categories.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Create or edit a one-tap expense shortcut (saved locally).
class AddExpenseShortcutSheet extends StatefulWidget {
  final ExpenseShortcut? editing;

  const AddExpenseShortcutSheet({super.key, this.editing});

  @override
  State<AddExpenseShortcutSheet> createState() => _AddExpenseShortcutSheetState();
}

class _AddExpenseShortcutSheetState extends State<AddExpenseShortcutSheet> {
  static const _expenseColor = AppColors.expense;
  static const _otherCategory = ExpenseCategories.other;
  static const _categories = ExpenseCategories.presets;

  final _displayLabelController = TextEditingController();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _otherCategoryController = TextEditingController();
  String _category = 'Food';
  late String _currencyCode;
  String? _paidFromSource;
  bool _saving = false;

  bool get _isOtherCategory => _category == _otherCategory;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    final e = widget.editing;
    if (e != null) {
      _displayLabelController.text = e.displayLabel;
      _titleController.text = e.expenseTitle;
      final display = CurrencyConverter.fromBase(e.amountBase, _currencyCode);
      _amountController.text = _formatRawAmount(display);
      if (_categories.contains(e.category)) {
        _category = e.category;
      } else {
        _category = _otherCategory;
        _otherCategoryController.text = e.category;
      }
      final src = e.incomeSource?.trim();
      _paidFromSource = (src == null || src.isEmpty) ? null : src;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    });
  }

  @override
  void dispose() {
    _displayLabelController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  String _formatRawAmount(double amount) {
    return amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
  }

  String? _resolvedCategory() {
    if (!_isOtherCategory) return _category;
    final custom = _otherCategoryController.text.trim();
    if (custom.isEmpty) return null;
    return custom;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final label = _displayLabelController.text.trim();
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final category = _resolvedCategory();

    if (label.isEmpty) {
      _toast(l10n.expenseShortcutErrorLabel);
      return;
    }
    if (title.isEmpty) {
      _toast(l10n.errorEnterTitle);
      return;
    }
    if (amount == null || amount <= 0) {
      _toast(l10n.errorEnterValidAmount);
      return;
    }
    if (category == null) {
      _toast(l10n.errorEnterCategoryName);
      return;
    }

    setState(() => _saving = true);
    try {
      final base = CurrencyConverter.toBase(amount, _currencyCode);
      final id = widget.editing?.id ??
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
      final shortcut = ExpenseShortcut(
        id: id,
        displayLabel: label,
        expenseTitle: title,
        category: category,
        incomeSource: _paidFromSource,
        amountBase: base,
      );
      await getIt<ExpenseShortcutsStore>().upsert(shortcut);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.editing != null;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 20),
                  Text(
                    isEdit ? l10n.expenseShortcutEditTitle : l10n.expenseShortcutAddTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.expenseShortcutFormHint,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textColor.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomFormField(
                    label: l10n.expenseShortcutChipLabelField,
                    hint: l10n.expenseShortcutChipLabelHint,
                    controller: _displayLabelController,
                    obscure: false,
                    icon: Icons.bolt_outlined,
                  ),
                  const SizedBox(height: 16),
                  CustomFormField(
                    label: l10n.expenseShortcutExpenseTitleField,
                    hint: l10n.hintExpenseTitle,
                    controller: _titleController,
                    obscure: false,
                    icon: Icons.label_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  CurrencyAmountField(
                    label: l10n.amountField,
                    controller: _amountController,
                    accentColor: _expenseColor,
                    initialCurrencyCode: _currencyCode,
                    onCurrencyChanged: (c) => _currencyCode = c.code,
                  ),
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
                    children: _categories.map((cat) {
                      final selected = _category == cat;
                      return ChoiceChip(
                        label: Text(localizeExpenseCategory(l10n, cat)),
                        selected: selected,
                        onSelected: (_) => setState(() => _category = cat),
                        selectedColor: _expenseColor,
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
                  if (_isOtherCategory) ...[
                    const SizedBox(height: 16),
                    CustomFormField(
                      label: l10n.otherCategoryField,
                      hint: l10n.otherCategoryHint,
                      controller: _otherCategoryController,
                      obscure: false,
                      icon: Icons.category_outlined,
                    ),
                  ],
                    PaymentMethodChipsSection(
                      label: l10n.expensePaidFromField,
                      selected: _paidFromSource ?? '',
                      allowNone: true,
                      onClearSelection: () =>
                          setState(() => _paidFromSource = null),
                      onSelected: (src) =>
                          setState(() => _paidFromSource = src),
                      accentColor: _expenseColor,
                    ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _expenseColor,
                        disabledBackgroundColor:
                            _expenseColor.withValues(alpha: 0.65),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.expenseShortcutSave,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
