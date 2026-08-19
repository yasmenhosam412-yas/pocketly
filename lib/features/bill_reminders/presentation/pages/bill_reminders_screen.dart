import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:imrpo/core/config/app_router.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/bill_reminder_notification_service.dart';
import 'package:imrpo/core/services/bill_reminder_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/money_format.dart';
import 'package:imrpo/features/bill_reminders/domain/entities/bill_reminder.dart';
import 'package:imrpo/features/bill_reminders/presentation/bloc/bill_reminders_bloc.dart';
import 'package:imrpo/features/bill_reminders/presentation/widgets/add_bill_reminder_sheet.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class BillRemindersScreen extends StatefulWidget {
  const BillRemindersScreen({super.key});

  @override
  State<BillRemindersScreen> createState() => _BillRemindersScreenState();
}

class _BillRemindersScreenState extends State<BillRemindersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BillRemindersBloc>().add(const LoadBillRemindersEvent());
  }

  Future<void> _openEditor({BillReminder? reminder}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: context.read<BillRemindersBloc>(),
        child: AddBillReminderSheet(reminder: reminder),
      ),
    );
  }

  Future<void> _confirmDelete(BillReminder reminder) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.expenseShortcutDeleteConfirmTitle),
        content: Text(reminder.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.expenseShortcutDelete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context.read<BillRemindersBloc>().add(
      DeleteBillReminderEvent(id: reminder.id),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.billRemindersDeleted)));
  }

  String _formatReminderTime(BuildContext context, BillReminder reminder) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: reminder.reminderHour, minute: reminder.reminderMinute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }


  String _leadLabel(AppLocalizations l10n, int days) {
    return switch (days) {
      0 => l10n.billRemindersRemindOnDay,
      1 => l10n.billRemindersRemind1Day,
      3 => l10n.billRemindersRemind3Days,
      7 => l10n.billRemindersRemind7Days,
      _ => l10n.billRemindersRemind1Day,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.billRemindersTitle,
          style: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alarm_rounded),
        label: Text(l10n.billRemindersAdd),
      ),
      body: BlocBuilder<BillRemindersBloc, BillRemindersState>(
        builder: (context, state) {
          if (state is BillRemindersLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is BillRemindersError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  localizeApiError(l10n, state.message),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (state is! BillRemindersLoaded) {
            return const SizedBox.shrink();
          }

          if (state.reminders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.billRemindersEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: state.reminders.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final reminder = state.reminders[index];
              final amountLabel = reminder.amount != null
                  ? Money.format(reminder.amount!)
                  : null;

              return Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openEditor(reminder: reminder),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          color: reminder.isEnabled
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminder.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${l10n.billRemindersDayOfMonthValue(reminder.dayOfMonth)} · '
                                '${_formatReminderTime(context, reminder)} · '
                                '${_leadLabel(l10n, reminder.remindDaysBefore)}'
                                '${amountLabel != null ? ' · $amountLabel' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: reminder.isEnabled,
                          activeThumbColor: AppColors.primary,
                          onChanged: (enabled) {
                            context.read<BillRemindersBloc>().add(
                              ToggleBillReminderEvent(
                                id: reminder.id,
                                enabled: enabled,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: AppColors.error,
                          onPressed: () => _confirmDelete(reminder),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Opens bill reminders and requests notification permission when enabling.
///
/// Uses [rootNavigatorKey] so navigation still works after the settings sheet
/// is popped (its [BuildContext] is deactivated).
Future<void> openBillRemindersScreen() async {
  final prefs = getIt<BillReminderPreferences>();
  if (prefs.enabled) {
    final granted = await BillReminderNotificationService.instance
        .requestPermissionIfNeeded();
    final snackContext = rootNavigatorKey.currentContext;
    if (!granted && snackContext != null && snackContext.mounted) {
      final l10n = AppLocalizations.of(snackContext)!;
      ScaffoldMessenger.of(snackContext).showSnackBar(
        SnackBar(content: Text(l10n.billRemindersPermissionDenied)),
      );
    }
  }

  final navContext = rootNavigatorKey.currentContext;
  if (navContext == null || !navContext.mounted) return;

  final bloc = getIt<BillRemindersBloc>();
  await Navigator.of(navContext).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const BillRemindersScreen()),
    ),
  );
}
