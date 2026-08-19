import 'package:flutter/material.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/expenses_tab/domain/expense_categories.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Returns the new category name, or null if cancelled.
Future<String?> showRenameExpenseCategorySheet(
  BuildContext context, {
  required String currentCategory,
  required List<String> existingCategories,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RenameExpenseCategorySheet(
      currentCategory: currentCategory,
      existingCategories: existingCategories,
    ),
  );
}

class _RenameExpenseCategorySheet extends StatefulWidget {
  final String currentCategory;
  final List<String> existingCategories;

  const _RenameExpenseCategorySheet({
    required this.currentCategory,
    required this.existingCategories,
  });

  @override
  State<_RenameExpenseCategorySheet> createState() =>
      _RenameExpenseCategorySheetState();
}

class _RenameExpenseCategorySheetState extends State<_RenameExpenseCategorySheet> {
  late final TextEditingController _controller;
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentCategory);
    if (ExpenseCategories.presets.contains(widget.currentCategory)) {
      _selectedPreset = widget.currentCategory;
    }
    _controller.addListener(() {
      if (_selectedPreset != null && _controller.text != _selectedPreset) {
        setState(() => _selectedPreset = null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPreset(String category) {
    setState(() {
      _selectedPreset = category;
      _controller.text = category;
    });
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorEnterCategoryName),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }
    if (name == widget.currentCategory) {
      Navigator.pop(context);
      return;
    }
    final taken = widget.existingCategories
        .where((c) => c != widget.currentCategory)
        .contains(name);
    if (taken) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.expenseCategoryNameTaken),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
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
              l10n.expenseCategoryRenameTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.expenseCategoryRenameHint(
                localizeExpenseCategory(l10n, widget.currentCategory),
              ),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColor.withValues(alpha: 0.6),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategories.presets.map((category) {
                final selected = _selectedPreset == category;
                return ChoiceChip(
                  label: Text(localizeExpenseCategory(l10n, category)),
                  selected: selected,
                  onSelected: (_) => _selectPreset(category),
                  selectedColor: AppColors.expense,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: AppColors.surface,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            CustomFormField(
              label: l10n.categoryField,
              hint: l10n.otherCategoryHint,
              controller: _controller,
              obscure: false,
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.expense,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.save,
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
    );
  }
}
