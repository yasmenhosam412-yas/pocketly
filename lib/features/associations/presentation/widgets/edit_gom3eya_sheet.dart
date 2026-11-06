import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/egp_amount_form_field.dart';
import 'package:imrpo/features/associations/domain/entities/association_hub_data.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class EditGom3eyaResult {
  final double? payoutAmount;
  final double? installmentAmount;
  final int? collectionDay;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final List<AssociationTurnSlot> slots;

  const EditGom3eyaResult({
    this.payoutAmount,
    this.installmentAmount,
    this.collectionDay,
    this.startsOn,
    this.endsOn,
    required this.slots,
  });
}

Future<EditGom3eyaResult?> showEditGom3eyaSheet(
  BuildContext context, {
  required AssociationHubData initial,
}) {
  return showModalBottomSheet<EditGom3eyaResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EditGom3eyaSheet(initial: initial),
  );
}

class _SlotDraft {
  _SlotDraft({
    String name = '',
    String partner = '',
    this.paymentOn,
    this.collectionOn,
    this.partnerPaymentOn,
    this.partnerCollectionOn,
    bool? split,
    this.id,
    this.receivedAt,
  }) : nameCtrl = TextEditingController(text: name),
       partnerCtrl = TextEditingController(text: partner),
       split = split ?? partner.trim().isNotEmpty;

  factory _SlotDraft.fromSlot(AssociationTurnSlot slot) {
    return _SlotDraft(
      name: slot.holderName,
      partner: slot.coHolderName ?? '',
      paymentOn: slot.paymentOn,
      collectionOn: slot.collectionOn,
      partnerPaymentOn: slot.coPaymentOn,
      partnerCollectionOn: slot.coCollectionOn,
      split: slot.isSplit,
      id: slot.id,
      receivedAt: slot.receivedAt,
    );
  }

  final TextEditingController nameCtrl;
  final TextEditingController partnerCtrl;
  DateTime? paymentOn;
  DateTime? collectionOn;
  DateTime? partnerPaymentOn;
  DateTime? partnerCollectionOn;
  bool split;
  final String? id;
  final DateTime? receivedAt;

  void dispose() {
    nameCtrl.dispose();
    partnerCtrl.dispose();
  }
}

class _EditGom3eyaSheet extends StatefulWidget {
  final AssociationHubData initial;

  const _EditGom3eyaSheet({required this.initial});

  @override
  State<_EditGom3eyaSheet> createState() => _EditGom3eyaSheetState();
}

