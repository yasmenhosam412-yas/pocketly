import 'package:flutter/material.dart';
import 'package:imrpo/core/services/currency_converter.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/wallet_currency_store.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/theme/color_contrast.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/balance_tab/domain/balance_source_constants.dart';
import 'package:imrpo/features/balance_tab/domain/entities/wallet_source_summary.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class BalanceWalletBreakdown extends StatelessWidget {
  final List<WalletSourceSummary> summaries;
  final String? selectedSource;
  final ValueChanged<String?> onSourceSelected;
  final String Function(AppLocalizations l10n, String key) localizeKey;

  const BalanceWalletBreakdown({
    super.key,
    required this.summaries,
    required this.selectedSource,
    required this.onSourceSelected,
    required this.localizeKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (summaries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.balanceWalletTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.balanceWalletSubtitle,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textColor.withValues(alpha: 0.55),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _WalletFilterChip(
                label: l10n.balanceWalletFilterAll,
                amount: summaries.fold<double>(
                  0,
                  (sum, row) => sum + row.remaining,
                ),
                selected: selectedSource == null,
                onTap: () => onSourceSelected(null),
              ),
              const SizedBox(width: 8),
              ...summaries.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _WalletFilterChip(
                    label: localizeKey(l10n, row.source),
                    amount: row.remaining,
                    selected: selectedSource == row.source,
                    onTap: () => onSourceSelected(
                      selectedSource == row.source ? null : row.source,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...summaries.map(
          (row) => _WalletSourceCard(
            summary: row,
            isSelected: selectedSource == row.source,
            localizeKey: localizeKey,
            onTap: () => onSourceSelected(
              selectedSource == row.source ? null : row.source,
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletFilterChip extends StatelessWidget {
  final String label;
  final double amount;
  final bool selected;
  final VoidCallback onTap;

  const _WalletFilterChip({
    required this.label,
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final positive = amount >= 0;
    final color = positive ? AppColors.balance : AppColors.expense;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? ColorContrast.onColor(color)
                      : AppColors.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Money.format(amount.abs()),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? ColorContrast.onColor(color).withValues(alpha: 0.92)
                      : AppColors.inkOf(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletSourceCard extends StatelessWidget {
  final WalletSourceSummary summary;
  final bool isSelected;
  final VoidCallback onTap;
  final String Function(AppLocalizations l10n, String key) localizeKey;

  const _WalletSourceCard({
    required this.summary,
    required this.isSelected,
    required this.onTap,
    required this.localizeKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = localizeKey(l10n, summary.source);
    final remaining = summary.remaining;
    final positive = remaining >= 0;
    final accent = positive ? AppColors.balance : AppColors.expense;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.card(
            borderColor: isSelected
                ? accent
                : accent.withValues(alpha: 0.15),
          ).copyWith(
            color: isSelected ? accent.withValues(alpha: 0.08) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.filter_alt_rounded
                          : Icons.account_balance_wallet_outlined,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final store = getIt<WalletCurrencyStore>();
                      final code = store.currencyFor(summary.source);
                      final prefix = positive ? '' : '−';
                      if (code == CurrencyConverter.defaultDisplayCode) {
                        return Text(
                          '$prefix${Money.format(remaining.abs())}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$prefix${CurrencyConverter.format(
                              CurrencyConverter.fromBase(
                                remaining.abs(),
                                code,
                              ),
                              code,
                            )}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                          Text(
                            '≈ $prefix${Money.format(remaining.abs())}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              if (summary.source != BalanceSourceConstants.unassigned) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (summary.initial > 0)
                      _DetailPill(
                        label: l10n.balanceWalletInitial,
                        amount: summary.initial,
                        color: AppColors.balance,
                      ),
                    if (summary.income > 0)
                      _DetailPill(
                        label: l10n.balanceStatIncome,
                        amount: summary.income,
                        color: AppColors.income,
                        prefix: '+',
                      ),
                    if (summary.spent > 0)
                      _DetailPill(
                        label: l10n.balanceStatExpense,
                        amount: summary.spent,
                        color: AppColors.expense,
                        prefix: '−',
                      ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  l10n.balanceWalletUnassignedHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textColor.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String prefix;

  const _DetailPill({
    required this.label,
    required this.amount,
    required this.color,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $prefix${Money.format(amount)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
