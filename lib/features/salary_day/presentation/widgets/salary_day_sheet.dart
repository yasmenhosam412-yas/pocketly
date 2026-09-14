import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/config/root_navigator.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/salary_day_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/plans_tab/domain/entities/plan.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
import 'package:imrpo/features/salary_day/domain/salary_day_allocator.dart';
import 'package:imrpo/l10n/app_localizations.dart';

Future<void> showSalaryDaySheet(
  BuildContext context, {
  double? initialAmountInBase,
  PlansTabBloc? plansBloc,
  ExpensesTabBloc? expensesBloc,
}) async {
  final plans = plansBloc ?? context.read<PlansTabBloc>();
  final expenses = expensesBloc ?? context.read<ExpensesTabBloc>();
  plans.add(const LoadPlansEvent());

  final host = rootNavigatorKey.currentContext ?? context;
  final message = await showModalBottomSheet<String>(
    context: host,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: plans),
          BlocProvider.value(value: expenses),
        ],
        child: SalaryDaySheet(initialAmountInBase: initialAmountInBase),
      ),
    ),
  );
  final toastContext = rootNavigatorKey.currentContext ?? context;
  if (message == null) return;
  if (!(toastContext.mounted || context.mounted)) return;
  AppToast.show(
    toastContext.mounted ? toastContext : context,
    message,
  );
}

class SalaryDaySheet extends StatefulWidget {
  final double? initialAmountInBase;

  const SalaryDaySheet({super.key, this.initialAmountInBase});

  @override
  State<SalaryDaySheet> createState() => _SalaryDaySheetState();
}

