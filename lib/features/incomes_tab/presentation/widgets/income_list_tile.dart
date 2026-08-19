import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/features/incomes_tab/presentation/bloc/incomes_tab_bloc.dart';
import 'package:intl/intl.dart';
import 'package:imrpo/core/theme/app_decorations.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:imrpo/features/incomes_tab/domain/entities/income.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/models/transaction_entry_meta.dart';
import 'package:imrpo/core/utils/transaction_entry_format.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class IncomeListTile extends StatelessWidget {
  final Income income;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const IncomeListTile({
    super.key,
    required this.income,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final source = localizeIncomeCategory(l10n, income.category);
    final title = localizeDemoTitle(l10n, income.title);
    final showTitleSubtitle =
        title.trim().toLowerCase() != source.trim().toLowerCase();
    final metaStyle = TextStyle(
      fontSize: 12.5,
      height: 1.25,
      fontWeight: FontWeight.w500,
      color: AppColors.textColor.withValues(alpha: 0.55),
    );
    final iconMetaColor = AppColors.textColor.withValues(alpha: 0.45);
    final foreignSubtitle = formatForeignEntrySubtitle(
      l10n,
      TransactionEntryMeta(
        entryCurrency: income.entryCurrency,
        entryAmount: income.entryAmount,
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: AppDecorations.card(
            borderColor: AppColors.income.withValues(alpha: 0.15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.incomeLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: AppColors.income,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                        height: 1.2,
                      ),
                    ),
                    if (showTitleSubtitle) ...[
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: AppColors.textColor.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                    if (foreignSubtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(foreignSubtitle, style: metaStyle),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: iconMetaColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatDate(context, income.date),
                            style: metaStyle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '+${Money.format(income.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.income,
                    height: 1.2,
                  ),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                BlocBuilder<IncomesTabBloc, IncomesTabState>(
                  buildWhen: (previous, current) =>
                      previous.deletingIncomeId != current.deletingIncomeId ||
                      previous.status != current.status,
                  builder: (context, state) {
                    final isDeleting =
                        state.status == IncomesTabStatus.loadingDelete &&
                        state.deletingIncomeId == income.id;

                    return IconButton(
                      onPressed: isDeleting ? null : onDelete,
                      icon: Skeletonizer(
                        enabled: isDeleting,
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
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
                    );
                  },
                ),
              ],
            ],
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
