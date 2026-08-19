import 'package:flutter/material.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/balance_tab/domain/balance_source_constants.dart';
import 'package:imrpo/features/balance_tab/domain/entities/wallet_source_summary.dart';
import 'package:imrpo/l10n/app_localizations.dart';

Future<void> showWalletOverviewDialog(
  BuildContext context, {
  required List<WalletSourceSummary> summaries,
  required String periodLabel,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.52),
    builder: (context) => _WalletOverviewDialog(
      summaries: summaries,
      periodLabel: periodLabel,
    ),
  );
}

abstract final class _WalletPalette {
  const _WalletPalette._();

  static const light = _WalletTheme(
    leatherDark: Color(0xFF4A3228),
    leatherMid: Color(0xFF7A5340),
    leatherLight: Color(0xFF9E6F55),
    stitch: Color(0xFF3D281F),
    pocket: Color(0xFFFFF7EF),
    pocketInk: Color(0xFF4A3228),
    clasp: Color(0xFFD4AF37),
    claspDark: Color(0xFF9A7B28),
  );

  static const dark = _WalletTheme(
    leatherDark: Color(0xFF1A120E),
    leatherMid: Color(0xFF3D2A20),
    leatherLight: Color(0xFF5A4030),
    stitch: Color(0xFF0E0907),
    pocket: Color(0xFF2A221C),
    pocketInk: Color(0xFFF0E8E0),
    clasp: Color(0xFFD4AF37),
    claspDark: Color(0xFF9A7B28),
  );

  static _WalletTheme of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class _WalletTheme {
  const _WalletTheme({
    required this.leatherDark,
    required this.leatherMid,
    required this.leatherLight,
    required this.stitch,
    required this.pocket,
    required this.pocketInk,
    required this.clasp,
    required this.claspDark,
  });

  final Color leatherDark;
  final Color leatherMid;
  final Color leatherLight;
  final Color stitch;
  final Color pocket;
  final Color pocketInk;
  final Color clasp;
  final Color claspDark;
}

class _WalletOverviewDialog extends StatelessWidget {
  final List<WalletSourceSummary> summaries;
  final String periodLabel;

  const _WalletOverviewDialog({
    required this.summaries,
    required this.periodLabel,
  });

  List<WalletSourceSummary> get _holdings => summaries
      .where((row) => row.source != BalanceSourceConstants.unassigned)
      .toList();

  WalletSourceSummary? get _unassigned {
    for (final row in summaries) {
      if (row.source == BalanceSourceConstants.unassigned) return row;
    }
    return null;
  }

  double get _total =>
      _holdings.fold<double>(0, (sum, row) => sum + row.remaining);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallet = _WalletPalette.of(context);
    final maxBodyHeight = MediaQuery.sizeOf(context).height * 0.48;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _WalletFoldFlap(),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      wallet.leatherMid,
                      wallet.leatherDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: wallet.stitch.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 14,
                      right: 14,
                      top: 10,
                      child: Container(
                        height: 1,
                        color: wallet.stitch.withValues(alpha: 0.35),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 10,
                      child: Container(
                        height: 1,
                        color: wallet.stitch.withValues(alpha: 0.25),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: wallet.pocket,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: wallet.stitch.withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.balanceWalletDialogTitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: wallet.pocketInk,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.balanceWalletDialogPeriod(periodLabel),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: wallet.pocketInk
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (_holdings.isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    l10n.balanceWalletDialogEmpty,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: wallet.pocketInk
                                          .withValues(alpha: 0.6),
                                      height: 1.45,
                                    ),
                                  ),
                                )
                              else
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: maxBodyHeight,
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      children: [
                                        for (var i = 0;
                                            i < _holdings.length;
                                            i++)
                                          _WalletCardSlot(
                                            label: localizeIncomeCategory(
                                              l10n,
                                              _holdings[i].source,
                                            ),
                                            amount: _holdings[i].remaining,
                                            icon: _iconForSource(
                                              _holdings[i].source,
                                            ),
                                            summary: _holdings[i],
                                            tilt: i.isEven ? -0.02 : 0.02,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_unassigned != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: AppColors.expenseLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.expense
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: AppColors.expense,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n.balanceWalletUnassignedHint,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textColor
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '−${Money.format(_unassigned!.spent)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.expense,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      wallet.leatherLight
                                          .withValues(alpha: 0.35),
                                      wallet.leatherMid
                                          .withValues(alpha: 0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: wallet.leatherMid
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l10n.balanceWalletDialogTotal,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: wallet.pocketInk,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      Money.format(_total),
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: wallet.pocketInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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

class _WalletFoldFlap extends StatelessWidget {
  const _WalletFoldFlap();

  @override
  Widget build(BuildContext context) {
    final wallet = _WalletPalette.of(context);
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                wallet.leatherLight,
                wallet.leatherMid,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: wallet.stitch.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 64,
              height: 5,
              decoration: BoxDecoration(
                color: wallet.stitch.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -2,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  wallet.clasp,
                  wallet.claspDark,
                ],
                center: Alignment(-0.2, -0.3),
                radius: 0.9,
              ),
              border: Border.all(
                color: wallet.stitch.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.circle,
              size: 8,
              color: Color(0xFF6B5420),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletCardSlot extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final WalletSourceSummary summary;
  final double tilt;

  const _WalletCardSlot({
    required this.label,
    required this.amount,
    required this.icon,
    required this.summary,
    required this.tilt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final positive = amount >= 0;
    final accent = positive ? AppColors.balance : AppColors.expense;

    return Transform.rotate(
      angle: tilt,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.card,
              accent.withValues(alpha: 0.06),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColor,
                    ),
                  ),
                  if (summary.initial > 0 ||
                      summary.income > 0 ||
                      summary.spent > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      _detailLine(l10n),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textColor.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${positive ? '' : '−'}${Money.format(amount.abs())}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _detailLine(AppLocalizations l10n) {
    final parts = <String>[];
    if (summary.initial > 0) {
      parts.add('${l10n.balanceWalletInitial} ${Money.format(summary.initial)}');
    }
    if (summary.income > 0) {
      parts.add('+${Money.format(summary.income)}');
    }
    if (summary.spent > 0) {
      parts.add('−${Money.format(summary.spent)}');
    }
    return parts.join(' · ');
  }
}

IconData _iconForSource(String source) {
  final key = source.trim().toLowerCase();
  if (key == 'cash') return Icons.payments_outlined;
  if (key.contains('visa') || key.contains('card')) {
    return Icons.credit_card_rounded;
  }
  if (key.contains('bank')) return Icons.account_balance_outlined;
  if (key.contains('vodafone') || key.contains('instapay')) {
    return Icons.phone_android_rounded;
  }
  if (key == 'salary' || key == 'freelance' || key == 'business') {
    return Icons.work_outline_rounded;
  }
  return Icons.account_balance_wallet_outlined;
}
