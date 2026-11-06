import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final List<_SeatDraft> _seats = [];
  DateTime? _startsOn;
  DateTime? _endsOn;
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
      final seats = item?.seats ?? const <GameyaSeat>[];
      if (seats.isNotEmpty) {
        for (final seat in seats) {
          _seats.add(_SeatDraft.fromSeat(seat));
        }
      } else {
        final slots = item == null ? 2 : item.safeTotal.clamp(2, 24).toInt();
        for (var i = 0; i < slots; i++) {
          _seats.add(_SeatDraft());
        }
      }
      final turn = (item?.myTurn ?? 1) - 1;
      _meIndex = turn.clamp(0, _seats.length - 1).toInt();
      _startsOn = item?.startsOn;
      _endsOn = item?.endsOn;
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
    for (final seat in _seats) {
      seat.dispose();
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
            if (_isGameya) ...[
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: l10n.associationHubStartDate,
                      value: _formatDate(_startsOn, l10n),
                      onTap: () => _pickRangeDate(isStart: true),
                      onClear: _startsOn == null
                          ? null
                          : () => setState(() => _startsOn = null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateButton(
                      label: l10n.associationHubEndDate,
                      value: _formatDate(_endsOn, l10n),
                      onTap: () => _pickRangeDate(isStart: false),
                      onClear: _endsOn == null
                          ? null
                          : () => setState(() => _endsOn = null),
                    ),
                  ),
                ],
              ),
              if (_datesInvalid) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.associationHubEndBeforeStart,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
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
        for (var i = 0; i < _seats.length; i++) ...[
          _SeatEditor(
            index: i,
            draft: _seats[i],
            accent: accent,
            isMe: i == _meIndex,
            canRemove: _seats.length > 2,
            formatDate: (date) => _formatDate(date, l10n),
            onMarkMe: () => setState(() => _meIndex = i),
            onRemove: () => _removeMember(i),
            onChanged: () => setState(() {}),
            onPickPayment: () => _pickSeatDate(
              _seats[i].paymentOn,
              (value) => _seats[i].paymentOn = value,
            ),
            onClearPayment: () => setState(() => _seats[i].paymentOn = null),
            onPickCollection: () => _pickSeatDate(
              _seats[i].collectionOn,
              (value) => _seats[i].collectionOn = value,
            ),
            onClearCollection: () =>
                setState(() => _seats[i].collectionOn = null),
            onToggleSplit: () {
              setState(() {
                final draft = _seats[i];
                draft.split = !draft.split;
                if (draft.split) {
                  draft.partnerPaymentOn ??= draft.paymentOn;
                  draft.partnerCollectionOn ??= draft.collectionOn;
                }
              });
            },
            onPickPartnerPayment: () => _pickSeatDate(
              _seats[i].partnerPaymentOn,
              (value) => _seats[i].partnerPaymentOn = value,
            ),
            onClearPartnerPayment: () =>
                setState(() => _seats[i].partnerPaymentOn = null),
            onPickPartnerCollection: () => _pickSeatDate(
              _seats[i].partnerCollectionOn,
              (value) => _seats[i].partnerCollectionOn = value,
            ),
            onClearPartnerCollection: () =>
                setState(() => _seats[i].partnerCollectionOn = null),
          ),
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
      _seats.add(_SeatDraft());
    });
  }

  void _removeMember(int index) {
    if (_seats.length <= 2) return;
    setState(() {
      _seats.removeAt(index).dispose();
      if (_meIndex == index) {
        _meIndex = index.clamp(0, _seats.length - 1).toInt();
      } else if (_meIndex > index) {
        _meIndex -= 1;
      }
    });
  }

  bool get _datesInvalid =>
      _startsOn != null &&
      _endsOn != null &&
      DateTime(_endsOn!.year, _endsOn!.month, _endsOn!.day).isBefore(
        DateTime(_startsOn!.year, _startsOn!.month, _startsOn!.day),
      );

  String _formatDate(DateTime? date, AppLocalizations l10n) {
    if (date == null) return l10n.associationHubDateNotSet;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  Future<void> _pickRangeDate({required bool isStart}) async {
    final picked = await _pickDate(isStart ? _startsOn : (_endsOn ?? _startsOn));
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startsOn = picked;
      } else {
        _endsOn = picked;
      }
    });
  }

  Future<void> _pickSeatDate(
    DateTime? current,
    void Function(DateTime value) apply,
  ) async {
    final picked = await _pickDate(current);
    if (picked == null) return;
    setState(() => apply(picked));
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? _startsOn ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 15),
    );
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
    final names = _seats.map((seat) => seat.name.text.trim()).toList();
    late final int count;
    late final int turn;
    late final List<GameyaSeat> seats;
    if (_isGameya) {
      if (_datesInvalid) {
        AppToast.error(context, l10n.associationHubEndBeforeStart);
        return;
      }
      if (names.length < 2) {
        AppToast.error(context, l10n.commitmentsMembersMin);
        return;
      }
      if (names.any((name) => name.isEmpty)) {
        AppToast.error(context, l10n.commitmentsMemberNameRequired);
        return;
      }
      if (_seats.any((seat) => seat.split && seat.partner.text.trim().isEmpty)) {
        AppToast.error(context, l10n.associationHubPartnerRequired);
        return;
      }
      count = names.length;
      turn = (_meIndex + 1).clamp(1, count);
      seats = [
        for (final seat in _seats)
          GameyaSeat(
            name: seat.name.text.trim(),
            paymentOn: seat.paymentOn,
            collectionOn: seat.collectionOn,
            partnerName: seat.split ? seat.partner.text.trim() : null,
            partnerPaymentOn: seat.split ? seat.partnerPaymentOn : null,
            partnerCollectionOn: seat.split ? seat.partnerCollectionOn : null,
            paidRounds: seat.paidRounds,
            partnerPaidRounds: seat.split ? seat.partnerPaidRounds : 0,
          ),
      ];
    } else {
      count = int.tryParse(_countController.text.trim()) ?? 0;
      if (count < 1) {
        AppToast.error(context, l10n.commitmentsCountRequired);
        return;
      }
      turn = 1;
      seats = const [];
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
      seats: seats,
      startsOn: _isGameya ? _startsOn : null,
      endsOn: _isGameya ? _endsOn : null,
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

class _SeatDraft {
  _SeatDraft({
    String name = '',
    String partner = '',
    this.paymentOn,
    this.collectionOn,
    this.partnerPaymentOn,
    this.partnerCollectionOn,
    this.paidRounds = 0,
    this.partnerPaidRounds = 0,
    bool? split,
  }) : name = TextEditingController(text: name),
       partner = TextEditingController(text: partner),
       split = split ?? partner.trim().isNotEmpty;

  factory _SeatDraft.fromSeat(GameyaSeat seat) {
    return _SeatDraft(
      name: seat.name,
      partner: seat.partnerName ?? '',
      paymentOn: seat.paymentOn,
      collectionOn: seat.collectionOn,
      partnerPaymentOn: seat.partnerPaymentOn,
      partnerCollectionOn: seat.partnerCollectionOn,
      paidRounds: seat.paidRounds,
      partnerPaidRounds: seat.partnerPaidRounds,
      split: seat.isSplit,
    );
  }

  final TextEditingController name;
  final TextEditingController partner;
  DateTime? paymentOn;
  DateTime? collectionOn;
  DateTime? partnerPaymentOn;
  DateTime? partnerCollectionOn;
  int paidRounds;
  int partnerPaidRounds;
  bool split;

  void dispose() {
    name.dispose();
    partner.dispose();
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColor,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 16),
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _SeatEditor extends StatelessWidget {
  final int index;
  final _SeatDraft draft;
  final Color accent;
  final bool isMe;
  final bool canRemove;
  final String Function(DateTime?) formatDate;
  final VoidCallback onMarkMe;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final VoidCallback onPickPayment;
  final VoidCallback onClearPayment;
  final VoidCallback onPickCollection;
  final VoidCallback onClearCollection;
  final VoidCallback onToggleSplit;
  final VoidCallback onPickPartnerPayment;
  final VoidCallback onClearPartnerPayment;
  final VoidCallback onPickPartnerCollection;
  final VoidCallback onClearPartnerCollection;

  const _SeatEditor({
    required this.index,
    required this.draft,
    required this.accent,
    required this.isMe,
    required this.canRemove,
    required this.formatDate,
    required this.onMarkMe,
    required this.onRemove,
    required this.onChanged,
    required this.onPickPayment,
    required this.onClearPayment,
    required this.onPickCollection,
    required this.onClearCollection,
    required this.onToggleSplit,
    required this.onPickPartnerPayment,
    required this.onClearPartnerPayment,
    required this.onPickPartnerCollection,
    required this.onClearPartnerCollection,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? accent : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isMe ? accent : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: draft.name,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => onChanged(),
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
                selected: isMe,
                onSelected: (_) => onMarkMe(),
                selectedColor: accent,
                labelStyle: TextStyle(
                  color: isMe ? Colors.white : AppColors.textColor,
                  fontWeight: FontWeight.w700,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
              if (canRemove)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: l10n.associationHubPersonPaymentDate,
                  value: formatDate(draft.paymentOn),
                  onTap: onPickPayment,
                  onClear: draft.paymentOn == null ? null : onClearPayment,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateButton(
                  label: l10n.associationHubPersonCollectionDate,
                  value: formatDate(draft.collectionOn),
                  onTap: onPickCollection,
                  onClear: draft.collectionOn == null ? null : onClearCollection,
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onToggleSplit,
              icon: Icon(
                draft.split ? Icons.link_off_rounded : Icons.people_outline,
                size: 18,
              ),
              label: Text(
                draft.split
                    ? l10n.associationHubRemovePartner
                    : l10n.associationHubSplitTurn,
              ),
            ),
          ),
          if (draft.split) ...[
            TextField(
              controller: draft.partner,
              onChanged: (_) => onChanged(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.associationHubPartnerName,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: l10n.associationHubPersonPaymentDate,
                    value: formatDate(draft.partnerPaymentOn),
                    onTap: onPickPartnerPayment,
                    onClear: draft.partnerPaymentOn == null
                        ? null
                        : onClearPartnerPayment,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateButton(
                    label: l10n.associationHubPersonCollectionDate,
                    value: formatDate(draft.partnerCollectionOn),
                    onTap: onPickPartnerCollection,
                    onClear: draft.partnerCollectionOn == null
                        ? null
                        : onClearPartnerCollection,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
