import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:imrpo/features/plans_tab/domain/entities/plan.dart';
import 'package:imrpo/features/plans_tab/domain/services/plan_savings_coach.dart';
import 'package:imrpo/features/associations/presentation/widgets/family_author_meta.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class PlanListTile extends StatelessWidget {
  final Plan plan;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onAddFromBalance;
  final bool isDeleting;

  const PlanListTile({
    super.key,
    required this.plan,
    this.onTap,
    this.onDelete,
    this.onAddFromBalance,
    this.isDeleting = false,
  });

  static const _planColor = AppColors.plans;
  static const _planAccent = AppColors.plansDark;
  static const _successColor = AppColors.success;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = plan.progress;
    final progressPercent = (progress * 100).round();
    final accent = plan.isCompleted ? _successColor : _planColor;

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
              color: plan.isCompleted
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
                            if (plan.imageUrl != null &&
                                plan.imageUrl!.trim().isNotEmpty) ...[
                              _PlanImageThumb(url: plan.imageUrl!),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizeDemoTitle(l10n, plan.title),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                  FamilyAuthorMeta(userId: plan.userId),
                                  const SizedBox(height: 8),
                                  _CategoryChip(
                                    label: localizePlanCategory(
                                      l10n,
                                      plan.category,
                                    ),
                                    isCompleted: plan.isCompleted,
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
                                    Money.format(plan.savedAmount),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                  Text(
                                    l10n.ofTargetAmount(
                                      Money.format(plan.targetAmount),
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textColor.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (plan.deadline != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 14,
                                          color: AppColors.textColor.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.dueDateLabel(
                                            _formatDate(context, plan.deadline!),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textColor
                                                .withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (!plan.isCompleted) ...[
                                    const SizedBox(height: 8),
                                    _PlanCoachTip(plan: plan),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _planColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _planColor.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                size: 18,
                                color: plan.isCompleted
                                    ? _successColor
                                    : _planColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                plan.isCompleted
                                    ? l10n.planGoalCompleted
                                    : l10n.planTapToEditGoal,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: plan.isCompleted
                                      ? _successColor
                                      : _planColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onAddFromBalance != null && !plan.isCompleted) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: onAddFromBalance,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _planAccent,
                                side: BorderSide(
                                  color: _planColor.withValues(alpha: 0.45),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 18,
                              ),
                              label: Text(
                                l10n.balanceAddToPlan,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
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

class _PlanCoachTip extends StatelessWidget {
  final Plan plan;

  const _PlanCoachTip({required this.plan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final left = PlanSavingsCoach.remaining(plan);
    final status = PlanSavingsCoach.paceStatus(plan);
    final monthly = PlanSavingsCoach.suggestedMonthly(plan);

    final Color color;
    final IconData icon;
    final String text;

    switch (status) {
      case PlanPaceStatus.completed:
        return const SizedBox.shrink();
      case PlanPaceStatus.overdue:
        color = AppColors.error;
        icon = Icons.warning_amber_rounded;
        text = l10n.planCoachOverdue(Money.format(left));
      case PlanPaceStatus.urgent:
        color = AppColors.warning;
        icon = Icons.priority_high_rounded;
        text = monthly != null
            ? l10n.planCoachMonthly(Money.format(monthly))
            : l10n.planCoachUrgent(Money.format(left));
      case PlanPaceStatus.steady:
        color = AppColors.plans;
        icon = Icons.trending_up_rounded;
        text = monthly != null
            ? l10n.planCoachMonthly(Money.format(monthly))
            : l10n.planCoachRemaining(Money.format(left));
      case PlanPaceStatus.noDeadline:
        color = AppColors.plansDark;
        icon = Icons.flag_outlined;
        text = l10n.planCoachRemaining(Money.format(left));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanImageThumb extends StatelessWidget {
  final String url;

  const _PlanImageThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => ColoredBox(
            color: AppColors.plans.withValues(alpha: 0.12),
            child: Icon(
              Icons.image_outlined,
              color: AppColors.plansDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isCompleted;

  const _CategoryChip({required this.label, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final color =
        isCompleted ? AppColors.success : PlanListTile._planAccent;

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
