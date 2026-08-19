import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/plans_tab/domain/entities/plan.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
import 'package:imrpo/features/plans_tab/presentation/widgets/plan_allocation_paid_from_section.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class AddToPlanFromBalanceSheet extends StatefulWidget {
  final double availableBalanceBase;

  const AddToPlanFromBalanceSheet({
    super.key,
    required this.availableBalanceBase,
  });

  @override
  State<AddToPlanFromBalanceSheet> createState() =>
      _AddToPlanFromBalanceSheetState();
}

class _AddToPlanFromBalanceSheetState extends State<AddToPlanFromBalanceSheet> {
  static const _planColor = AppColors.plans;

  final _amountController = TextEditingController();
  late String _currencyCode;
  Plan? _selectedPlan;
  String _paidFromSource = 'Cash';
  bool _awaitingSubmit = false;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
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

  List<Plan> _activePlans(List<Plan> plans) =>
      plans.where((p) => !p.isCompleted).toList();

  double _remainingOnPlan(Plan plan) =>
      (plan.targetAmount - plan.savedAmount).clamp(0, double.infinity);

  void _fillMaxForPlan(Plan plan) {
    final maxBase = _remainingOnPlan(plan);
    final capBase = widget.availableBalanceBase < maxBase
        ? widget.availableBalanceBase
        : maxBase;
    final display = CurrencyConverter.fromBase(capBase, _currencyCode);
    _amountController.text = display == display.roundToDouble()
        ? display.toInt().toString()
        : display.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<PlansTabBloc, PlansTabState>(
      listenWhen: (previous, current) {
        if (!_awaitingSubmit) return false;
        if (previous is! PlansTabLoaded || current is! PlansTabLoaded) {
          return false;
        }
        if (previous.status != PlansTabStatus.loadingUpdateSaved) {
          return false;
        }
        return current.status == PlansTabStatus.loaded ||
            current.status == PlansTabStatus.errorUpdateSaved;
      },
      listener: (context, state) {
        if (state is! PlansTabLoaded) return;
        _awaitingSubmit = false;
        if (state.status == PlansTabStatus.errorUpdateSaved &&
            state.error.isNotEmpty) {
          _showError(localizeApiError(l10n, state.error));
          return;
        }
        if (state.status == PlansTabStatus.loaded) {
          FocusManager.instance.primaryFocus?.unfocus();
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        }
      },
      builder: (context, state) {
        final isSubmitting = _awaitingSubmit &&
            state is PlansTabLoaded &&
            state.status == PlansTabStatus.loadingUpdateSaved;
        final plans = state is PlansTabLoaded ? state.plans : <Plan>[];
        final active = _activePlans(plans);

        if (_selectedPlan == null && active.isNotEmpty) {
          _selectedPlan = active.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _amountController.text.isEmpty) {
              _fillMaxForPlan(_selectedPlan!);
            }
          });
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: _sheetMaxHeight(context),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  l10n.balanceAddToPlanTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.balanceAddToPlanHint(
                    Money.format(widget.availableBalanceBase),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textColor.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                if (active.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.balanceNoPlansForAllocation,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textColor.withValues(alpha: 0.55),
                      ),
                    ),
                  )
                else ...[
                  Text(
                    l10n.balanceSelectPlan,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...active.map((plan) {
                    final selected = _selectedPlan?.id == plan.id;
                    final remaining = _remainingOnPlan(plan);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: selected
                            ? _planColor.withValues(alpha: 0.1)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            setState(() {
                              _selectedPlan = plan;
                              _fillMaxForPlan(plan);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? _planColor
                                    : AppColors.border,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: selected
                                      ? _planColor
                                      : AppColors.textColor.withValues(
                                          alpha: 0.35,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localizeDemoTitle(l10n, plan.title),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.balancePlanRemaining(
                                          Money.format(remaining),
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textColor
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
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
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  PlanAllocationPaidFromSection(
                    selectedSource: _paidFromSource,
                    onSelected: (src) => setState(() => _paidFromSource = src),
                    accentColor: _planColor,
                  ),
                  const SizedBox(height: 16),
                  CurrencyAmountField(
                    label: l10n.balanceAmountToAllocate,
                    controller: _amountController,
                    accentColor: _planColor,
                    initialCurrencyCode: _currencyCode,
                    onCurrencyChanged: (c) => _currencyCode = c.code,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _planColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _selectedPlan == null || isSubmitting
                          ? null
                          : _submit,
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
                        l10n.balanceAddToPlan,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  double _sheetMaxHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    final available = media.size.height
        - media.viewInsets.bottom
        - media.padding.vertical;
    return (available * 0.75).clamp(160.0, media.size.height);
  }

  void _submit() {
    final plan = _selectedPlan;
    if (plan == null) return;

    final paidFrom = _paidFromSource.trim();
    if (paidFrom.isEmpty) {
      _showError(AppLocalizations.of(context)!.planAllocationSelectPaidFrom);
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError(AppLocalizations.of(context)!.errorEnterValidSavedAmount);
      return;
    }

    final baseAmount = CurrencyConverter.toBase(amount, _currencyCode);
    if (baseAmount > widget.availableBalanceBase) {
      _showError(AppLocalizations.of(context)!.balanceAmountExceedsSurplus);
      return;
    }

    final remaining = _remainingOnPlan(plan);
    if (baseAmount > remaining) {
      _showError(AppLocalizations.of(context)!.errorSavedExceedsTarget);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _awaitingSubmit = true);
    context.read<PlansTabBloc>().add(
          AddAmountToPlanEvent(
            id: plan.id,
            amountToAdd: baseAmount,
            expenseTitle: l10n.balancePlanAllocationExpenseTitle(
              localizeDemoTitle(l10n, plan.title),
            ),
            expensePaidFrom: paidFrom,
          ),
        );
  }

  void _showError(String message) {
    AppToast.error(context, message);
  }
}
