import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/core/widgets/app_toast.dart';
import 'package:imrpo/core/widgets/currency_amount_field.dart';
import 'package:imrpo/core/widgets/payment_method_chips_section.dart';
import 'package:imrpo/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:imrpo/features/expenses_tab/domain/expense_categories.dart';
import 'package:imrpo/features/expenses_tab/presentation/bloc/expenses_tab_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:imrpo/features/loans_tab/domain/services/wallet_split_service.dart';
import 'package:imrpo/features/loans_tab/presentation/bloc/loans_tab_bloc.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class _PersonRow {
  final TextEditingController name;
  final TextEditingController amount;

  _PersonRow()
      : name = TextEditingController(),
        amount = TextEditingController();

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

/// Log an InstaPay/wallet payment and create loans for who owes you.
class WalletSplitSheet extends StatefulWidget {
  const WalletSplitSheet({super.key});

  @override
  State<WalletSplitSheet> createState() => _WalletSplitSheetState();
}

class _WalletSplitSheetState extends State<WalletSplitSheet> {
  static const _accent = AppColors.loans;

  final _titleController = TextEditingController();
  final _totalController = TextEditingController();
  final _notesController = TextEditingController();
  final _people = <_PersonRow>[_PersonRow(), _PersonRow()];

  late String _currencyCode;
  String _paidFrom = 'InstaPay';
  String _category = 'Food';
  bool _includeMe = true;
  bool _equalSplit = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _currencyCode = getIt<CurrencyPreferences>().displayCode;
    _totalController.addListener(_onTotalsChanged);
    for (final p in _people) {
      p.amount.addListener(_onPersonAmountChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IncomesTabBloc>().add(const LoadIncomesEvent());
    });
  }

  @override
  void dispose() {
    _totalController.removeListener(_onTotalsChanged);
    for (final p in _people) {
      p.amount.removeListener(_onPersonAmountChanged);
      p.dispose();
    }
    _titleController.dispose();
    _totalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTotalsChanged() {
    if (_equalSplit) _applyEqualSplit();
    setState(() {});
  }

  void _onPersonAmountChanged() {
    if (!_equalSplit) setState(() {});
  }

  double? get _totalDisplay {
    return double.tryParse(_totalController.text.trim().replaceAll(',', ''));
  }

  double? get _totalInBase {
    final display = _totalDisplay;
    if (display == null) return null;
    return CurrencyConverter.toBase(display, _currencyCode);
  }

  int get _shareCount => _people.length + (_includeMe ? 1 : 0);

  double? get _yourShareDisplay {
    if (!_includeMe) return 0;
    final total = _totalDisplay;
    if (total == null || total <= 0 || _shareCount <= 0) return null;
    if (_equalSplit) return total / _shareCount;
    final others = _peopleAmountSum();
    if (others == null) return null;
    final yours = total - others;
    return yours < 0 ? 0 : yours;
  }

  double? _peopleAmountSum() {
    var sum = 0.0;
    for (final p in _people) {
      final v = double.tryParse(p.amount.text.trim().replaceAll(',', ''));
      if (v == null) return null;
      sum += v;
    }
    return sum;
  }

  void _applyEqualSplit() {
    final total = _totalDisplay;
    if (total == null || total <= 0 || _shareCount <= 0) return;
    final each = total / _shareCount;
    final formatted = _formatAmount(each);
    for (final p in _people) {
      if (p.amount.text != formatted) {
        p.amount.text = formatted;
      }
    }
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  void _addPerson() {
    setState(() {
      final row = _PersonRow();
      row.amount.addListener(_onPersonAmountChanged);
      _people.add(row);
      if (_equalSplit) _applyEqualSplit();
    });
  }

  void _removePerson(int index) {
    if (_people.length <= 1) return;
    setState(() {
      final row = _people.removeAt(index);
      row.amount.removeListener(_onPersonAmountChanged);
      row.dispose();
      if (_equalSplit) _applyEqualSplit();
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _toast(l10n.walletSplitTitleRequired, error: true);
      return;
    }

    final totalBase = _totalInBase;
    if (totalBase == null || totalBase <= 0) {
      _toast(l10n.errorEnterValidAmount, error: true);
      return;
    }

    final debtors = <WalletSplitPersonShare>[];
    for (final p in _people) {
      final name = p.name.text.trim();
      if (name.isEmpty) {
        _toast(l10n.walletSplitPersonRequired, error: true);
        return;
      }
      final display =
          double.tryParse(p.amount.text.trim().replaceAll(',', ''));
      if (display == null || display <= 0) {
        _toast(l10n.errorEnterValidAmount, error: true);
        return;
      }
      debtors.add(
        WalletSplitPersonShare(
          personName: name,
          amountInBase: CurrencyConverter.toBase(display, _currencyCode),
        ),
      );
    }

    final othersDisplay = _peopleAmountSum() ?? 0;
    final totalDisplay = _totalDisplay ?? 0;
    if (_includeMe) {
      if (othersDisplay > totalDisplay + 0.009) {
        _toast(l10n.walletSplitAmountsExceedTotal, error: true);
        return;
      }
    } else if ((othersDisplay - totalDisplay).abs() > 0.05) {
      _toast(l10n.walletSplitAmountsMustMatchTotal, error: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await getIt<WalletSplitService>().submit(
        title: title,
        category: _category,
        totalAmountInBase: totalBase,
        paidFrom: _paidFrom,
        date: DateTime.now(),
        debtors: debtors,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      await result.fold(
        (failure) async {
          _toast(localizeApiError(l10n, failure.error), error: true);
        },
        (ok) async {
          context.read<LoansTabBloc>().add(const LoadLoansEvent(force: true));
          context
              .read<ExpensesTabBloc>()
              .add(const LoadExpensesEvent(force: true));
          Navigator.of(context).pop(l10n.walletSplitSuccess(ok.loanCount));
        },
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String message, {bool error = false}) {
    AppToast.show(context, message, error: error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final yourShare = _yourShareDisplay;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: AbsorbPointer(
        absorbing: _submitting,
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
                l10n.walletSplitTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.walletSplitSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              CustomFormField(
                label: l10n.walletSplitWhatFor,
                hint: l10n.walletSplitWhatForHint,
                controller: _titleController,
                obscure: false,
                icon: Icons.receipt_long_outlined,
              ),
              const SizedBox(height: 16),
              CurrencyAmountField(
                label: l10n.walletSplitYouPaid,
                controller: _totalController,
                accentColor: _accent,
                initialCurrencyCode: _currencyCode,
                onCurrencyChanged: (c) {
                  setState(() => _currencyCode = c.code);
                  if (_equalSplit) _applyEqualSplit();
                },
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategories.presets.map((cat) {
                  final selected = _category == cat;
                  return ChoiceChip(
                    label: Text(localizeExpenseCategory(l10n, cat)),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = cat),
                    selectedColor: _accent.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: selected ? _accent : AppColors.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              PaymentMethodChipsSection(
                label: l10n.expensePaidFromField,
                hint: l10n.walletSplitPaidFromHint,
                selected: _paidFrom,
                onSelected: (src) => setState(() => _paidFrom = src),
                accentColor: _accent,
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.walletSplitIncludeMe,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                subtitle: Text(
                  l10n.walletSplitIncludeMeHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textColor.withValues(alpha: 0.55),
                  ),
                ),
                value: _includeMe,
                activeThumbColor: _accent,
                onChanged: (v) {
                  setState(() {
                    _includeMe = v;
                    if (_equalSplit) _applyEqualSplit();
                  });
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.walletSplitEqualShares,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                value: _equalSplit,
                activeThumbColor: _accent,
                onChanged: (v) {
                  setState(() {
                    _equalSplit = v;
                    if (v) _applyEqualSplit();
                  });
                },
              ),
              if (_includeMe && yourShare != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.walletSplitYourShare(
                      Money.format(
                        CurrencyConverter.toBase(yourShare, _currencyCode),
                      ),
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.walletSplitPeopleSection,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addPerson,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(l10n.walletSplitAddPerson),
                    style: TextButton.styleFrom(foregroundColor: _accent),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...List.generate(_people.length, (index) {
                final row = _people[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomFormField(
                          label: l10n.loanPersonLabel,
                          hint: l10n.walletSplitPersonHint,
                          controller: row.name,
                          obscure: false,
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: IgnorePointer(
                          ignoring: _equalSplit,
                          child: Opacity(
                            opacity: _equalSplit ? 0.7 : 1,
                            child: CustomFormField(
                              label: l10n.loanPrincipalLabel,
                              hint: '0',
                              controller: row.amount,
                              obscure: false,
                              icon: Icons.payments_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_people.length > 1)
                        IconButton(
                          onPressed: () => _removePerson(index),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.textColor.withValues(alpha: 0.45),
                        ),
                    ],
                  ),
                );
              }),
              CustomFormField(
                label: l10n.loanNotesOptional,
                hint: l10n.walletSplitNotesHint,
                controller: _notesController,
                obscure: false,
                icon: Icons.notes_rounded,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
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
                      : Text(
                          l10n.walletSplitSave,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
