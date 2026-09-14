import 'package:flutter/material.dart';
import 'package:imrpo/core/config/app_router.dart';
import 'package:imrpo/core/services/bill_reminder_debug_log.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/bill_reminder_notification_service.dart';
import 'package:imrpo/core/services/bill_reminder_preferences.dart';
import 'package:imrpo/core/services/daily_digest_notification_service.dart';
import 'package:imrpo/core/services/daily_digest_preferences.dart';
import 'package:imrpo/core/services/notification_inbox_store.dart';
import 'package:imrpo/core/services/notification_inbox_sync_service.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/features/notifications/domain/notification_inbox_item.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/bill_reminders/domain/repositories/bill_reminder_repository.dart';
import 'package:imrpo/features/notifications/domain/notifications_hub_service.dart';
import 'package:imrpo/features/notifications/domain/scheduled_notification_item.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _hub = NotificationsHubService();
  List<ScheduledNotificationItem> _upcoming = [];
  bool _loading = true;
  bool? _permissionGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload(markRead: true));
  }

  Future<void> _reload({bool markRead = false}) async {
    if (!mounted) return;
    setState(() => _loading = true);
    await getIt<NotificationInboxSyncService>().syncDelivered();
    if (markRead) {
      await getIt<NotificationInboxStore>().markAllRead();
    }
    final granted = await BillReminderNotificationService.instance
        .requestPermissionIfNeeded();
    final l10n = lookupAppLocalizations(getIt<LocalePreferences>().locale);
    final upcoming = await _hub.loadUpcoming(l10n);
    if (!mounted) return;
    setState(() {
      _permissionGranted = granted;
      _upcoming = upcoming;
      _loading = false;
    });
  }

  Future<void> _onBillRemindersToggle(bool enabled) async {
    final prefs = getIt<BillReminderPreferences>();
    await prefs.setEnabled(enabled);
    if (enabled) {
      await BillReminderNotificationService.instance
          .requestPermissionIfNeeded();
    }
    final result = await getIt<BillReminderRepository>().getAll();
    await result.fold(
      (f) async => billReminderLog('notifications: bills load ${f.error}'),
      (list) async {
        if (enabled) {
          await BillReminderNotificationService.instance.rescheduleAll(list);
        } else {
          await BillReminderNotificationService.instance.cancelAll();
        }
      },
    );
    await _reload();
  }

  Future<void> _onDailyDigestToggle(bool enabled) async {
    await getIt<DailyDigestPreferences>().setEnabled(enabled);
    if (enabled) {
      await DailyDigestNotificationService.instance
          .requestPermissionIfNeeded();
    }
    await DailyDigestNotificationService.instance.reschedule();
    await _reload();
  }

  Future<void> _pickDailyDigestTime(DailyDigestPreferences digestPrefs) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: digestPrefs.hour, minute: digestPrefs.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryInk,
              onPrimary: AppColors.onPrimaryInk,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    await digestPrefs.setTime(hour: picked.hour, minute: picked.minute);
    await DailyDigestNotificationService.instance.reschedule();
    await _reload();
  }

  String _formatDigestTime(BuildContext context, int hour, int minute) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: hour, minute: minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: getIt<NotificationInboxStore>(),
      builder: (context, _) {
        final inbox = getIt<NotificationInboxStore>().items;

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
          l10n.notificationsTitle,
          style: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryInk,
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (_permissionGranted == false)
              _PermissionBanner(
                message: l10n.notificationsPermissionBanner,
                actionLabel: l10n.notificationsOpenSettings,
                onOpenSettings: openAppSettings,
              ),
            Text(
              l10n.notificationsSubtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: getIt<BillReminderPreferences>(),
              builder: (context, _) {
                final billPrefs = getIt<BillReminderPreferences>();
                return _NotificationTypeCard(
                  icon: Icons.event_repeat_rounded,
                  title: l10n.billRemindersTitle,
                  subtitle: l10n.billRemindersSubtitle,
                  enabled: billPrefs.enabled,
                  onToggle: _onBillRemindersToggle,
                  trailing: billPrefs.enabled
                      ? TextButton(
                          onPressed: () async {
                            await Navigator.of(context).pushNamed(
                              AppRoutes.billReminders,
                            );
                            if (mounted) await _reload();
                          },
                          child: Text(l10n.notificationsManageBills),
                        )
                      : null,
                );
              },
            ),
            const SizedBox(height: 10),
            ListenableBuilder(
              listenable: getIt<DailyDigestPreferences>(),
              builder: (context, _) {
                final digestPrefs = getIt<DailyDigestPreferences>();
                return _NotificationTypeCard(
                  icon: Icons.insights_outlined,
                  title: l10n.dailyDigestEnabled,
                  subtitle: l10n.dailyDigestSubtitle,
                  enabled: digestPrefs.enabled,
                  onToggle: _onDailyDigestToggle,
                  trailing: digestPrefs.enabled
                      ? TextButton(
                          onPressed: () => _pickDailyDigestTime(digestPrefs),
                          child: Text(
                            '${l10n.dailyDigestTimeLabel}: '
                            '${_formatDigestTime(context, digestPrefs.hour, digestPrefs.minute)}',
                          ),
                        )
                      : null,
                );
              },
            ),
            if (inbox.isNotEmpty) ...[
              Text(
                l10n.notificationsInbox,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...inbox.take(12).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InboxTile(item: item),
                    ),
                  ),
              const SizedBox(height: 24),
            ],
            Text(
              l10n.notificationsUpcoming,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryInk),
                ),
              )
            else if (_upcoming.isEmpty)
              _EmptyUpcoming(message: l10n.notificationsUpcomingEmpty)
            else
              ..._upcoming.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _UpcomingTile(item: item),
                  )),
          ],
        ),
      ),
        );
      },
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onOpenSettings;

  const _PermissionBanner({
    required this.message,
    required this.actionLabel,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.errorColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_off_outlined,
                color: AppColors.errorColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onOpenSettings,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final Widget? trailing;

  const _NotificationTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryInk),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: enabled,
                  activeThumbColor: AppColors.primaryInk,
                  onChanged: onToggle,
                ),
              ],
            ),
            if (trailing != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  final NotificationInboxItem item;

  const _InboxTile({required this.item});

  IconData get _icon => switch (item.kind) {
        ScheduledNotificationKind.billReminder =>
          Icons.notifications_active_outlined,
        ScheduledNotificationKind.dailyDigest => Icons.insights_outlined,
        ScheduledNotificationKind.push => Icons.campaign_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: item.isUnread ? AppColors.primaryInk.withValues(alpha: 0.06) : AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, color: AppColors.primaryInk, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: item.isUnread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (item.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primaryInk,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.notificationsMessageLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final ScheduledNotificationItem item;

  const _UpcomingTile({required this.item});

  IconData get _icon => switch (item.kind) {
        ScheduledNotificationKind.billReminder =>
          Icons.notifications_active_outlined,
        ScheduledNotificationKind.dailyDigest => Icons.insights_outlined,
        ScheduledNotificationKind.push => Icons.campaign_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, color: AppColors.primaryInk, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!
                          .notificationsMessageLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyUpcoming extends StatelessWidget {
  final String message;

  const _EmptyUpcoming({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Opens the notifications hub from anywhere (e.g. home header).
Future<void> openNotificationsScreen() async {
  final navContext = rootNavigatorKey.currentContext;
  if (navContext == null || !navContext.mounted) return;

  await Navigator.of(navContext).pushNamed(AppRoutes.notifications);
}
