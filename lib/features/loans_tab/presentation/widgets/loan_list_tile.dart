import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:imrpo/features/loans_tab/domain/entities/loan.dart';
import 'package:imrpo/features/associations/presentation/widgets/family_author_meta.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class LoanListTile extends StatelessWidget {
  final Loan loan;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRecordPayment;
  final bool isDeleting;

  const LoanListTile({
    super.key,
    required this.loan,
    this.onTap,
    this.onDelete,
    this.onRecordPayment,
    this.isDeleting = false,
  });

  static const _loanColor = AppColors.loans;
  static const _loanAccent = AppColors.loansDark;
  static const _successColor = AppColors.success;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = loan.progress;
    final progressPercent = (progress * 100).round();
    final accent = loan.isSettled
        ? _successColor
        : loan.isOverdue
        ? AppColors.error
        : _loanColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: loan.isOverdue
                  ? AppColors.error.withValues(alpha: 0.35)
                  : loan.isSettled
                  ? _successColor.withValues(alpha: 0.35)
                  : AppColors.stroke.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.stroke.withValues(alpha: 0.08),
                blurRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loan.personName,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                  FamilyAuthorMeta(userId: loan.userId),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _Badge(
                                        label: loan.isGiven
                                            ? l10n.loanDirectionGiven
                                            : l10n.loanDirectionReceived,
                                        color: loan.isGiven
                                            ? AppColors.income
                                            : AppColors.expense,
                                      ),
                                      if (loan.isSettled)
                                        _Badge(
                                          label: l10n.loanSettledBadge,
                                          color: _successColor,
                                        )
                                      else if (loan.isOverdue)
                                        _Badge(
                                          label: l10n.loanOverdueBadge,
                                          color: AppColors.error,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (onDelete != null)
                              IconButton(
                                onPressed: isDeleting ? null : onDelete,
                                icon: Skeletonizer(
                                  enabled: isDeleting,
                                  child: Icon(
                                    Icons.delete,
                                    color: AppColors.textColor.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              height: 52,
                              width: 52,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 5,
                                    backgroundColor: accent.withValues(
                                      alpha: 0.12,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      accent,
                                    ),
                                  ),
                                  Text(
                                    '$progressPercent%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Money.format(loan.remaining),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                  Text(
                                    l10n.loanOfPrincipal(
                                      Money.format(loan.principal),
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textColor.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (loan.dueDate != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 14,
                                          color: loan.isOverdue
                                              ? AppColors.error
                                              : AppColors.textColor.withValues(
                                                  alpha: 0.4,
                                                ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.dueDateLabel(
                                            _formatDate(
                                              context,
                                              loan.dueDate!,
                                            ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: loan.isOverdue
                                                ? AppColors.error
                                                : AppColors.textColor
                                                    .withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (loan.notes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            loan.notes,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (onRecordPayment != null && !loan.isSettled)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: onRecordPayment,
                              icon: const Icon(Icons.payments_outlined, size: 18),
                              label: Text(l10n.loanRecordPayment),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _loanAccent,
                                side: BorderSide(
                                  color: _loanColor.withValues(alpha: 0.35),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _loanColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _loanColor.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  loan.isSettled
                                      ? Icons.check_circle_outline
                                      : Icons.edit_note_rounded,
                                  size: 18,
                                  color: loan.isSettled
                                      ? _successColor
                                      : _loanColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  loan.isSettled
                                      ? l10n.loanSettledBadge
                                      : l10n.loanTapToEdit,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: loan.isSettled
                                        ? _successColor
                                        : _loanColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.MMMd(locale).format(date);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
