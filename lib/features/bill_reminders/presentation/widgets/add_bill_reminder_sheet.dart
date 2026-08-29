import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/services/bill_reminder_preferences.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/bill_reminders/domain/bill_reminder_day_helper.dart';
import 'package:imrpo/features/bill_reminders/domain/entities/bill_reminder.dart';
import 'package:imrpo/features/bill_reminders/presentation/bloc/bill_reminders_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AddBillReminderSheet extends StatefulWidget {
  final BillReminder? reminder;

  const AddBillReminderSheet({super.key, this.reminder});

  @override
  State<AddBillReminderSheet> createState() => _AddBillReminderSheetState();
}

class _AddBillReminderSheetState extends State<AddBillReminderSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late int _dayOfMonth;
  late int _leadDays;
  late TimeOfDay _reminderTime;
  late String _currencyCode;
  late int _referenceYear;
  late int _referenceMonth;

  bool get _isEditing => widget.reminder != null;

  int get _maxDayInReferenceMonth =>
      BillReminderDayHelper.daysInMonth(_referenceYear, _referenceMonth);

  bool get _usesLastDayInSomeMonths => _dayOfMonth > 28;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    final now = DateTime.now();
    _referenceYear = now.year;
    _referenceMonth = now.month;

    final r = widget.reminder;
    if (r != null) {
      _titleController.text = r.title;
      _dayOfMonth = BillReminderDayHelper.clampStoredDay(r.dayOfMonth);
      _leadDays = r.remindDaysBefore;
      _reminderTime = TimeOfDay(hour: r.reminderHour, minute: r.reminderMinute);
      if (r.amount != null) {
        final display =
            CurrencyConverter.fromBase(r.amount!, _currencyCode);
        _amountController.text = display == display.roundToDouble()
            ? display.toInt().toString()
            : display.toStringAsFixed(2);
      }
    } else {
      _dayOfMonth = now.day.clamp(1, _maxDayInReferenceMonth);
      _leadDays = getIt<BillReminderPreferences>().defaultLeadDays;
      _reminderTime = const TimeOfDay(
        hour: BillReminder.defaultReminderHour,
        minute: BillReminder.defaultReminderMinute,
      );
    }
    _clampDayToReferenceMonth();
  }

  void _clampDayToReferenceMonth() {
    final max = _maxDayInReferenceMonth;
    if (_dayOfMonth > max) {
      _dayOfMonth = max;
    }
  }

  void _shiftReferenceMonth(int delta) {
    final date = DateTime(_referenceYear, _referenceMonth + delta, 1);
    setState(() {
      _referenceYear = date.year;
      _referenceMonth = date.month;
      _clampDayToReferenceMonth();
    });
  }

  String _referenceMonthLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMM(locale).format(
      DateTime(_referenceYear, _referenceMonth),
    );
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryInk,
              onPrimary: AppColors.onPrimaryInk,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  String _formatReminderTime(BuildContext context) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      _reminderTime,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<({String label, int days})> _leadOptions(AppLocalizations l10n) => [
        (label: l10n.billRemindersRemindOnDay, days: 0),
        (label: l10n.billRemindersRemind1Day, days: 1),
        (label: l10n.billRemindersRemind3Days, days: 3),
        (label: l10n.billRemindersRemind7Days, days: 7),
      ];

  List<({String label, String value})> _presets(AppLocalizations l10n) => [
        (label: l10n.billRemindersPresetElectricity, value: l10n.billRemindersPresetElectricity),
        (label: l10n.billRemindersPresetRent, value: l10n.billRemindersPresetRent),
        (label: l10n.billRemindersPresetInternet, value: l10n.billRemindersPresetInternet),
        (label: l10n.billRemindersPresetWater, value: l10n.billRemindersPresetWater),
      ];

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.billRemindersTitleRequired)),
      );
      return;
    }

    double? amount;
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed != null && parsed > 0) {
      amount = CurrencyConverter.toBase(parsed, _currencyCode);
    }

    final id = widget.reminder?.id ??
        '${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}';

    context.read<BillRemindersBloc>().add(
          SaveBillReminderEvent(
            reminder: BillReminder(
              id: id,
              title: title,
              amount: amount,
              dayOfMonth: BillReminderDayHelper.clampStoredDay(_dayOfMonth),
              remindDaysBefore: _leadDays,
              reminderHour: _reminderTime.hour,
              reminderMinute: _reminderTime.minute,
              isEnabled: widget.reminder?.isEnabled ?? true,
            ),
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? l10n.billRemindersEdit : l10n.billRemindersAdd,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets(l10n).map((preset) {
                return ActionChip(
                  label: Text(preset.label),
                  onPressed: () {
                    setState(() => _titleController.text = preset.value);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            CustomFormField(
              label: l10n.billRemindersTitleLabel,
              controller: _titleController,
              hint: l10n.billRemindersTitleHint,
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 16),
            CurrencyAmountField(
              label: l10n.billRemindersAmountLabel,
              controller: _amountController,
              accentColor: AppColors.primary,
              initialCurrencyCode: _currencyCode,
              onCurrencyChanged: (c) => _currencyCode = c.code,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.billRemindersDayOfMonth,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _shiftReferenceMonth(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                          color: AppColors.primaryInk,
                        ),
                        Expanded(
                          child: Text(
                            _referenceMonthLabel(context),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _shiftReferenceMonth(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: AppColors.primaryInk,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          l10n.billRemindersDayOfMonthValue(_dayOfMonth),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          ' / $_maxDayInReferenceMonth',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _dayOfMonth.toDouble(),
                            min: 1,
                            max: _maxDayInReferenceMonth.toDouble(),
                            divisions: _maxDayInReferenceMonth - 1,
                            activeColor: AppColors.primaryInk,
                            onChanged: (v) =>
                                setState(() => _dayOfMonth = v.round()),
                          ),
                        ),
                      ],
                    ),
                    if (_usesLastDayInSomeMonths)
                      Text(
                        l10n.billRemindersDayOfMonthShortMonthHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.billRemindersTimeLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickReminderTime,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: AppColors.primaryInk,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatReminderTime(context),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.billRemindersRemindBefore,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _leadOptions(l10n).map((opt) {
                final selected = _leadDays == opt.days;
                return ChoiceChip(
                  label: Text(opt.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _leadDays = opt.days),
                  selectedColor: AppColors.primaryInk.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isEditing ? l10n.save : l10n.billRemindersAdd,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
