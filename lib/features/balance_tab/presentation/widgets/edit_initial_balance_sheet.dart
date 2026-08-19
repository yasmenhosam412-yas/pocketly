import 'package:flutter/material.dart';
import 'package:imrpo/core/models/initial_balance_entry.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/initial_balance_store.dart';
import 'package:imrpo/core/services/payment_methods_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/widgets/payment_method_chips_section.dart';
import 'package:imrpo/l10n/app_localizations.dart';

Future<bool?> showEditInitialBalanceSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
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
      child: const EditInitialBalanceSheet(),
    ),
  );
}

class _DraftEntry {
  String source;
  final TextEditingController amountController;

  _DraftEntry({required this.source, required String amountText})
      : amountController = TextEditingController(text: amountText);

  void dispose() => amountController.dispose();
}

class EditInitialBalanceSheet extends StatefulWidget {
  const EditInitialBalanceSheet({super.key});

  @override
  State<EditInitialBalanceSheet> createState() =>
      _EditInitialBalanceSheetState();
}

class _EditInitialBalanceSheetState extends State<EditInitialBalanceSheet> {
  final List<_DraftEntry> _drafts = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final store = getIt<InitialBalanceStore>();
    if (store.entries.isEmpty) {
      _drafts.add(
        _DraftEntry(
          source: PaymentMethodsStore.defaultPresets.first,
          amountText: '',
        ),
      );
    } else {
      for (final entry in store.entries) {
        final display = CurrencyConverter.fromBase(
          entry.amount,
          CurrencyConverter.defaultDisplayCode,
        );
        final text = display == display.roundToDouble()
            ? display.toInt().toString()
            : display.toStringAsFixed(2);
        _drafts.add(_DraftEntry(source: entry.source, amountText: text));
      }
    }
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      final used = _drafts.map((d) => d.source.toLowerCase()).toSet();
      final next = PaymentMethodsStore.defaultPresets.firstWhere(
        (preset) => !used.contains(preset.toLowerCase()),
        orElse: () => PaymentMethodsStore.defaultPresets.first,
      );
      _drafts.add(_DraftEntry(source: next, amountText: ''));
    });
  }

  void _removeRow(int index) {
    if (_drafts.length <= 1) return;
    setState(() {
      _drafts.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final parsed = <InitialBalanceEntry>[];

    for (final draft in _drafts) {
      final source = draft.source.trim();
      final text = draft.amountController.text.trim();
      if (text.isEmpty) continue;
      final amount = double.tryParse(text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorEnterValidAmount),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (source.isEmpty) continue;
      parsed.add(
        InitialBalanceEntry(
          source: source,
          amount: CurrencyConverter.toBase(
            amount,
            CurrencyConverter.defaultDisplayCode,
          ),
        ),
      );
    }

    setState(() => _saving = true);
    await getIt<InitialBalanceStore>().setEntries(parsed);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 20 + bottomInset),
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
              l10n.balanceInitialBalanceTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.balanceInitialBalanceHint,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColor.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < _drafts.length; i++)
                      _InitialBalanceDraftCard(
                        key: ValueKey('draft_$i'),
                        draft: _drafts[i],
                        canRemove: _drafts.length > 1,
                        onRemove: () => _removeRow(i),
                        onSourceChanged: (source) {
                          setState(() => _drafts[i].source = source);
                        },
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.balanceInitialBalanceAddSource),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.balance,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.balance,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.save,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialBalanceDraftCard extends StatelessWidget {
  final _DraftEntry draft;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<String> onSourceChanged;

  const _InitialBalanceDraftCard({
    super.key,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
    required this.onSourceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.balanceInitialBalanceBySource,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColor,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textColor.withValues(alpha: 0.45),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          PaymentMethodChipsSection(
            label: l10n.incomeSourceField,
            selected: draft.source,
            onSelected: onSourceChanged,
            accentColor: AppColors.balance,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.amountField,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: draft.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.balance,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