class _SalaryDaySheetState extends State<SalaryDaySheet> {
  final _amountController = TextEditingController();
  late String _currencyCode;
  late int _day;
  late double _rentPct;
  late double _billsPct;
  late double _plansPct;
  late bool _prompt;
  bool _submitting = false;
  List<SalaryAllocationLine> _lines = [];

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SalaryDayPreferences>();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    _day = prefs.dayOfMonth;
    _rentPct = prefs.rentPercent;
    _billsPct = prefs.billsPercent;
    _plansPct = prefs.plansPercent;
    _prompt = prefs.promptOnSalaryIncome;
    if (widget.initialAmountInBase != null &&
        widget.initialAmountInBase! > 0) {
      final display = CurrencyConverter.fromBase(
        widget.initialAmountInBase!,
        _currencyCode,
      );
      _amountController.text = display == display.roundToDouble()
          ? display.toInt().toString()
          : display.toStringAsFixed(2);
    }
    _amountController.addListener(_rebuildLines);
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildLines());
  }

  @override
  void dispose() {
    _amountController.removeListener(_rebuildLines);
    _amountController.dispose();
    super.dispose();
  }

  double? get _amountInBase {
    final display = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    if (display == null) return null;
    return CurrencyConverter.toBase(display, _currencyCode);
  }

  void _rebuildLines() {
    final amount = _amountInBase;
    final plansState = context.read<PlansTabBloc>().state;
    final plans =
        plansState is PlansTabLoaded ? plansState.plans : const <Plan>[];
    if (amount == null || amount <= 0) {
      setState(() => _lines = []);
      return;
    }
    final draft = SalaryDayAllocator.buildDraft(
      salaryAmountInBase: amount,
      rentPercent: _rentPct,
      billsPercent: _billsPct,
      plansPercent: _plansPct,
      plans: plans,
    );
    setState(() => _lines = draft.lines);
  }

  Future<void> _savePrefs() async {
    await getIt<SalaryDayPreferences>().save(
      dayOfMonth: _day,
      rentPercent: _rentPct,
      billsPercent: _billsPct,
      plansPercent: _plansPct,
      promptOnSalaryIncome: _prompt,
    );
  }

  Future<void> _apply() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = _amountInBase;
    if (amount == null || amount <= 0) {
      AppToast.show(context, l10n.errorEnterValidAmount, error: true);
      return;
    }
    await _savePrefs();
    final draft = SalaryAllocationDraft(
      salaryAmountInBase: amount,
      paidFrom: 'Salary',
      lines: _lines,
    );
    setState(() => _submitting = true);
    try {
      final result = await getIt<SalaryDayAllocator>().apply(draft);
      if (!mounted) return;
      result.fold(
        (f) => AppToast.show(
          context,
          localizeApiError(l10n, f.error),
          error: true,
        ),
        (count) {
          context
              .read<ExpensesTabBloc>()
              .add(const LoadExpensesEvent(force: true));
          context.read<PlansTabBloc>().add(const LoadPlansEvent(force: true));
          Navigator.of(context).pop(l10n.salaryDaySuccess(count));
        },
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final leftoverPct =
        (100 - _rentPct - _billsPct - _plansPct).clamp(0.0, 100.0);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: AbsorbPointer(
        absorbing: _submitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
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
              const SizedBox(height: 16),
              Text(
                l10n.salaryDayTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.salaryDaySubtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.salaryDayPaydayLabel(_day),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ),
              Slider(
                value: _day.toDouble(),
                min: 1,
                max: 28,
                divisions: 27,
                label: '$_day',
                activeColor: AppColors.income,
                onChanged: (v) => setState(() => _day = v.round()),
              ),
              CurrencyAmountField(
                label: l10n.salaryDayAmountLabel,
                controller: _amountController,
                accentColor: AppColors.income,
                initialCurrencyCode: _currencyCode,
                onCurrencyChanged: (c) {
                  setState(() => _currencyCode = c.code);
                  _rebuildLines();
                },
              ),
              const SizedBox(height: 12),
              _pctSlider(
                l10n.salaryDayRentPct,
                _rentPct,
                (v) {
                  setState(() => _rentPct = v);
                  _rebuildLines();
                },
              ),
              _pctSlider(
                l10n.salaryDayBillsPct,
                _billsPct,
                (v) {
                  setState(() => _billsPct = v);
                  _rebuildLines();
                },
              ),
              _pctSlider(
                l10n.salaryDayPlansPct,
                _plansPct,
                (v) {
                  setState(() => _plansPct = v);
                  _rebuildLines();
                },
              ),
              Text(
                l10n.salaryDayLeftoverPct(leftoverPct.toStringAsFixed(0)),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor.withValues(alpha: 0.7),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.salaryDayPromptToggle),
                value: _prompt,
                activeThumbColor: AppColors.income,
                onChanged: (v) => setState(() => _prompt = v),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.salaryDayPreview,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              if (_lines.isEmpty)
                Text(
                  l10n.salaryDayPreviewEmpty,
                  style: TextStyle(
                    color: AppColors.textColor.withValues(alpha: 0.55),
                  ),
                )
              else
                ..._lines.map((line) {
                  final isLeftover =
                      line.kind == SalaryAllocationKind.leftover;
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: line.enabled,
                    onChanged: isLeftover
                        ? null
                        : (v) {
                            setState(() {
                              final i = _lines.indexOf(line);
                              _lines[i] = line.copyWith(enabled: v ?? false);
                            });
                          },
                    title: Text(line.title),
                    subtitle: Text(
                      isLeftover
                          ? l10n.salaryDayLeftoverHint
                          : localizeExpenseCategory(l10n, line.category),
                    ),
                    secondary: Text(
                      Money.format(line.amountInBase),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isLeftover
                            ? AppColors.income
                            : AppColors.textColor,
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.income,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.salaryDayApply),
                ),
              ),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        final message = l10n.salaryDayRulesSaved;
                        await _savePrefs();
                        if (!mounted) return;
                        navigator.pop(message);
                      },
                child: Text(l10n.salaryDaySaveRulesOnly),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pctSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label · ${value.toStringAsFixed(0)}%',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        Slider(
          value: value.clamp(0, 100),
          min: 0,
          max: 100,
          divisions: 20,
          activeColor: AppColors.income,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
