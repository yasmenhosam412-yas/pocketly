import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/zakat_preferences.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/zakat/domain/entities/zakat_input.dart';
import 'package:imrpo/features/zakat/domain/entities/zakat_result.dart';
import 'package:imrpo/features/zakat/domain/services/zakat_calculator.dart';
import 'package:imrpo/features/zakat/domain/services/zakat_ledger_snapshot_service.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final _calculator = ZakatCalculator();
  final _ledgerSnapshot = ZakatLedgerSnapshotService();

  final _cashCtrl = TextEditingController();
  final _goldCtrl = TextEditingController();
  final _silverCtrl = TextEditingController();
  final _investmentsCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _receivablesCtrl = TextEditingController();
  final _debtsCtrl = TextEditingController();
  final _goldPriceCtrl = TextEditingController();
  final _silverPriceCtrl = TextEditingController();

  ZakatResult? _result;
  bool _fillingLedger = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _cashCtrl,
      _goldCtrl,
      _silverCtrl,
      _investmentsCtrl,
      _businessCtrl,
      _receivablesCtrl,
      _debtsCtrl,
      _goldPriceCtrl,
      _silverPriceCtrl,
    ]) {
      c.addListener(_recalculate);
    }
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final goldPrice = await ZakatPreferences.loadGoldPricePerGram();
    final silverPrice = await ZakatPreferences.loadSilverPricePerGram();
    if (!mounted) return;
    _goldPriceCtrl.text = _formatInput(goldPrice);
    _silverPriceCtrl.text = _formatInput(silverPrice);
    _recalculate();
  }

  @override
  void dispose() {
    for (final c in [
      _cashCtrl,
      _goldCtrl,
      _silverCtrl,
      _investmentsCtrl,
      _businessCtrl,
      _receivablesCtrl,
      _debtsCtrl,
      _goldPriceCtrl,
      _silverPriceCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', ''));

  String _formatInput(double value) {
    if (value == 0) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  ZakatInput _buildInput() {
    return ZakatInput(
      cash: _parse(_cashCtrl.text) ?? 0,
      goldGrams: _parse(_goldCtrl.text) ?? 0,
      silverGrams: _parse(_silverCtrl.text) ?? 0,
      investments: _parse(_investmentsCtrl.text) ?? 0,
      businessGoods: _parse(_businessCtrl.text) ?? 0,
      receivables: _parse(_receivablesCtrl.text) ?? 0,
      debts: _parse(_debtsCtrl.text) ?? 0,
      goldPricePerGram: _parse(_goldPriceCtrl.text) ?? 0,
      silverPricePerGram: _parse(_silverPriceCtrl.text) ?? 0,
    );
  }

  void _recalculate() {
    final goldPrice = _parse(_goldPriceCtrl.text);
    if (goldPrice != null && goldPrice > 0) {
      ZakatPreferences.saveGoldPricePerGram(goldPrice);
    }
    final silverPrice = _parse(_silverPriceCtrl.text);
    if (silverPrice != null && silverPrice > 0) {
      ZakatPreferences.saveSilverPricePerGram(silverPrice);
    }
    setState(() => _result = _calculator.calculate(_buildInput()));
  }

  Future<void> _fillFromLedger() async {
    setState(() => _fillingLedger = true);
    final snapshot = await _ledgerSnapshot.load();
    if (!mounted) return;
    final money = getIt<CurrencyPreferences>();
    final cashDisplay = money.displayAmount(snapshot.cash);
    final savingsDisplay = money.displayAmount(snapshot.savings);
    _cashCtrl.text = _formatInput(cashDisplay);
    if (snapshot.savings > 0) {
      final current = _parse(_investmentsCtrl.text) ?? 0;
      _investmentsCtrl.text = _formatInput(current + savingsDisplay);
    }
    setState(() => _fillingLedger = false);
    _recalculate();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.zakatFillFromLedgerDone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = _result;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          l10n.zakatTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _InfoCard(text: l10n.zakatDisclaimer),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _fillingLedger ? null : _fillFromLedger,
            icon: _fillingLedger
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.account_balance_wallet_outlined),
            label: Text(l10n.zakatFillFromLedger),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(l10n.zakatPricesSection),
          const SizedBox(height: 6),
          Text(
            l10n.zakatPricesHint,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _AmountField(
            label: l10n.zakatGoldPricePerGram,
            hint: l10n.zakatGoldPriceHint,
            controller: _goldPriceCtrl,
            suffix: l10n.zakatPricePerGramSuffix,
          ),
          _AmountField(
            label: l10n.zakatSilverPricePerGram,
            hint: l10n.zakatSilverPriceHint,
            controller: _silverPriceCtrl,
            suffix: l10n.zakatPricePerGramSuffix,
          ),
          const SizedBox(height: 20),
          _SectionTitle(l10n.zakatAssetsSection),
          const SizedBox(height: 10),
          _AmountField(
            label: l10n.zakatCash,
            hint: l10n.zakatAmountHint,
            controller: _cashCtrl,
            suffix: 'EGP',
          ),
          _WeightField(
            label: l10n.zakatGold,
            hint: l10n.zakatGoldWeightHint,
            controller: _goldCtrl,
            valueHint: _metalValueHint(
              l10n,
              (_parse(_goldCtrl.text) ?? 0) * (_parse(_goldPriceCtrl.text) ?? 0),
            ),
          ),
          _WeightField(
            label: l10n.zakatSilver,
            hint: l10n.zakatSilverWeightHint,
            controller: _silverCtrl,
            valueHint: _metalValueHint(
              l10n,
              (_parse(_silverCtrl.text) ?? 0) *
                  (_parse(_silverPriceCtrl.text) ?? 0),
            ),
          ),
          _AmountField(
            label: l10n.zakatInvestments,
            hint: l10n.zakatAmountHint,
            controller: _investmentsCtrl,
            suffix: 'EGP',
          ),
          _AmountField(
            label: l10n.zakatBusinessGoods,
            hint: l10n.zakatAmountHint,
            controller: _businessCtrl,
            suffix: 'EGP',
          ),
          _AmountField(
            label: l10n.zakatReceivables,
            hint: l10n.zakatAmountHint,
            controller: _receivablesCtrl,
            suffix: 'EGP',
          ),
          const SizedBox(height: 20),
          _SectionTitle(l10n.zakatDeductionsSection),
          const SizedBox(height: 10),
          _AmountField(
            label: l10n.zakatDebts,
            hint: l10n.zakatAmountHint,
            controller: _debtsCtrl,
            suffix: 'EGP',
          ),
          const SizedBox(height: 20),
          _SectionTitle(l10n.zakatNisabSection),
          const SizedBox(height: 6),
          Text(
            l10n.zakatNisabHint(
              ZakatResult.goldNisabGrams.toInt(),
              ZakatResult.silverNisabGrams.toInt(),
            ),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 24),
            _ResultCard(result: result, l10n: l10n),
          ],
        ],
      ),
    );
  }

  String? _metalValueHint(AppLocalizations l10n, double value) {
    if (value <= 0) return null;
    return l10n.zakatComputedValue(Money.formatEgp(value));
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;

  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String suffix;

  const _AmountField({
    required this.label,
    required this.hint,
    required this.controller,
    this.suffix = 'EGP',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.card,
              suffixText: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? valueHint;

  const _WeightField({
    required this.label,
    required this.hint,
    required this.controller,
    this.valueHint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.card,
              suffixText: 'g',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (valueHint != null) ...[
            const SizedBox(height: 6),
            Text(
              valueHint!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ZakatResult result;
  final AppLocalizations l10n;

  const _ResultCard({required this.result, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final meets = result.meetsNisab;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            Color.lerp(AppColors.primary, AppColors.secondary, 0.5)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.zakatResultTitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _ResultRow(
            label: l10n.zakatTotalAssets,
            value: Money.formatEgp(result.totalAssets),
          ),
          _ResultRow(
            label: l10n.zakatNetWealth,
            value: Money.formatEgp(result.netWealth),
          ),
          _ResultRow(
            label: l10n.zakatNisabThreshold,
            value: result.nisabThreshold > 0
                ? Money.formatEgp(result.nisabThreshold)
                : '—',
          ),
          Divider(color: Colors.white24, height: 24),
          Text(
            meets ? l10n.zakatMeetsNisab : l10n.zakatBelowNisab,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Money.formatEgp(result.zakatDue),
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            l10n.zakatDueLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.zakatRateNote,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
