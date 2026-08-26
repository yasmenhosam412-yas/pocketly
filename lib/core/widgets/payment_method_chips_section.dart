import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Chips for income source / expense paid-from with quick "+ Add method".
class PaymentMethodChipsSection extends StatefulWidget {
  final String label;
  final String? hint;
  final String selected;
  final ValueChanged<String> onSelected;
  final Color accentColor;
  final bool enabled;
  final bool allowNone;
  final VoidCallback? onClearSelection;

  PaymentMethodChipsSection({
    super.key,
    required this.label,
    this.hint,
    required this.selected,
    required this.onSelected,
    Color? accentColor,
    this.enabled = true,
    this.allowNone = false,
    this.onClearSelection,
  }) : accentColor = accentColor ?? AppColors.primary;

  @override
  State<PaymentMethodChipsSection> createState() =>
      _PaymentMethodChipsSectionState();
}

class _PaymentMethodChipsSectionState extends State<PaymentMethodChipsSection> {
  final _newMethodController = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _newMethodController.dispose();
    super.dispose();
  }

  Future<void> _saveNewMethod() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _newMethodController.text.trim();
    if (name.isEmpty) {
      _showSnack(l10n.paymentMethodNameEmpty, isError: true);
      return;
    }
    await getIt<PaymentMethodsStore>().add(name);
    if (!mounted) return;
    setState(() {
      _adding = false;
      _newMethodController.clear();
    });
    widget.onSelected(name);
    _showSnack(l10n.paymentMethodAdded(name));
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorColor : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final methodsStore = getIt<PaymentMethodsStore>();

    return ListenableBuilder(
      listenable: methodsStore,
      builder: (context, _) {
        return BlocBuilder<IncomesTabBloc, IncomesTabState>(
          buildWhen: (prev, curr) => prev.incomes != curr.incomes,
          builder: (context, incomeState) {
            final fromIncomes = incomeState.incomes
                .map((i) => i.category.trim())
                .where((c) => c.isNotEmpty);
            final options = methodsStore.optionsFor(
              fromIncomes: fromIncomes,
              selected: widget.selected,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                if (widget.hint != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.hint!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textColor.withValues(alpha: 0.55),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.allowNone)
                      ChoiceChip(
                        label: Text(l10n.expensePaidFromNone),
                        selected: widget.selected.isEmpty,
                        onSelected: widget.enabled
                            ? (_) => widget.onClearSelection?.call()
                            : null,
                        selectedColor: widget.accentColor,
                        labelStyle: TextStyle(
                          color: widget.selected.isEmpty
                              ? Colors.white
                              : AppColors.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                        backgroundColor: AppColors.surface,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ...options.map((src) {
                      final isSelected = widget.selected == src;
                      return ChoiceChip(
                        label: Text(localizeIncomeCategory(l10n, src)),
                        selected: isSelected,
                        onSelected: widget.enabled
                            ? (_) => widget.onSelected(src)
                            : null,
                        selectedColor: widget.accentColor,
                        labelStyle: TextStyle(
                          color:
                              isSelected ? Colors.white : AppColors.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: AppColors.surface,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }),
                    ActionChip(
                      avatar: Icon(
                        _adding ? Icons.close_rounded : Icons.add_rounded,
                        size: 18,
                        color: widget.accentColor,
                      ),
                      label: Text(
                        _adding
                            ? l10n.paymentMethodAddCancel
                            : l10n.paymentMethodAddChip,
                      ),
                      onPressed: widget.enabled
                          ? () => setState(() {
                                _adding = !_adding;
                                if (!_adding) _newMethodController.clear();
                              })
                          : null,
                      backgroundColor:
                          widget.accentColor.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: widget.accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: widget.accentColor.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
                if (_adding) ...[
                  const SizedBox(height: 12),
                  CustomFormField(
                    label: l10n.paymentMethodNewLabel,
                    hint: l10n.paymentMethodNewHint,
                    controller: _newMethodController,
                    obscure: false,
                    icon: Icons.account_balance_wallet_outlined,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.enabled ? _saveNewMethod : null,
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text(l10n.paymentMethodSave),
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
