import 'package:flutter/material.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Returns the new source name, or null if cancelled.
Future<String?> showRenameIncomeSourceSheet(
  BuildContext context, {
  required String currentSource,
  required List<String> existingSources,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RenameIncomeSourceSheet(
      currentSource: currentSource,
      existingSources: existingSources,
    ),
  );
}

class _RenameIncomeSourceSheet extends StatefulWidget {
  final String currentSource;
  final List<String> existingSources;

  const _RenameIncomeSourceSheet({
    required this.currentSource,
    required this.existingSources,
  });

  @override
  State<_RenameIncomeSourceSheet> createState() =>
      _RenameIncomeSourceSheetState();
}

class _RenameIncomeSourceSheetState extends State<_RenameIncomeSourceSheet> {
  late final TextEditingController _controller;
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentSource);
    if (PaymentMethodsStore.defaultPresets.contains(widget.currentSource)) {
      _selectedPreset = widget.currentSource;
    }
    _controller.addListener(() {
      if (_selectedPreset != null && _controller.text != _selectedPreset) {
        setState(() => _selectedPreset = null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPreset(String source) {
    setState(() {
      _selectedPreset = source;
      _controller.text = source;
    });
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorEnterCategoryName),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }
    if (name == widget.currentSource) {
      Navigator.pop(context);
      return;
    }
    final taken = widget.existingSources
        .where((s) => s != widget.currentSource)
        .contains(name);
    if (taken) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.incomeSourceNameTaken),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
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
              l10n.incomeSourceRenameTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.incomeSourceRenameHint(
                localizeIncomeCategory(l10n, widget.currentSource),
              ),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColor.withValues(alpha: 0.6),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethodsStore.defaultPresets.map((source) {
                final selected = _selectedPreset == source;
                return ChoiceChip(
                  label: Text(localizeIncomeCategory(l10n, source)),
                  selected: selected,
                  onSelected: (_) => _selectPreset(source),
                  selectedColor: AppColors.income,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: AppColors.surface,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            CustomFormField(
              label: l10n.incomeSourceField,
              hint: l10n.hintIncomeSource,
              controller: _controller,
              obscure: false,
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.income,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.save,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
