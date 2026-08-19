import 'package:flutter/material.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/models/currency.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/transaction_entry_format.dart';
import 'package:imrpo/l10n/app_localizations.dart';
class CurrencyAmountField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final Color accentColor;
  final ValueChanged<Currency>? onCurrencyChanged;
  final String? initialCurrencyCode;

  const CurrencyAmountField({
    super.key,
    required this.label,
    required this.controller,
    required this.accentColor,
    this.onCurrencyChanged,
    this.initialCurrencyCode,
  });

  @override
  State<CurrencyAmountField> createState() => _CurrencyAmountFieldState();
}

class _CurrencyAmountFieldState extends State<CurrencyAmountField> {
  late Currency _selected;

  @override
  void initState() {
    super.initState();
    _selected = CurrencyConverter.byCode(
      widget.initialCurrencyCode ?? CurrencyConverter.defaultDisplayCode,
    );
    if (!CurrencyConverter.entryCurrencies
        .any((c) => c.code == _selected.code)) {
      _selected = CurrencyConverter.byCode(
        CurrencyConverter.defaultDisplayCode,
      );
    }
    widget.controller.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onAmountChanged);
    super.dispose();
  }

  void _onAmountChanged() => setState(() {});

  Currency get selectedCurrency => _selected;

  double? get enteredAmount => double.tryParse(widget.controller.text.trim());

  /// Amount converted to app base (USD) for storage.
  double? get amountInBase {
    final amount = enteredAmount;
    if (amount == null) return null;
    return CurrencyConverter.toBase(amount, _selected.code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final singleCurrency = CurrencyConverter.entryCurrencies.length == 1;
    final baseHint = formatStoredAsBaseHint(l10n, amountInBase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (singleCurrency)
              _CurrencyLabel(currency: _selected, accentColor: widget.accentColor)
            else
              _CurrencySelector(
                selected: _selected,
                accentColor: widget.accentColor,
                onChanged: (currency) {
                  setState(() => _selected = currency);
                  widget.onCurrencyChanged?.call(currency);
                },
              ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: widget.controller,
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
                    vertical: 18,
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
                    borderSide: BorderSide(color: widget.accentColor, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (baseHint.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            baseHint,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary.withValues(alpha: 0.55),
            ),
          ),
        ],
      ],
    );
  }
}

class _CurrencyLabel extends StatelessWidget {
  final Currency currency;
  final Color accentColor;

  const _CurrencyLabel({
    required this.currency,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = localizeCurrencyLabel(l10n, currency.code);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: accentColor,
        ),
      ),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final Currency selected;
  final Color accentColor;
  final ValueChanged<Currency> onChanged;

  const _CurrencySelector({
    required this.selected,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected.code,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(Icons.expand_more_rounded, color: accentColor),
          items: CurrencyConverter.entryCurrencies.map((currency) {
            return DropdownMenuItem(
              value: currency.code,
              child: Text(
                localizeCurrencyLabel(l10n, currency.code),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            );
          }).toList(),
          onChanged: (code) {
            if (code == null) return;
            onChanged(CurrencyConverter.byCode(code));
          },
        ),
      ),
    );
  }
}
