import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';
import 'package:imrpo/features/loans_tab/presentation/bloc/loans_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class AddLoanSheet extends StatefulWidget {
  final Loan? loan;

  const AddLoanSheet({super.key, this.loan});

  @override
  State<AddLoanSheet> createState() => _AddLoanSheetState();
}

class _AddLoanSheetState extends State<AddLoanSheet> {
  static const _loanColor = AppColors.loans;

  final _personController = TextEditingController();
  final _principalController = TextEditingController();
  final _repaidController = TextEditingController();
  final _notesController = TextEditingController();
  LoanDirection _direction = LoanDirection.given;
  late String _currencyCode;
  DateTime? _dueDate;

  bool get _isEditing => widget.loan != null;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    final loan = widget.loan;
    if (loan != null) {
      _personController.text = loan.personName;
      _principalController.text = _formatDisplayAmount(loan.principal);
      _repaidController.text = _formatDisplayAmount(loan.repaidAmount);
      _notesController.text = loan.notes;
      _direction = loan.direction;
      _dueDate = loan.dueDate;
    }
  }

  @override
  void dispose() {
    _personController.dispose();
    _principalController.dispose();
    _repaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    final l10n = AppLocalizations.of(context)!;

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
            const SizedBox(height: 20),
            Text(
              _isEditing ? l10n.loanEditTitle : l10n.loanAddTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 24),
            CustomFormField(
              label: l10n.loanPersonLabel,
              hint: l10n.loanPersonHint,
              controller: _personController,
              obscure: false,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.loanDirectionLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _directionChip(
                  LoanDirection.given,
                  l10n.loanDirectionGiven,
                ),
                _directionChip(
                  LoanDirection.received,
                  l10n.loanDirectionReceived,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CurrencyAmountField(
              label: l10n.loanPrincipalLabel,
              controller: _principalController,
              accentColor: _loanColor,
              initialCurrencyCode: _currencyCode,
              onCurrencyChanged: (c) => _currencyCode = c.code,
            ),
            const SizedBox(height: 16),
            CurrencyAmountField(
              label: l10n.loanRepaidLabel,
              controller: _repaidController,
              accentColor: _loanColor,
              initialCurrencyCode: _currencyCode,
              onCurrencyChanged: (c) => _currencyCode = c.code,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDueDate,
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
                      Icons.event_outlined,
                      color: _loanColor.withValues(alpha: 0.9),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate == null
                          ? l10n.loanDueDateOptional
                          : _formatDate(context, _dueDate!),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _dueDate == null
                            ? AppColors.textColor.withValues(alpha: 0.5)
                            : AppColors.textColor,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.textColor.withValues(alpha: 0.4),
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textColor.withValues(alpha: 0.4),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomFormField(
              label: l10n.loanNotesOptional,
              hint: l10n.loanNotesHint,
              controller: _notesController,
              obscure: false,
              icon: Icons.notes_rounded,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _loanColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _submit,
                child: Text(
                  _isEditing ? l10n.loanUpdate : l10n.loanSave,
                  style: const TextStyle(
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
    );
  }

  Widget _directionChip(
    LoanDirection value,
    String label,
  ) {
    final selected = _direction == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _direction = value),
      selectedColor: _loanColor,
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
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _loanColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    final person = _personController.text.trim();
    final principal = double.tryParse(_principalController.text.trim());
    final repaidRaw = _repaidController.text.trim();
    final repaid = repaidRaw.isEmpty ? 0.0 : double.tryParse(repaidRaw);

    final l10n = AppLocalizations.of(context)!;
    if (person.isEmpty) {
      _showError(l10n.errorEnterPersonName);
      return;
    }
    if (principal == null || principal <= 0) {
      _showError(l10n.errorEnterLoanAmount);
      return;
    }
    if (repaid == null || repaid < 0) {
      _showError(l10n.errorEnterLoanAmount);
      return;
    }

    final basePrincipal = CurrencyConverter.toBase(principal, _currencyCode);
    final baseRepaid = CurrencyConverter.toBase(repaid, _currencyCode);
    if (baseRepaid > basePrincipal) {
      _showError(l10n.errorRepaidExceedsPrincipal);
      return;
    }

    final bloc = context.read<LoansTabBloc>();
    if (_isEditing) {
      bloc.add(
        UpdateLoanEvent(
          id: widget.loan!.id,
          personName: person,
          direction: _direction,
          principal: basePrincipal,
          repaidAmount: baseRepaid,
          dueDate: _dueDate,
          notes: _notesController.text.trim(),
        ),
      );
    } else {
      bloc.add(
        AddLoanEvent(
          personName: person,
          direction: _direction,
          principal: basePrincipal,
          repaidAmount: baseRepaid,
          dueDate: _dueDate,
          notes: _notesController.text.trim(),
        ),
      );
    }
    Navigator.pop(context);
  }

  String _formatDisplayAmount(double baseAmount) {
    final display = CurrencyConverter.fromBase(baseAmount, _currencyCode);
    return display == display.roundToDouble()
        ? display.toInt().toString()
        : display.toStringAsFixed(2);
  }

  void _showError(String message) {
    AppToast.error(context, message);
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }
}
