import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/core/widgets/payment_method_chips_section.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/incomes_tab/domain/entities/income.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class AddIncomeSheet extends StatefulWidget {
  final Income? income;
  final String? initialTitle;
  final double? initialAmount;
  final DateTime? initialDate;

  const AddIncomeSheet({
    super.key,
    this.income,
    this.initialTitle,
    this.initialAmount,
    this.initialDate,
  });

  @override
  State<AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<AddIncomeSheet> {
  final _titleController = TextEditingController();
  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  late String _currencyCode;
  DateTime _date = DateTime.now();

  bool get _isEditing => widget.income != null;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    final income = widget.income;
    if (income != null) {
      _titleController.text = income.title;
      _sourceController.text = income.category;
      if (income.entryCurrency != null && income.entryAmount != null) {
        _currencyCode = income.entryCurrency!;
        _amountController.text = _formatRawAmount(income.entryAmount!);
      } else {
        _amountController.text = _formatDisplayAmount(income.amount);
      }
      _date = income.date;
    } else {
      if (widget.initialTitle != null) {
        _titleController.text = widget.initialTitle!;
      }
      if (widget.initialAmount != null) {
        _amountController.text = _formatRawAmount(widget.initialAmount!);
      }
      if (widget.initialDate != null) {
        _date = widget.initialDate!;
      }
      if (_sourceController.text.trim().isEmpty) {
        _sourceController.text = PaymentMethodsStore.defaultPresets.first;
      }
    }
  }

  bool _didPop = false;

  void _closeSheetOnSuccess() {
    if (_didPop) return;
    _didPop = true;
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(_isEditing ? 'updated' : 'added');
    });
  }

  bool _isSubmitting(IncomesTabState state) =>
      state.status == IncomesTabStatus.loadingAdd ||
      state.status == IncomesTabStatus.loadingUpdate;

  @override
  void dispose() {
    _titleController.dispose();
    _sourceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<IncomesTabBloc, IncomesTabState>(
      listenWhen: (previous, current) {
        final finishedSubmit =
            (previous.status == IncomesTabStatus.loadingAdd ||
                previous.status == IncomesTabStatus.loadingUpdate) &&
            current.status == IncomesTabStatus.loaded;
        final failedSubmit =
            current.status == IncomesTabStatus.errorAdd ||
            current.status == IncomesTabStatus.errorUpdate;
        return finishedSubmit || failedSubmit;
      },
      listener: (context, state) {
        if (state.status == IncomesTabStatus.errorAdd ||
            state.status == IncomesTabStatus.errorUpdate) {
          _showError(localizeApiError(l10n, state.message));
          return;
        }
        _closeSheetOnSuccess();
      },
      child: BlocBuilder<IncomesTabBloc, IncomesTabState>(
        buildWhen: (previous, current) =>
            _isSubmitting(previous) != _isSubmitting(current) ||
            previous.incomes.length != current.incomes.length,
        builder: (context, state) {
          return PopScope(
            canPop: !_isSubmitting(state),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                    const SizedBox(height: 20),
                    Text(
                      _isEditing ? l10n.editIncome : l10n.addIncome,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PaymentMethodChipsSection(
                      label: l10n.incomeSourceField,
                      hint: l10n.addIncomeSheetSourceHint,
                      selected: _sourceController.text.trim().isEmpty
                          ? PaymentMethodsStore.defaultPresets.first
                          : _sourceController.text.trim(),
                      onSelected: (src) =>
                          setState(() => _sourceController.text = src),
                      accentColor: AppColors.income,
                    ),
                    const SizedBox(height: 16),
                    CustomFormField(
                      label: l10n.titleField,
                      hint: l10n.addIncomeSheetTitleHint,
                      controller: _titleController,
                      obscure: false,
                      icon: Icons.label_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    CurrencyAmountField(
                      label: l10n.amountField,
                      controller: _amountController,
                      accentColor: AppColors.income,
                      initialCurrencyCode: _currencyCode,
                      onCurrencyChanged: (c) => _currencyCode = c.code,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.income.withValues(alpha: 0.8),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatDate(context, _date),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textColor,
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
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.income,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed:
                            _isSubmitting(state) ? null : _submit,
                        child: _isSubmitting(state)
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditing
                                    ? l10n.updateIncome
                                    : l10n.saveIncome,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.income,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _submit() {
    final source = _sourceController.text.trim();
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final l10n = AppLocalizations.of(context)!;

    if (source.isEmpty) {
      _showError(l10n.errorEnterCategoryName);
      return;
    }
    if (title.isEmpty) {
      _showError(l10n.errorEnterTitle);
      return;
    }
    if (amount == null || amount <= 0) {
      _showError(l10n.errorEnterValidAmount);
      return;
    }

    final baseAmount = CurrencyConverter.toBase(amount, _currencyCode);
    final entryCurrency = CurrencyConverter.isDefaultEntryCurrency(_currencyCode)
        ? null
        : _currencyCode;
    final entryAmount = entryCurrency != null ? amount : null;

    final bloc = context.read<IncomesTabBloc>();
    if (_isEditing) {
      bloc.add(
        UpdateIncomeEvent(
          id: widget.income!.id,
          title: title,
          category: source,
          amount: baseAmount,
          date: _date,
          entryCurrency: entryCurrency,
          entryAmount: entryAmount,
        ),
      );
    } else {
      bloc.add(
        AddIncomeEvent(
          title: title,
          category: source,
          amount: baseAmount,
          date: _date,
          entryCurrency: entryCurrency,
          entryAmount: entryAmount,
        ),
      );
    }
  }

  String _formatDisplayAmount(double baseAmount) {
    final display = CurrencyConverter.fromBase(baseAmount, _currencyCode);
    return _formatRawAmount(display);
  }

  String _formatRawAmount(double amount) {
    return amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
  }

  void _showError(String message) {
    AppToast.error(context, message);
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }
}
