import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/receipt_storage_service.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/receipt_image_validator.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/expenses_tab/presentation/widgets/receipt_attachment_section.dart';
import 'package:imrpo/features/plans_tab/domain/entities/plan.dart';
import 'package:imrpo/features/plans_tab/presentation/bloc/plans_tab_bloc.dart';
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
  File? _imageFile;
  String? _existingImageUrl;
  bool _imageRemoved = false;
  bool _submitting = false;

  static const _otherCategory = 'Other';

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    final plan = widget.plan;
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
      _existingImageUrl = plan.imageUrl;
    }
  }

  static const _categories = [
    'Savings',
    'Travel',
    'Purchase',
    'Education',
    _otherCategory,
  ];

  bool get _isOtherCategory => _category == _otherCategory;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    _otherCategoryController.dispose();
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
              _isEditing ? l10n.planEditGoal : l10n.planAddPlan,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            if (!_isEditing) ...[
              const SizedBox(height: 8),
              Text(
                l10n.planHowItHelps,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textColor.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.planTemplatesTitle,
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
                  _TemplateChip(
                    label: l10n.planTemplateEmergency,
                    onTap: () => _applyTemplate(
                      l10n.planTemplateEmergency,
                      'Savings',
                    ),
                  ),
                  _TemplateChip(
                    label: l10n.planTemplateVacation,
                    onTap: () => _applyTemplate(
                      l10n.planTemplateVacation,
                      'Travel',
                    ),
                  ),
                  _TemplateChip(
                    label: l10n.planTemplateNewPhone,
                    onTap: () => _applyTemplate(
                      l10n.planTemplateNewPhone,
                      'Purchase',
                    ),
                  ),
                  _TemplateChip(
                    label: l10n.planTemplateEducation,
                    onTap: () => _applyTemplate(
                      l10n.planTemplateEducation,
                      'Education',
                    ),
                  ),
                ],
              ),
            ],
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
            const SizedBox(height: 6),
            Text(
              l10n.amountSavedHint,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textColor.withValues(alpha: 0.55),
              ),
            ),
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
            ReceiptAttachmentSection(
              localFile: _imageFile,
              remoteUrl: _existingImageUrl,
              removed: _imageRemoved,
              accentColor: _planColor,
              attachIcon: Icons.add_photo_alternate_outlined,
              label: l10n.planImageLabel,
              attachLabel: l10n.planImageAttach,
              replaceLabel: l10n.planImageReplace,
              removeLabel: l10n.planImageRemove,
              onLocalFileChanged: (file) => setState(() {
                _imageFile = file;
                _imageRemoved = false;
              }),
              onRemove: () => setState(() {
                _imageFile = null;
                _imageRemoved = true;
              }),
            ),
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
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
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

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final target = double.tryParse(_targetController.text.trim());
    final savedRaw = _savedController.text.trim();
    final saved = savedRaw.isEmpty ? 0.0 : double.tryParse(savedRaw);

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
    if (saved > target + 0.01) {
      _showError(l10n.errorSavedExceedsTarget);
      return;
    }

    final category = _resolvedCategory();
    if (category == null) {
      _showError(l10n.errorEnterCategoryName);
      return;
    }

    final baseTarget = CurrencyConverter.toBase(target, _currencyCode);
    final baseSaved = CurrencyConverter.toBaseAtMost(
      saved,
      _currencyCode,
      baseTarget,
    );

    setState(() => _submitting = true);
    String? imageUrl = _imageRemoved ? null : _existingImageUrl;
    try {
      final storage = getIt<ReceiptStorageService>();
      if (_imageRemoved && _existingImageUrl != null) {
        await storage.deleteByPublicUrl(_existingImageUrl);
      }
      if (_imageFile != null) {
        if (!ReceiptImageValidator.isSupportedPath(_imageFile!.path)) {
          if (!mounted) return;
          setState(() => _submitting = false);
          _showError(l10n.expenseReceiptInvalidType);
          return;
        }
        if (_existingImageUrl != null) {
          await storage.deleteByPublicUrl(_existingImageUrl);
        }
        imageUrl = await storage.uploadReceipt(_imageFile!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(l10n.planImageUploadFailed);
      return;
    }
    if (!mounted) return;

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
          imageUrl: imageUrl,
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
          imageUrl: imageUrl,
        ),
      );
    }
    Navigator.pop(context);
  }

  void _applyTemplate(String title, String category) {
    setState(() {
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = title;
      }
      _category = category;
      _otherCategoryController.clear();
      _deadline ??= DateTime.now().add(const Duration(days: 180));
    });
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

class _TemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.plans),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textColor,
        ),
      ),
      onPressed: onTap,
      backgroundColor: AppColors.plans.withValues(alpha: 0.1),
      side: BorderSide(color: AppColors.plans.withValues(alpha: 0.22)),
    );
  }
}