class _EditGom3eyaSheetState extends State<_EditGom3eyaSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _payoutCtrl;
  late final TextEditingController _installmentCtrl;
  late final TextEditingController _dayCtrl;
  final List<_SlotDraft> _drafts = [];
  DateTime? _start;
  DateTime? _end;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _payoutCtrl = TextEditingController(
      text: d.payoutAmount != null && d.payoutAmount! > 0
          ? _trimNum(d.payoutAmount!)
          : '',
    );
    _installmentCtrl = TextEditingController(
      text: d.installmentAmount != null && d.installmentAmount! > 0
          ? _trimNum(d.installmentAmount!)
          : '',
    );
    _dayCtrl = TextEditingController(
      text: d.collectionDay?.toString() ?? '',
    );
    _start = d.startsOn;
    _end = d.endsOn;
    if (d.slots.isEmpty) {
      _drafts.add(_SlotDraft());
      _drafts.add(_SlotDraft());
    } else {
      for (final slot in d.slots) {
        _drafts.add(_SlotDraft.fromSlot(slot));
      }
    }
  }

  String _trimNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  void dispose() {
    _payoutCtrl.dispose();
    _installmentCtrl.dispose();
    _dayCtrl.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addSlotRow() {
    setState(() => _drafts.add(_SlotDraft()));
  }

  void _removeSlotRow(int index) {
    if (_drafts.length <= 1) return;
    setState(() {
      _drafts[index].dispose();
      _drafts.removeAt(index);
    });
  }

  double? _parseAmount(String text) {
    final t = text.trim().replaceAll(',', '');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  bool get _hasAnySlotName =>
      _drafts.any((d) => d.nameCtrl.text.trim().isNotEmpty);

  bool get _datesInvalid =>
      _start != null &&
      _end != null &&
      DateTime(_end!.year, _end!.month, _end!.day).isBefore(
        DateTime(_start!.year, _start!.month, _start!.day),
      );

  String? _validateOptionalAmount(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return null;
    final amount = _parseAmount(value);
    if (amount == null || amount <= 0) {
      return l10n.errorEnterValidAmount;
    }
    return null;
  }

  String? _validateCollectionDay(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return null;
    final day = int.tryParse(value.trim());
    if (day == null || day < 1 || day > 31) {
      return l10n.associationHubCollectionDayInvalid;
    }
    return null;
  }

  String? _validatePrimary(_SlotDraft draft, int index, AppLocalizations l10n) {
    if (draft.split && draft.nameCtrl.text.trim().isEmpty) {
      return l10n.associationHubSlotsRequired;
    }
    if (_hasAnySlotName) return null;
    if (index == 0) return l10n.associationHubSlotsRequired;
    return null;
  }

  String? _validatePartner(_SlotDraft draft, AppLocalizations l10n) {
    if (!draft.split) return null;
    if (draft.partnerCtrl.text.trim().isEmpty) {
      return l10n.associationHubPartnerRequired;
    }
    return null;
  }

  Future<void> _pickStart() async {
    final picked = await _pickDate(_start);
    if (picked == null) return;
    setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDate(_end ?? _start);
    if (picked == null) return;
    setState(() => _end = picked);
  }

  Future<void> _pickDraftDate(
    DateTime? current,
    void Function(DateTime? value) apply,
  ) async {
    final picked = await _pickDate(current);
    if (picked == null) return;
    setState(() => apply(picked));
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? _start ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 15),
    );
  }

  String _formatDate(DateTime? date, AppLocalizations l10n) {
    if (date == null) return l10n.associationHubDateNotSet;
    final locale = getIt<LocalePreferences>().locale.toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);

    if (_datesInvalid) {
      AppToast.error(context, l10n.associationHubEndBeforeStart);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      AppToast.error(context, l10n.associationHubFormFixErrors);
      return;
    }

    final dayText = _dayCtrl.text.trim();
    int? day;
    if (dayText.isNotEmpty) {
      day = int.parse(dayText);
    }

    final slots = <AssociationTurnSlot>[];
    for (final draft in _drafts) {
      final name = draft.nameCtrl.text.trim();
      if (name.isEmpty) continue;
      final partner = draft.split ? draft.partnerCtrl.text.trim() : '';
      slots.add(
        AssociationTurnSlot(
          id: draft.id,
          slotIndex: slots.length,
          holderName: name,
          receivedAt: draft.receivedAt,
          paymentOn: draft.paymentOn,
          collectionOn: draft.collectionOn,
          coHolderName: partner.isEmpty ? null : partner,
          coPaymentOn: partner.isEmpty ? null : draft.partnerPaymentOn,
          coCollectionOn: partner.isEmpty ? null : draft.partnerCollectionOn,
        ),
      );
    }

    Navigator.pop(
      context,
      EditGom3eyaResult(
        payoutAmount: _parseAmount(_payoutCtrl.text),
        installmentAmount: _parseAmount(_installmentCtrl.text),
        collectionDay: day,
        startsOn: _start,
        endsOn: _end,
        slots: slots,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final available = (media.size.height - media.padding.top).clamp(320.0, media.size.height);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: available * 0.92,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16),
                  Text(
                    l10n.associationHubEdit,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DateButton(
                          label: l10n.associationHubStartDate,
                          value: _formatDate(_start, l10n),
                          hasValue: _start != null,
                          clearTooltip: l10n.associationHubClearDate,
                          onTap: _pickStart,
                          onClear: _start == null
                              ? null
                              : () => setState(() => _start = null),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateButton(
                          label: l10n.associationHubEndDate,
                          value: _formatDate(_end, l10n),
                          hasValue: _end != null,
                          clearTooltip: l10n.associationHubClearDate,
                          onTap: _pickEnd,
                          onClear: _end == null
                              ? null
                              : () => setState(() => _end = null),
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
                  const SizedBox(height: 12),
                  EgpAmountFormField(
                    controller: _payoutCtrl,
                    labelText: l10n.associationHubPayout,
                    hintText: l10n.associationHubPayoutHint,
                    autovalidateMode: _autovalidateMode,
                    validator: (v) => _validateOptionalAmount(v, l10n),
                  ),
                  const SizedBox(height: 12),
                  EgpAmountFormField(
                    controller: _installmentCtrl,
                    labelText: l10n.associationHubInstallment,
                    hintText: l10n.associationHubInstallmentHint,
                    autovalidateMode: _autovalidateMode,
                    validator: (v) => _validateOptionalAmount(v, l10n),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dayCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => _validateCollectionDay(v, l10n),
                    decoration: InputDecoration(
                      labelText: l10n.associationHubCollectionDay,
                      hintText: l10n.associationHubCollectionDayHint,
                      errorMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.associationHubTurnList,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addSlotRow,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(l10n.associationHubAddSlot),
                      ),
                    ],
                  ),
                  Text(
                    l10n.associationHubTurnListHint,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_drafts.length, (index) {
                    final draft = _drafts[index];
                    return _SlotCard(
                      index: index,
                      draft: draft,
                      canRemove: _drafts.length > 1,
                      formatDate: (date) => _formatDate(date, l10n),
                      primaryValidator: (v) => _validatePrimary(draft, index, l10n),
                      partnerValidator: (v) => _validatePartner(draft, l10n),
                      onChanged: () {
                        if (_autovalidateMode != AutovalidateMode.disabled) {
                          _formKey.currentState?.validate();
                        }
                      },
                      onRemove: () => _removeSlotRow(index),
                      onPickPayment: () => _pickDraftDate(
                        draft.paymentOn,
                        (value) => draft.paymentOn = value,
                      ),
                      onClearPayment: () => setState(() => draft.paymentOn = null),
                      onPickCollection: () => _pickDraftDate(
                        draft.collectionOn,
                        (value) => draft.collectionOn = value,
                      ),
                      onClearCollection: () =>
                          setState(() => draft.collectionOn = null),
                      onPickPartnerPayment: () => _pickDraftDate(
                        draft.partnerPaymentOn,
                        (value) => draft.partnerPaymentOn = value,
                      ),
                      onClearPartnerPayment: () =>
                          setState(() => draft.partnerPaymentOn = null),
                      onPickPartnerCollection: () => _pickDraftDate(
                        draft.partnerCollectionOn,
                        (value) => draft.partnerCollectionOn = value,
                      ),
                      onClearPartnerCollection: () =>
                          setState(() => draft.partnerCollectionOn = null),
                      onToggleSplit: () {
                        setState(() {
                          draft.split = !draft.split;
                          if (draft.split) {
                            draft.partnerPaymentOn ??= draft.paymentOn;
                            draft.partnerCollectionOn ??= draft.collectionOn;
                          }
                        });
                        if (_autovalidateMode != AutovalidateMode.disabled) {
                          _formKey.currentState?.validate();
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.associationHubSave),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final bool hasValue;
  final String clearTooltip;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateButton({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.clearTooltip,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasValue
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                tooltip: clearTooltip,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textMuted,
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.calendar_today_outlined, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final int index;
  final _SlotDraft draft;
  final bool canRemove;
  final String Function(DateTime?) formatDate;
  final FormFieldValidator<String> primaryValidator;
  final FormFieldValidator<String> partnerValidator;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onPickPayment;
  final VoidCallback onClearPayment;
  final VoidCallback onPickCollection;
  final VoidCallback onClearCollection;
  final VoidCallback onPickPartnerPayment;
  final VoidCallback onClearPartnerPayment;
  final VoidCallback onPickPartnerCollection;
  final VoidCallback onClearPartnerCollection;
  final VoidCallback onToggleSplit;

  const _SlotCard({
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.formatDate,
    required this.primaryValidator,
    required this.partnerValidator,
    required this.onChanged,
    required this.onRemove,
    required this.onPickPayment,
    required this.onClearPayment,
    required this.onPickCollection,
    required this.onClearCollection,
    required this.onPickPartnerPayment,
    required this.onClearPartnerPayment,
    required this.onPickPartnerCollection,
    required this.onClearPartnerCollection,
    required this.onToggleSplit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 48,
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryInk,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: draft.nameCtrl,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => onChanged(),
                  validator: primaryValidator,
                  decoration: InputDecoration(
                    hintText: l10n.associationHubSlotName,
                    errorMaxLines: 2,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.errorColor,
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
                  hasValue: draft.paymentOn != null,
                  clearTooltip: l10n.associationHubClearDate,
                  onTap: onPickPayment,
                  onClear: draft.paymentOn == null ? null : onClearPayment,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateButton(
                  label: l10n.associationHubPersonCollectionDate,
                  value: formatDate(draft.collectionOn),
                  hasValue: draft.collectionOn != null,
                  clearTooltip: l10n.associationHubClearDate,
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
            TextFormField(
              controller: draft.partnerCtrl,
              textInputAction: TextInputAction.next,
              onChanged: (_) => onChanged(),
              validator: partnerValidator,
              decoration: InputDecoration(
                labelText: l10n.associationHubPartnerName,
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: l10n.associationHubPersonPaymentDate,
                    value: formatDate(draft.partnerPaymentOn),
                    hasValue: draft.partnerPaymentOn != null,
                    clearTooltip: l10n.associationHubClearDate,
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
                    hasValue: draft.partnerCollectionOn != null,
                    clearTooltip: l10n.associationHubClearDate,
                    onTap: onPickPartnerCollection,
                    onClear: draft.partnerCollectionOn == null
                        ? null
                        : onClearPartnerCollection,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.associationHubSplitHint,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
