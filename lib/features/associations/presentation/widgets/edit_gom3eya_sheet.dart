import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/egp_amount_form_field.dart';
import 'package:imrpo/features/associations/domain/entities/association_hub_data.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class EditGom3eyaResult {
  final double? payoutAmount;
  final double? installmentAmount;
  final int? collectionDay;
  final List<AssociationTurnSlot> slots;

  const EditGom3eyaResult({
    this.payoutAmount,
    this.installmentAmount,
    this.collectionDay,
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
  final List<TextEditingController> _nameCtrls = [];
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
    if (d.slots.isEmpty) {
      _addSlotRow();
      _addSlotRow();
    } else {
      for (final slot in d.slots) {
        _nameCtrls.add(TextEditingController(text: slot.holderName));
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
    for (final c in _nameCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSlotRow() {
    setState(() => _nameCtrls.add(TextEditingController()));
  }

  void _removeSlotRow(int index) {
    if (_nameCtrls.length <= 1) return;
    setState(() {
      _nameCtrls[index].dispose();
      _nameCtrls.removeAt(index);
    });
  }

  double? _parseAmount(String text) {
    final t = text.trim().replaceAll(',', '');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  bool get _hasAnySlotName =>
      _nameCtrls.any((c) => c.text.trim().isNotEmpty);

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

  String? _validateSlotName(String? value, int index, AppLocalizations l10n) {
    if (_hasAnySlotName) return null;
    if (index == 0) return l10n.associationHubSlotsRequired;
    return null;
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);

    if (!(_formKey.currentState?.validate() ?? false)) {
      AppToast.error(context, l10n.associationHubFormFixErrors);
      return;
    }

    final names = <String>[];
    for (final c in _nameCtrls) {
      final n = c.text.trim();
      if (n.isNotEmpty) names.add(n);
    }

    final dayText = _dayCtrl.text.trim();
    int? day;
    if (dayText.isNotEmpty) {
      day = int.parse(dayText);
    }

    final slots = <AssociationTurnSlot>[];
    for (var i = 0; i < names.length; i++) {
      slots.add(AssociationTurnSlot(slotIndex: i, holderName: names[i]));
    }

    Navigator.pop(
      context,
      EditGom3eyaResult(
        payoutAmount: _parseAmount(_payoutCtrl.text),
        installmentAmount: _parseAmount(_installmentCtrl.text),
        collectionDay: day,
        slots: slots,
      ),
    );
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
                l10n.associationHubEdit,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
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
                      style: TextStyle(
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
              const SizedBox(height: 8),
              ...List.generate(_nameCtrls.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
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
                          controller: _nameCtrls[index],
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (_autovalidateMode !=
                                AutovalidateMode.disabled) {
                              _formKey.currentState?.validate();
                            }
                          },
                          validator: (v) =>
                              _validateSlotName(v, index, l10n),
                          decoration: InputDecoration(
                            hintText: l10n.associationHubSlotName,
                            errorMaxLines: 2,
                          ),
                        ),
                      ),
                      if (_nameCtrls.length > 1)
                        IconButton(
                          onPressed: () => _removeSlotRow(index),
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.errorColor,
                        ),
                    ],
                  ),
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
    );
  }
}
