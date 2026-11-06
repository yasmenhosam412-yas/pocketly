import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/egp_amount_form_field.dart';
import 'package:imrpo/features/associations/domain/entities/association_hub_data.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class RecordAssociationPaymentResult {
  final String payerName;
  final String? turnSlotId;
  final double amount;
  final DateTime paidAt;
  final String? note;

  const RecordAssociationPaymentResult({
    required this.payerName,
    this.turnSlotId,
    required this.amount,
    required this.paidAt,
    this.note,
  });
}

Future<RecordAssociationPaymentResult?> showRecordAssociationPaymentSheet(
  BuildContext context, {
  required AssociationHubData hub,
}) {
  return showModalBottomSheet<RecordAssociationPaymentResult>(
    context: context,
    isScrollControlled: true,
shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RecordAssociationPaymentSheet(hub: hub),
  );
}

class _RecordAssociationPaymentSheet extends StatefulWidget {
  final AssociationHubData hub;

  const _RecordAssociationPaymentSheet({required this.hub});

  @override
  State<_RecordAssociationPaymentSheet> createState() =>
      _RecordAssociationPaymentSheetState();
}

class _PayerChoice {
  final String key;
  final String? slotId;
  final String payerName;
  final String label;
  final bool halfShare;
  final DateTime? paymentOn;

  const _PayerChoice({
    required this.key,
    required this.slotId,
    required this.payerName,
    required this.label,
    required this.halfShare,
    this.paymentOn,
  });
}

class _RecordAssociationPaymentSheetState
    extends State<_RecordAssociationPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late final List<_PayerChoice> _choices;
  late DateTime _paidAt;
  String? _selectedSlotId;
  String? _selectedPayerName;
  String? _selectedKey;
  TextEditingController? _payerCtrl;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _choices = _buildChoices(widget.hub);
    _noteCtrl = TextEditingController();
    _paidAt = DateTime.now();

    final current = widget.hub.currentSlot;
    _PayerChoice? initial;
    if (_choices.isNotEmpty) {
      initial = _choices.firstWhere(
        (choice) =>
            current != null &&
            choice.slotId == current.id &&
            choice.key.endsWith('|me'),
        orElse: () => _choices.first,
      );
      _selectedKey = initial.key;
      _selectedSlotId = initial.slotId;
      _selectedPayerName = initial.payerName;
      if (initial.paymentOn != null) _paidAt = initial.paymentOn!;
    }

    _amountCtrl = TextEditingController(
      text: _defaultAmount(initial?.halfShare ?? false),
    );
    if (_choices.isEmpty) {
      _payerCtrl = TextEditingController(text: _selectedPayerName ?? '');
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _payerCtrl?.dispose();
    super.dispose();
  }

  List<_PayerChoice> _buildChoices(AssociationHubData hub) {
    final choices = <_PayerChoice>[];
    for (final slot in hub.slots) {
      final slotKey = slot.id ?? 'idx_${slot.slotIndex}';
      for (final person in slot.people) {
        choices.add(
          _PayerChoice(
            key: '$slotKey|${person.isPartner ? 'co' : 'me'}',
            slotId: slot.id,
            payerName: person.name,
            label: slot.isSplit
                ? '${person.name} · ${slot.slotIndex + 1}'
                : person.name,
            halfShare: slot.isSplit,
            paymentOn: person.paymentOn,
          ),
        );
      }
    }
    return choices;
  }

  String _defaultAmount(bool halfShare) {
    final installment = widget.hub.installmentAmount;
    if (installment == null || installment <= 0) return '';
    final value = halfShare ? installment / 2 : installment;
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  bool _isAutoAmount(String text) {
    final current = _parseAmount(text);
    if (current == null) return true;
    final installment = widget.hub.installmentAmount;
    if (installment == null || installment <= 0) return false;
    final half = installment / 2;
    return (current - installment).abs() < 0.001 || (current - half).abs() < 0.001;
  }

  double? _parseAmount(String text) {
    final t = text.trim().replaceAll(',', '');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  String? _validateAmount(String? value, AppLocalizations l10n) {
    final amount = _parseAmount(value ?? '');
    if (amount == null || amount <= 0) return l10n.errorEnterValidAmount;
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(2020);
    final last = DateTime(now.year + 15);
    var initial = _paidAt;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() => _paidAt = picked);
    }
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);

    if (!(_formKey.currentState?.validate() ?? false)) {
      AppToast.error(context, l10n.associationHubFormFixErrors);
      return;
    }

    final payer = (_payerCtrl?.text ?? _selectedPayerName ?? '').trim();
    if (payer.isEmpty) {
      AppToast.error(context, l10n.associationHubPaymentPayerRequired);
      return;
    }

    final amount = _parseAmount(_amountCtrl.text)!;
    Navigator.pop(
      context,
      RecordAssociationPaymentResult(
        payerName: payer,
        turnSlotId: _selectedSlotId,
        amount: amount,
        paidAt: DateTime(_paidAt.year, _paidAt.month, _paidAt.day, 12),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );
  }

  String _formatDate(BuildContext context) {
    final locale = getIt<LocalePreferences>().locale.toString();
    return DateFormat.yMMMd(locale).format(_paidAt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
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
                l10n.associationHubRecordPayment,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_choices.isNotEmpty) ...[
                Text(
                  l10n.associationHubPaymentPayer,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedKey,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.card,
                  ),
                  items: _choices.map((choice) {
                    return DropdownMenuItem(
                      value: choice.key,
                      child: Text(choice.label),
                    );
                  }).toList(),
                  onChanged: (key) {
                    if (key == null) return;
                    final choice = _choices.firstWhere((c) => c.key == key);
                    setState(() {
                      _selectedKey = key;
                      _selectedSlotId = choice.slotId;
                      _selectedPayerName = choice.payerName;
                      if (choice.paymentOn != null) {
                        _paidAt = choice.paymentOn!;
                      }
                      if (_isAutoAmount(_amountCtrl.text)) {
                        _amountCtrl.text = _defaultAmount(choice.halfShare);
                      }
                    });
                  },
                  validator: (v) =>
                      v == null ? l10n.associationHubPaymentPayerRequired : null,
                ),
              ] else
                TextFormField(
                  controller: _payerCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.associationHubPaymentPayer,
                    hintText: l10n.associationHubSlotName,
                  ),
                  onChanged: (v) => _selectedPayerName = v,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l10n.associationHubPaymentPayerRequired;
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 12),
              EgpAmountFormField(
                controller: _amountCtrl,
                labelText: l10n.associationHubPaymentAmount,
                autovalidateMode: _autovalidateMode,
                validator: (v) => _validateAmount(v, l10n),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.associationHubPaymentDate,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primaryInk,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(context),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textColor.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: l10n.associationHubPaymentNote,
                  hintText: l10n.associationHubPaymentNoteHint,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.associationHubPaymentSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
