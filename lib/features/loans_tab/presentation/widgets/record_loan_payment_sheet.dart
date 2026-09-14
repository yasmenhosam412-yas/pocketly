import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/core/widgets/payment_method_chips_section.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
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
  late String _walletSource;
  bool _awaitingSubmit = false;

  bool get _isReceiving => widget.loan.isGiven;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    _walletSource = PaymentMethodsStore.defaultPresets.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    });
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

    return BlocConsumer<LoansTabBloc, LoansTabState>(
      listenWhen: (previous, current) {
        if (!_awaitingSubmit) return false;
        if (previous is! LoansTabLoaded || current is! LoansTabLoaded) {
          return false;
        }
        if (previous.status != LoansTabStatus.loadingUpdateSaved) {
          return false;
        }
        return current.status == LoansTabStatus.loaded ||
            current.status == LoansTabStatus.errorUpdateSaved;
      },
      listener: (context, state) {
        if (state is! LoansTabLoaded) return;
        _awaitingSubmit = false;
        if (state.status == LoansTabStatus.errorUpdateSaved &&
            state.error.isNotEmpty) {
          AppToast.error(context, localizeApiError(l10n, state.error));
          return;
        }
        if (state.status == LoansTabStatus.loaded) {
          FocusManager.instance.primaryFocus?.unfocus();
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        }
      },
      builder: (context, state) {
        final busy = state is LoansTabLoaded &&
            state.status == LoansTabStatus.loadingUpdateSaved;
        final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

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
                const SizedBox(height: 16),
                PaymentMethodChipsSection(
                  label: _isReceiving
                      ? l10n.loanPaymentAddToBalance
                      : l10n.loanPaymentPayFromBalance,
                  hint: _isReceiving
                      ? l10n.loanPaymentAddToBalanceHint
                      : l10n.loanPaymentPayFromBalanceHint,
                  selected: _walletSource,
                  onSelected: (src) => setState(() => _walletSource = src),
                  accentColor: AppColors.loans,
                  enabled: !busy,
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
                    onPressed: busy ? null : _submit,
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
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
          ),
        );
      },
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      AppToast.error(context, l10n.errorEnterPaymentAmount);
      return;
    }
    if (_walletSource.trim().isEmpty) {
      AppToast.error(context, l10n.errorSelectLoanPaymentSource);
      return;
    }
    final base = CurrencyConverter.toBase(amount, _currencyCode);
    if (base > widget.loan.remaining + 0.0001) {
      AppToast.error(context, l10n.errorPaymentExceedsRemaining);
      return;
    }
    setState(() => _awaitingSubmit = true);
    context.read<LoansTabBloc>().add(
      RecordLoanPaymentEvent(
        id: widget.loan.id,
        amount: base,
        walletSource: _walletSource.trim(),
        balanceEntryTitle: l10n.loanPaymentBalanceEntryTitle(
          widget.loan.personName,
        ),
      ),
    );
  }
}
