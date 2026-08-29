import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/features/plans_tab/domain/entities/plan.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';

class UpdatePlanSavedSheet extends StatefulWidget {
  final Plan plan;

  const UpdatePlanSavedSheet({super.key, required this.plan});

  @override
  State<UpdatePlanSavedSheet> createState() => _UpdatePlanSavedSheetState();
}

class _UpdatePlanSavedSheetState extends State<UpdatePlanSavedSheet> {
  static const _planColor = AppColors.plans;

  late final TextEditingController _savedController;
  late String _currencyCode;
  bool _awaitingSubmit = false;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    final displaySaved = CurrencyConverter.fromBase(
      widget.plan.savedAmount,
      _currencyCode,
    );
    _savedController = TextEditingController(
      text: displaySaved == displaySaved.roundToDouble()
          ? displaySaved.toInt().toString()
          : displaySaved.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _savedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<PlansTabBloc, PlansTabState>(
      listenWhen: (previous, current) {
        if (!_awaitingSubmit) return false;
        if (previous is! PlansTabLoaded || current is! PlansTabLoaded) {
          return false;
        }
        if (previous.status != PlansTabStatus.loadingUpdateSaved &&
            previous.status != PlansTabStatus.loadingUpdate) {
          return false;
        }
        return current.status == PlansTabStatus.loaded ||
            current.status == PlansTabStatus.errorUpdateSaved ||
            current.status == PlansTabStatus.errorUpdate;
      },
      listener: (context, state) {
        if (state is! PlansTabLoaded) return;
        _awaitingSubmit = false;
        if (state.status == PlansTabStatus.errorUpdateSaved ||
            state.status == PlansTabStatus.errorUpdate) {
          if (state.error.isNotEmpty) {
            _showError(localizeApiError(l10n, state.error));
          }
          return;
        }
        if (state.status == PlansTabStatus.loaded) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final isSubmitting = _awaitingSubmit &&
            state is PlansTabLoaded &&
            (state.status == PlansTabStatus.loadingUpdateSaved ||
                state.status == PlansTabStatus.loadingUpdate);

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
                  l10n.updateSavedTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizeDemoTitle(l10n, plan.title),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _planColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _planColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.targetWithAmount(Money.format(plan.targetAmount)),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${(plan.progress * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _planColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CurrencyAmountField(
                  label: l10n.amountSavedLabel,
                  controller: _savedController,
                  accentColor: _planColor,
                  initialCurrencyCode: _currencyCode,
                  onCurrencyChanged: (c) => _currencyCode = c.code,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _planColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.saveAmountButton,
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
        );
      },
    );
  }

  void _submit() {
    final saved = double.tryParse(_savedController.text.trim());
    final l10n = AppLocalizations.of(context)!;

    if (saved == null || saved < 0) {
      _showError(l10n.errorEnterValidSavedAmount);
      return;
    }

    if (CurrencyConverter.exceedsCap(
      CurrencyConverter.toBase(saved, _currencyCode),
      widget.plan.targetAmount,
      currencyCode: _currencyCode,
    )) {
      _showError(l10n.errorSavedExceedsTarget);
      return;
    }

    final baseSaved = CurrencyConverter.toBaseAtMost(
      saved,
      _currencyCode,
      widget.plan.targetAmount,
    );

    setState(() => _awaitingSubmit = true);
    context.read<PlansTabBloc>().add(
          UpdatePlanSavedEvent(
            id: widget.plan.id,
            savedAmount: baseSaved,
          ),
        );
  }

  void _showError(String message) {
    AppToast.error(context, message);
  }
}
