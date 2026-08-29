import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/budgets/domain/entities/budget_period.dart';
import 'package:imrpo/features/budgets/domain/entities/category_budget_status.dart';
import 'package:imrpo/features/budgets/domain/services/budget_calculator.dart';
import 'package:imrpo/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class SetBudgetSheet extends StatefulWidget {
  final BudgetPeriod period;
  final List<String> suggestedCategories;
  final CategoryBudgetStatus? initialRow;

  const SetBudgetSheet({
    super.key,
    required this.period,
    required this.suggestedCategories,
    this.initialRow,
  });

  @override
  State<SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<SetBudgetSheet> {
  static const _presetCategories = [
    'Food',
    'Rent',
    'Transport',
    'Shopping',
    'Bills',
    'Other',
  ];

  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  late String _currencyCode;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    final row = widget.initialRow;
    if (row != null) {
      _selectedCategory = row.category;
      _categoryController.text = row.category;
      if (row.limit > 0) {
        final display = CurrencyConverter.fromBase(row.limit, _currencyCode);
        _amountController.text = display == display.roundToDouble()
            ? display.toInt().toString()
            : display.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<String> get _categoryOptions {
    final combined = <String>{
      ..._presetCategories,
      ...widget.suggestedCategories,
      ...context.read<BudgetsBloc>().state.budgets.map((b) => b.category),
    };
    return combined.toList()..sort();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _categoryController.text = category;
    });
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final category = _categoryController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (category.isEmpty) {
      _showError(l10n.errorEnterCategoryName);
      return;
    }
    if (amount == null || amount <= 0) {
      _showError(l10n.errorEnterValidAmount);
      return;
    }

    final baseAmount = CurrencyConverter.toBase(amount, _currencyCode);
    context.read<BudgetsBloc>().add(
          UpsertBudgetEvent(
            category: BudgetCalculator.categoryKey(category),
            amount: baseAmount,
            year: widget.period.year,
            month: widget.period.month,
            budgetId: widget.initialRow?.budgetId,
          ),
        );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return BlocListener<BudgetsBloc, BudgetsState>(
      listenWhen: (previous, current) =>
          previous.status == BudgetsStatus.saving &&
          current.status == BudgetsStatus.loaded,
      listener: (context, state) {
        Navigator.of(context).pop(true);
      },
      child: BlocBuilder<BudgetsBloc, BudgetsState>(
        builder: (context, state) {
          final isSaving = state.status == BudgetsStatus.saving;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
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
                      widget.initialRow?.budgetId != null
                          ? l10n.budgetEditTitle
                          : l10n.budgetSetTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.budgetSetHint,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textColor.withValues(alpha: 0.6),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.categoryField,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categoryOptions.map((category) {
                        final selected = _selectedCategory == category;
                        return ChoiceChip(
                          label: Text(
                            localizeExpenseCategory(l10n, category),
                          ),
                          selected: selected,
                          onSelected: (_) => _selectCategory(category),
                          selectedColor: AppColors.expense,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textColor,
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
                    const SizedBox(height: 16),
                    CustomFormField(
                      label: l10n.budgetCustomCategory,
                      hint: l10n.otherCategoryHint,
                      controller: _categoryController,
                      obscure: false,
                      icon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 16),
                    CurrencyAmountField(
                      label: l10n.budgetMonthlyLimit,
                      controller: _amountController,
                      accentColor: AppColors.expense,
                      initialCurrencyCode: _currencyCode,
                      onCurrencyChanged: (c) => _currencyCode = c.code,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: isSaving ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.expense,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.budgetSave,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<bool?> showSetBudgetSheet(
  BuildContext context, {
  required BudgetPeriod period,
  required List<String> suggestedCategories,
  CategoryBudgetStatus? initialRow,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<BudgetsBloc>(),
      child: SetBudgetSheet(
        period: period,
        suggestedCategories: suggestedCategories,
        initialRow: initialRow,
      ),
    ),
  );
}
