import 'package:flutter/material.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/payment_method_chips_section.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/commitments/domain/entities/payment_commitment.dart';
import 'package:imrpo/features/expenses_tab/domain/expense_categories.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class CommitmentPaymentDraft {
  final String payFrom;
  final String category;
  final String receiveInto;

  const CommitmentPaymentDraft({
    required this.payFrom,
    required this.category,
    required this.receiveInto,
  });
}

class MarkCommitmentPaidSheet extends StatefulWidget {
  final PaymentCommitment item;

  const MarkCommitmentPaidSheet({super.key, required this.item});

  @override
  State<MarkCommitmentPaidSheet> createState() =>
      _MarkCommitmentPaidSheetState();
}

class _MarkCommitmentPaidSheetState extends State<MarkCommitmentPaidSheet> {
  final _otherCategoryController = TextEditingController();
  late String _category;
  late String _payFrom;
  late String _receiveInto;

  bool get _recordPayout => widget.item.isMyTurnNext;

  @override
  void initState() {
    super.initState();
    final storedCategory = widget.item.expenseCategory.trim();
    if (storedCategory.isEmpty ||
        (ExpenseCategories.presets.contains(storedCategory) &&
            storedCategory != ExpenseCategories.other)) {
      _category = storedCategory.isEmpty ? 'Bills' : storedCategory;
    } else {
      _category = ExpenseCategories.other;
      if (storedCategory != ExpenseCategories.other) {
        _otherCategoryController.text = storedCategory;
      }
    }
    _payFrom = widget.item.payFrom;
    _receiveInto = widget.item.receiveInto.trim().isEmpty
        ? widget.item.payFrom
        : widget.item.receiveInto;
  }

  @override
  void dispose() {
    _otherCategoryController.dispose();
    super.dispose();
  }

  String? _resolvedCategory() {
    if (_category != ExpenseCategories.other) return _category;
    final custom = _otherCategoryController.text.trim();
    if (custom.isEmpty) return null;
    return custom;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    final accent = item.isGameya ? AppColors.primaryInk : AppColors.expense;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Material(
      color: AppColors.card,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: maxHeight,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            Text(
              l10n.commitmentsMarkPaid,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${item.title} · ${Money.format(item.monthlyAmount)}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (_recordPayout) ...[
              const SizedBox(height: 12),
              Text(
                l10n.commitmentsTurnPayoutNote(
                  Money.format(item.payout),
                ),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
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
              children: ExpenseCategories.presets.map((cat) {
                final selected = _category == cat;
                return ChoiceChip(
                  label: Text(localizeExpenseCategory(l10n, cat)),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: accent,
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
            if (_category == ExpenseCategories.other) ...[
              const SizedBox(height: 16),
              CustomFormField(
                label: l10n.otherCategoryField,
                hint: l10n.otherCategoryHint,
                controller: _otherCategoryController,
                obscure: false,
                icon: Icons.category_outlined,
              ),
            ],
            const SizedBox(height: 16),
            PaymentMethodChipsSection(
              label: l10n.loanPaymentPayFromBalance,
              hint: l10n.commitmentsPayFromHint,
              selected: _payFrom,
              onSelected: (src) => setState(() => _payFrom = src),
              accentColor: accent,
            ),
            if (_recordPayout) ...[
              const SizedBox(height: 16),
              PaymentMethodChipsSection(
                label: l10n.commitmentsReceiveInto,
                hint: l10n.commitmentsReceiveIntoHint,
                selected: _receiveInto,
                onSelected: (src) => setState(() => _receiveInto = src),
                accentColor: accent,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _confirm,
                child: Text(
                  l10n.commitmentsConfirmPay,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _confirm() {
    final l10n = AppLocalizations.of(context)!;
    if (_payFrom.trim().isEmpty ||
        (_recordPayout && _receiveInto.trim().isEmpty)) {
      AppToast.error(context, l10n.errorSelectLoanPaymentSource);
      return;
    }
    final category = _resolvedCategory();
    if (category == null) {
      AppToast.error(context, l10n.errorEnterCategoryName);
      return;
    }
    Navigator.of(context).pop(
      CommitmentPaymentDraft(
        payFrom: _payFrom.trim(),
        category: category,
        receiveInto: _receiveInto.trim(),
      ),
    );
  }
}
