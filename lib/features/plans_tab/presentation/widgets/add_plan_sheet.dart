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
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/plans_tab/domain/entities/plan.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
import 'package:imrpo/features/plans_tab/presentation/widgets/plan_allocation_paid_from_section.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class AddPlanSheet extends StatefulWidget {
  final Plan? plan;

  const AddPlanSheet({super.key, this.plan});

  @override
  State<AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<AddPlanSheet> {
  static const _planColor = AppColors.plans;

  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _savedController = TextEditingController();
  final _otherCategoryController = TextEditingController();
  String _category = 'Savings';
  late String _currencyCode;
  DateTime? _deadline;
  String _paidFromSource = 'Cash';

  static const _otherCategory = 'Other';

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    final plan = widget.plan;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    });
    if (plan != null) {
      _titleController.text = plan.title;
      _targetController.text = _formatDisplayAmount(plan.targetAmount);
      _savedController.text = _formatDisplayAmount(plan.savedAmount);
      _deadline = plan.deadline;
      if (_categories.contains(plan.category)) {
        _category = plan.category;
      } else {
        _category = _otherCategory;
        _otherCategoryController.text = plan.category;
      }
    }
    _savedController.addListener(_onSavedTextChanged);
  }

  static const _categories = [
    'Savings',
    'Travel',
    'Purchase',
    'Education',
    _otherCategory,
  ];

  bool get _isOtherCategory => _category == _otherCategory;

  double get _previousSavedBase => widget.plan?.savedAmount ?? 0;

  bool get _requiresPaidFrom {
    final saved = double.tryParse(_savedController.text.trim());
    if (saved == null) return false;
    final baseSaved = CurrencyConverter.toBase(saved, _currencyCode);
    return baseSaved > _previousSavedBase;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _savedController
      ..removeListener(_onSavedTextChanged)
      ..dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  void _onSavedTextChanged() {
    if (mounted) setState(() {});
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
              _isEditing ? l10n.planEditGoal : l10n.planAddPlan,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 24),
            CustomFormField(
              label: l10n.goalTitleLabel,
              hint: l10n.goalTitleHint,
              controller: _titleController,
              obscure: false,
              icon: Icons.flag_outlined,
            ),
            const SizedBox(height: 16),
            CurrencyAmountField(
              label: l10n.targetAmountLabel,
              controller: _targetController,
              accentColor: _planColor,
              initialCurrencyCode: _currencyCode,
              onCurrencyChanged: (c) => _currencyCode = c.code,
            ),
            const SizedBox(height: 16),
            CurrencyAmountField(
              label: l10n.amountSavedLabel,
              controller: _savedController,
              accentColor: _planColor,
              initialCurrencyCode: _currencyCode,
              onCurrencyChanged: (c) => _currencyCode = c.code,
            ),
            if (_requiresPaidFrom) ...[
              const SizedBox(height: 16),
              PlanAllocationPaidFromSection(
                selectedSource: _paidFromSource,
                onSelected: (src) => setState(() => _paidFromSource = src),
                accentColor: _planColor,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.categoryField,
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
              children: _categories.map((cat) {
                final selected = _category == cat;
                return ChoiceChip(
                  label: Text(localizePlanCategory(l10n, cat)),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: _planColor,
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
              }).toList(),
            ),
            if (_isOtherCategory) ...[
              const SizedBox(height: 16),
              CustomFormField(
                label: l10n.otherCategoryField,
                hint: l10n.otherCategoryHint,
                controller: _otherCategoryController,
                obscure: false,
                icon: Icons.category_outlined,
              ),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDeadline,
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
                      color: _planColor.withValues(alpha: 0.9),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _deadline == null
                          ? l10n.setDeadlineOptional
                          : _formatDate(context, _deadline!),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _deadline == null
                            ? AppColors.textColor.withValues(alpha: 0.5)
                            : AppColors.textColor,
                      ),
                    ),
                    const Spacer(),
                    if (_deadline != null)
                      GestureDetector(
                        onTap: () => setState(() => _deadline = null),
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
                onPressed: _submit,
                child: Text(
                  _isEditing ? l10n.updateGoal : l10n.savePlan,
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
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _planColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final target = double.tryParse(_targetController.text.trim());
    final saved = double.tryParse(_savedController.text.trim());

    final l10n = AppLocalizations.of(context)!;
    if (title.isEmpty) {
      _showError(l10n.errorEnterGoalTitle);
      return;
    }
    if (target == null || target <= 0) {
      _showError(l10n.errorEnterTargetAmount);
      return;
    }
    if (saved == null || saved < 0) {
      _showError(l10n.errorEnterAmountSaved);
      return;
    }
    if (saved > target) {
      _showError(l10n.errorSavedExceedsTarget);
      return;
    }

    final category = _resolvedCategory();
    if (category == null) {
      _showError(l10n.errorEnterCategoryName);
      return;
    }

    final baseTarget = CurrencyConverter.toBase(target, _currencyCode);
    final baseSaved = CurrencyConverter.toBase(saved, _currencyCode);

    if (baseSaved > baseTarget) {
      _showError(l10n.errorSavedExceedsTarget);
      return;
    }

    final needsPaidFrom = baseSaved > _previousSavedBase;
    final paidFrom = _paidFromSource.trim();
    if (needsPaidFrom && paidFrom.isEmpty) {
      _showError(l10n.planAllocationSelectPaidFrom);
      return;
    }

    final allocationTitle = l10n.balancePlanAllocationExpenseTitle(
      localizeDemoTitle(l10n, title),
    );

    final bloc = context.read<PlansTabBloc>();
    if (_isEditing) {
      bloc.add(
        UpdatePlanEvent(
          id: widget.plan!.id,
          title: title,
          category: category,
          targetAmount: baseTarget,
          savedAmount: baseSaved,
          deadline: _deadline,
          expensePaidFrom: needsPaidFrom ? paidFrom : null,
          expenseTitle: needsPaidFrom ? allocationTitle : null,
        ),
      );
    } else {
      bloc.add(
        AddPlanEvent(
          title: title,
          category: category,
          targetAmount: baseTarget,
          savedAmount: baseSaved,
          deadline: _deadline,
          expensePaidFrom: needsPaidFrom ? paidFrom : null,
          expenseTitle: needsPaidFrom ? allocationTitle : null,
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

  String? _resolvedCategory() {
    if (!_isOtherCategory) return _category;
    final custom = _otherCategoryController.text.trim();
    if (custom.isEmpty) return null;
    return custom;
  }

  void _showError(String message) {
    AppToast.error(context, message);
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }
}
