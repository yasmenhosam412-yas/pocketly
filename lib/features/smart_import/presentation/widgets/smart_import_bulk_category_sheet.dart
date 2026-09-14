import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/core/widgets/payment_method_chips_section.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class BulkImportCategories {
  final String? expenseCategory;
  /// Income row category (source name on income records).
  final String? incomeSource;
  /// Expense [incomeSource] (paid from). Bulk sheet default; per-SMS value preferred.
  final String? expensePaidFrom;

  const BulkImportCategories({
    this.expenseCategory,
    this.incomeSource,
    this.expensePaidFrom,
  });
}

Future<BulkImportCategories?> showSmartImportBulkCategorySheet(
  BuildContext context, {
  required bool needsExpenseCategory,
  required bool needsIncomeSource,
  String? initialExpenseCategory,
  String? initialIncomeSource,
  String? initialExpensePaidFrom,
  String? sheetTitle,
  String? sheetHint,
}) {
  return showModalBottomSheet<BulkImportCategories>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => BlocProvider.value(
      value: context.read<IncomesTabBloc>(),
      child: _SmartImportBulkCategorySheet(
        needsExpenseCategory: needsExpenseCategory,
        needsIncomeSource: needsIncomeSource,
        initialExpenseCategory: initialExpenseCategory,
        initialIncomeSource: initialIncomeSource,
        initialExpensePaidFrom: initialExpensePaidFrom,
        sheetTitle: sheetTitle,
        sheetHint: sheetHint,
      ),
    ),
  );
}

class _SmartImportBulkCategorySheet extends StatefulWidget {
  final bool needsExpenseCategory;
  final bool needsIncomeSource;
  final String? initialExpenseCategory;
  final String? initialIncomeSource;
  final String? initialExpensePaidFrom;
  final String? sheetTitle;
  final String? sheetHint;

  const _SmartImportBulkCategorySheet({
    required this.needsExpenseCategory,
    required this.needsIncomeSource,
    this.initialExpenseCategory,
    this.initialIncomeSource,
    this.initialExpensePaidFrom,
    this.sheetTitle,
    this.sheetHint,
  });

  @override
  State<_SmartImportBulkCategorySheet> createState() =>
      _SmartImportBulkCategorySheetState();
}

class _SmartImportBulkCategorySheetState
    extends State<_SmartImportBulkCategorySheet> {
  static const _expenseOther = 'Other';
  static const _expenseCategories = [
    'Food',
    'Rent',
    'Transport',
    'Shopping',
    'Bills',
    _expenseOther,
  ];

  late String _expenseCategory;
  final _expenseOtherController = TextEditingController();
  late String _selectedIncomeSource;
  late String _expensePaidFrom;

  bool get _isExpenseOther => _expenseCategory == _expenseOther;

  @override
  void initState() {
    super.initState();
    final initialExpense = widget.initialExpenseCategory?.trim();
    if (initialExpense != null &&
        initialExpense.isNotEmpty &&
        _expenseCategories.contains(initialExpense)) {
      _expenseCategory = initialExpense;
    } else if (initialExpense != null && initialExpense.isNotEmpty) {
      _expenseCategory = _expenseOther;
      _expenseOtherController.text = initialExpense;
    } else {
      _expenseCategory = 'Bills';
    }
    _selectedIncomeSource =
        widget.initialIncomeSource?.trim().isNotEmpty == true
            ? widget.initialIncomeSource!.trim()
            : 'Other';
    _expensePaidFrom =
        widget.initialExpensePaidFrom?.trim().isNotEmpty == true
            ? widget.initialExpensePaidFrom!.trim()
            : 'Cash';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    });
  }

  @override
  void dispose() {
    _expenseOtherController.dispose();
    super.dispose();
  }

  String? _resolvedExpenseCategory() {
    if (!_isExpenseOther) return _expenseCategory;
    final custom = _expenseOtherController.text.trim();
    return custom.isEmpty ? null : custom;
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    String? expense;
    String? income;
    String? paidFrom;

    if (widget.needsExpenseCategory) {
      expense = _resolvedExpenseCategory();
      if (expense == null) {
        _showError(l10n.errorEnterCategoryName);
        return;
      }
      paidFrom = _expensePaidFrom.trim();
      if (paidFrom.isEmpty) {
        _showError(l10n.smartImportBulkSelectPaidFrom);
        return;
      }
    }
    if (widget.needsIncomeSource) {
      income = _selectedIncomeSource.trim();
      if (income.isEmpty) {
        _showError(l10n.smartImportBulkSelectIncomeSource);
        return;
      }
    }

    Navigator.of(context).pop(
      BulkImportCategories(
        expenseCategory: expense,
        incomeSource: income,
        expensePaidFrom: paidFrom,
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

  Widget _buildExpensePaidFromSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: PaymentMethodChipsSection(
        label: l10n.expensePaidFromField,
        hint: l10n.smartImportBulkExpensePaidFromHint,
        selected: _expensePaidFrom,
        onSelected: (src) => setState(() => _expensePaidFrom = src),
        accentColor: AppColors.expense,
      ),
    );
  }

  Widget _buildIncomeSourceSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: PaymentMethodChipsSection(
        label: l10n.smartImportBulkIncomeSource,
        hint: l10n.smartImportBulkIncomeSourceHint,
        selected: _selectedIncomeSource,
        onSelected: (src) => setState(() => _selectedIncomeSource = src),
        accentColor: AppColors.income,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
              const SizedBox(height: 20),
              Text(
                widget.sheetTitle ?? l10n.smartImportBulkCategorySheetTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.sheetHint ?? l10n.smartImportBulkCategorySheetHint,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textColor.withValues(alpha: 0.6),
                  height: 1.35,
                ),
              ),
              if (widget.needsExpenseCategory) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.smartImportBulkExpenseCategory,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _expenseCategories.map((cat) {
                    final selected = _expenseCategory == cat;
                    return ChoiceChip(
                      label: Text(localizeExpenseCategory(l10n, cat)),
                      selected: selected,
                      onSelected: (_) => setState(() => _expenseCategory = cat),
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
                if (_isExpenseOther) ...[
                  const SizedBox(height: 12),
                  CustomFormField(
                    label: l10n.otherCategoryField,
                    hint: l10n.otherCategoryHint,
                    controller: _expenseOtherController,
                    obscure: false,
                    icon: Icons.category_outlined,
                  ),
                ],
                _buildExpensePaidFromSection(l10n),
              ],
              if (widget.needsIncomeSource) _buildIncomeSourceSection(l10n),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.smartImportBulkApplyAndImport,
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
  }
}
