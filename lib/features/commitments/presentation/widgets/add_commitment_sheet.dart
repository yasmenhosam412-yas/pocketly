import 'package:flutter/material.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/core/widgets/payment_method_chips_section.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/bill_reminders/domain/bill_reminder_day_helper.dart';
import 'package:imrpo/features/commitments/domain/entities/payment_commitment.dart';
import 'package:imrpo/features/expenses_tab/domain/expense_categories.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class AddCommitmentSheet extends StatefulWidget {
  final CommitmentKind kind;
  final PaymentCommitment? item;

  const AddCommitmentSheet({
    super.key,
    required this.kind,
    this.item,
  });

  @override
  State<AddCommitmentSheet> createState() => _AddCommitmentSheetState();
}

class _AddCommitmentSheetState extends State<AddCommitmentSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _countController = TextEditingController();
  final _notesController = TextEditingController();
  final _otherCategoryController = TextEditingController();
  final List<TextEditingController> _memberControllers = [];
  late String _currencyCode;
  late int _dueDay;
  late int _meIndex;
  late CommitmentKind _kind;
  late String _category;
  late String _payFrom;
  late String _receiveInto;

  bool get _isEditing => widget.item != null;
  bool get _isGameya => _kind == CommitmentKind.gameya;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    _kind = widget.item?.kind ?? widget.kind;
    _dueDay = widget.item?.dueDay ?? 1;
    final fallbackSource = PaymentMethodsStore.defaultPresets.first;
    final item = widget.item;
    final storedCategory = item?.expenseCategory.trim() ?? '';
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
    _payFrom = (item != null && item.payFrom.trim().isNotEmpty)
        ? item.payFrom
        : fallbackSource;
    _receiveInto = (item != null && item.receiveInto.trim().isNotEmpty)
        ? item.receiveInto
        : _payFrom;
    _meIndex = 0;
    if (_isGameya) {
      final names = item?.members ?? const <String>[];
      if (names.isNotEmpty) {
        for (final name in names) {
          _memberControllers.add(TextEditingController(text: name));
        }
      } else {
        final slots = item == null ? 2 : item.safeTotal.clamp(2, 24).toInt();
        for (var i = 0; i < slots; i++) {
          _memberControllers.add(TextEditingController());
        }
      }
      final turn = (item?.myTurn ?? 1) - 1;
      _meIndex = turn.clamp(0, _memberControllers.length - 1).toInt();
    }
    if (item != null) {
      _titleController.text = item.title;
      _amountController.text = _format(item.monthlyAmount);
      _countController.text = '${item.totalCount}';
      _notesController.text = item.notes;
    } else {
      _countController.text = '12';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _countController.dispose();
    _notesController.dispose();
    _otherCategoryController.dispose();
    for (final controller in _memberControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _format(double base) {
    final display = CurrencyConverter.fromBase(base, _currencyCode);
    return display == display.roundToDouble()
        ? display.toInt().toString()
        : display.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = _isGameya ? AppColors.primaryInk : AppColors.expense;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
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
              _isEditing
                  ? l10n.commitmentsEditTitle
                  : (_isGameya
                      ? l10n.commitmentsAddGameya
                      : l10n.commitmentsAddInstallment),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isGameya
                  ? l10n.commitmentsGameyaHint
                  : l10n.commitmentsInstallmentHint,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textColor.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            CustomFormField(
              label: l10n.commitmentsNameLabel,
              hint: _isGameya
                  ? l10n.commitmentsGameyaNameHint
                  : l10n.commitmentsInstallmentNameHint,
              controller: _titleController,
              obscure: false,
              icon: Icons.edit_outlined,
            ),
            const SizedBox(height: 16),
            CurrencyAmountField(
              label: l10n.commitmentsMonthlyAmount,
              controller: _amountController,
              accentColor: accent,
              initialCurrencyCode: _currencyCode,
              onCurrencyChanged: (c) => _currencyCode = c.code,
            ),
            const SizedBox(height: 16),
            if (_isGameya)
              _membersEditor(l10n, accent)
            else
              CustomFormField(
                label: l10n.commitmentsInstallmentCount,
                hint: '12',
                controller: _countController,
                obscure: false,
                icon: Icons.tag_rounded,
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 16),
            Text(
              l10n.commitmentsDueDay(_dueDay),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
            ),
            Slider(
              value: _dueDay.toDouble(),
              min: 1,
              max: 31,
              divisions: 30,
              activeColor: accent,
              label: '$_dueDay',
              onChanged: (v) => setState(() => _dueDay = v.round()),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.categoryField,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.commitmentsCategoryHint,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textColor.withValues(alpha: 0.55),
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
            if (_isGameya) ...[
              const SizedBox(height: 16),
              PaymentMethodChipsSection(
                label: l10n.commitmentsReceiveInto,
                hint: l10n.commitmentsReceiveIntoHint,
                selected: _receiveInto,
                onSelected: (src) => setState(() => _receiveInto = src),
                accentColor: accent,
              ),
            ],
            const SizedBox(height: 16),
            CustomFormField(
              label: l10n.loanNotesOptional,
              hint: l10n.commitmentsNotesHint,
              controller: _notesController,
              obscure: false,
              icon: Icons.notes_rounded,
            ),
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
                onPressed: _save,
                child: Text(
                  _isEditing ? l10n.save : l10n.commitmentsSave,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _membersEditor(AppLocalizations l10n, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.commitmentsMembersTitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.commitmentsMembersHint,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            color: AppColors.textColor.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _memberControllers.length; i++) ...[
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: i == _meIndex ? accent : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _memberControllers[i],
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColor,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.commitmentsMemberHint,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text(l10n.commitmentsMemberMe),
                selected: i == _meIndex,
                onSelected: (_) => setState(() => _meIndex = i),
                selectedColor: accent,
                labelStyle: TextStyle(
                  color: i == _meIndex ? Colors.white : AppColors.textColor,
                  fontWeight: FontWeight.w700,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
              if (_memberControllers.length > 2)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removeMember(i),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _addMember,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(l10n.commitmentsAddMember),
          ),
        ),
      ],
    );
  }

  void _addMember() {
    setState(() {
      _memberControllers.add(TextEditingController());
    });
  }

  void _removeMember(int index) {
    if (_memberControllers.length <= 2) return;
    setState(() {
      _memberControllers.removeAt(index).dispose();
      if (_meIndex == index) {
        _meIndex = index.clamp(0, _memberControllers.length - 1).toInt();
      } else if (_meIndex > index) {
        _meIndex -= 1;
      }
    });
  }

  String? _resolvedCategory() {
    if (_category != ExpenseCategories.other) return _category;
    final custom = _otherCategoryController.text.trim();
    if (custom.isEmpty) return null;
    return custom;
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppToast.error(context, l10n.commitmentsNameRequired);
      return;
    }
    final displayAmount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    if (displayAmount == null || displayAmount <= 0) {
      AppToast.error(context, l10n.errorEnterValidAmount);
      return;
    }
    final names = _memberControllers
        .map((controller) => controller.text.trim())
        .toList();
    late final int count;
    late final int turn;
    if (_isGameya) {
      if (names.length < 2) {
        AppToast.error(context, l10n.commitmentsMembersMin);
        return;
      }
      if (names.any((name) => name.isEmpty)) {
        AppToast.error(context, l10n.commitmentsMemberNameRequired);
        return;
      }
      count = names.length;
      turn = (_meIndex + 1).clamp(1, count);
    } else {
      count = int.tryParse(_countController.text.trim()) ?? 0;
      if (count < 1) {
        AppToast.error(context, l10n.commitmentsCountRequired);
        return;
      }
      turn = 1;
    }

    if (_payFrom.trim().isEmpty) {
      AppToast.error(context, l10n.errorSelectLoanPaymentSource);
      return;
    }
    if (_isGameya && _receiveInto.trim().isEmpty) {
      AppToast.error(context, l10n.errorSelectLoanPaymentSource);
      return;
    }
    final category = _resolvedCategory();
    if (category == null) {
      AppToast.error(context, l10n.errorEnterCategoryName);
      return;
    }

    final existing = widget.item;
    final paid = existing == null
        ? 0
        : existing.paidCount.clamp(0, count);
    final item = PaymentCommitment(
      id: existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      kind: _kind,
      title: title,
      monthlyAmount: CurrencyConverter.toBase(displayAmount, _currencyCode),
      totalCount: count,
      paidCount: paid,
      dueDay: BillReminderDayHelper.clampStoredDay(_dueDay),
      myTurn: turn,
      members: _isGameya ? names : const [],
      lastPaidYm: existing?.lastPaidYm ?? '',
      notes: _notesController.text.trim(),
      payFrom: _payFrom.trim(),
      expenseCategory: category,
      receiveInto: _isGameya ? _receiveInto.trim() : _payFrom.trim(),
      lastExpenseId: existing?.lastExpenseId ?? '',
      lastIncomeId: existing?.lastIncomeId ?? '',
    );
    Navigator.of(context).pop(item);
  }
}
