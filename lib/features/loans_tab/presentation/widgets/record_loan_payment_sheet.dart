import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';
import 'package:imrpo/features/loans_tab/presentation/bloc/loans_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class RecordLoanPaymentSheet extends StatefulWidget {
  final Loan loan;

  const RecordLoanPaymentSheet({super.key, required this.loan});

  @override
  State<RecordLoanPaymentSheet> createState() => _RecordLoanPaymentSheetState();
}

class _RecordLoanPaymentSheetState extends State<RecordLoanPaymentSheet> {
  final _amountController = TextEditingController();
  late String _currencyCode;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loan = widget.loan;

    return Padding(
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
            l10n.loanRecordPayment,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${loan.personName} · ${l10n.loanRemainingOf(Money.format(loan.remaining), Money.format(loan.principal))}',
            style: TextStyle(
              color: AppColors.textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          CurrencyAmountField(
            label: l10n.loanPaymentAmount,
            controller: _amountController,
            accentColor: AppColors.loans,
            initialCurrencyCode: _currencyCode,
            onCurrencyChanged: (c) => _currencyCode = c.code,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.loans,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _submit,
              child: Text(
                l10n.loanPaymentSubmit,
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
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      AppToast.error(context, l10n.errorEnterPaymentAmount);
      return;
    }
    final base = CurrencyConverter.toBase(amount, _currencyCode);
    if (base > widget.loan.remaining + 0.0001) {
      AppToast.error(context, l10n.errorPaymentExceedsRemaining);
      return;
    }
    context.read<LoansTabBloc>().add(
      RecordLoanPaymentEvent(id: widget.loan.id, amount: base),
    );
    Navigator.pop(context);
  }
}
