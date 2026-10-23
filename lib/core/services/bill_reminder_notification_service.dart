import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imrpo/core/services/android_notification_permission.dart';
import 'package:imrpo/core/services/bill_reminder_debug_log.dart';
import 'package:imrpo/core/services/bill_reminder_preferences.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/features/bill_reminders/domain/bill_reminder_day_helper.dart';
import 'package:imrpo/features/bill_reminders/domain/entities/bill_reminder.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// [repair] — bootstrap / app resume: skip if nothing changed and alarms exist.
/// [full] — user saved a reminder: always rebuild schedules (catch-up allowed).
enum BillReminderScheduleMode { repair, full }

class BillReminderNotificationService {
  BillReminderNotificationService._();

  static final BillReminderNotificationService instance =
      BillReminderNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _rescheduleInProgress = false;

  static const _channelId = 'bill_reminders';
  static const _channelName = 'Bill reminders';
  static const _fingerprintKey = 'bill_reminders_schedule_fingerprint';

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> initialize() async {
    if (_initialized) {
      billReminderLog('initialize: already done');
      return;
    }

    billReminderLog('initialize: starting (platform=$defaultTargetPlatform)');
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      billReminderLog('initialize: plugin initialized');

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Reminders for recurring bills',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await _android?.createNotificationChannel(channel);
      billReminderLog('initialize: Android channel "$_channelId" created');

      await _requestExactAlarmsPermission();

      _initialized = true;
    } catch (e, st) {
      billReminderLogError('initialize failed', e, st);
      rethrow;
    }
  }

  Future<bool> requestPermissionIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      billReminderLog('permission: non-Android, assuming granted');
      return true;
    }

    final before = await Permission.notification.status;
    billReminderLog('permission: notification status=$before');
    final granted = await requestAndroidNotificationPermission();
    if (!before.isGranted) {
      billReminderLog(
        'permission: after request=${granted ? PermissionStatus.granted : PermissionStatus.denied}',
      );
    }

    await _requestExactAlarmsPermission();
    await _logAndroidScheduleCapabilities();
    return granted;
  }

  Future<void> _requestExactAlarmsPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final before = await _android?.canScheduleExactNotifications();
      final granted = await _android?.requestExactAlarmsPermission();
      final after = await _android?.canScheduleExactNotifications();
      billReminderLog(
        'exactAlarms: before=$before request=$granted after=$after',
      );
      if (after != true) {
        billReminderLog(
          'exactAlarms: OFF — enable "Alarms & reminders" for Pockio in system settings (MIUI/Samsung: App info → Other permissions)',
        );
      }
    } catch (e) {
      billReminderLog('exactAlarms: request failed: $e');
    }
  }

  Future<bool> _canScheduleExact() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      return await _android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _logAndroidScheduleCapabilities() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final canExact = await _canScheduleExact();
      billReminderLog('Android canScheduleExactNotifications=$canExact');
      billReminderLog(
        'tip: if notifications do not appear, disable battery restrictions for Pocketly in system settings',
      );
    } catch (e) {
      billReminderLog('Android schedule capabilities check failed: $e');
    }
  }

  NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Reminders for recurring bills',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        ticker: 'Bill reminder',
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    final exact = await _canScheduleExact();
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    billReminderLog('androidScheduleMode=$mode (exact=$exact)');
    return mode;
  }

  Future<void> rescheduleAll(
    List<BillReminder> reminders, {
    BillReminderScheduleMode mode = BillReminderScheduleMode.full,
  }) async {
    if (_rescheduleInProgress) {
      billReminderLog('rescheduleAll: SKIP — already running');
      return;
    }
    _rescheduleInProgress = true;
    try {
      await _rescheduleAllImpl(reminders, mode: mode);
    } finally {
      _rescheduleInProgress = false;
    }
  }

  Future<void> _rescheduleAllImpl(
    List<BillReminder> reminders, {
    required BillReminderScheduleMode mode,
  }) async {
    billReminderLog(
      'rescheduleAll: ${reminders.length} reminder(s), tz=${tz.local.name}',
    );

    try {
      await initialize();
    } catch (e, st) {
      billReminderLogError('rescheduleAll: init failed', e, st);
      return;
    }

    final prefs = getIt<BillReminderPreferences>();
    if (!prefs.enabled) {
      billReminderLog('rescheduleAll: SKIP — master toggle disabled');
      await cancelAll();
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_fingerprintKey);
      return;
    }

    final granted = await requestPermissionIfNeeded();
    if (!granted) {
      billReminderLog('rescheduleAll: SKIP — notification permission denied');
      return;
    }

    if (mode == BillReminderScheduleMode.repair &&
        await _shouldSkipRepairReschedule(reminders)) {
      return;
    }

    await cancelAll();
    billReminderLog('rescheduleAll: cleared previous schedules');

    final enabled = reminders.where((r) => r.isEnabled).toList();
    billReminderLog('rescheduleAll: scheduling ${enabled.length} enabled');

    final l10n = lookupAppLocalizations(getIt<LocalePreferences>().locale);
    final money = getIt<CurrencyPreferences>();

    var scheduled = 0;
    for (final reminder in enabled) {
      try {
        await _scheduleReminder(reminder, l10n, money);
        scheduled++;
      } catch (e, st) {
        billReminderLogError(
          'rescheduleAll: failed id=${reminder.id} title=${reminder.title}',
          e,
          st,
        );
      }
    }

    billReminderLog('rescheduleAll: done, scheduled=$scheduled');
    await _persistScheduleFingerprint(reminders);
    await _logPendingNotifications();
  }

  String _scheduleFingerprint(List<BillReminder> reminders) {
    final enabled = reminders.where((r) => r.isEnabled).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (enabled.isEmpty) return 'empty';
    return enabled
        .map(
          (r) =>
              '${r.id}:${r.dayOfMonth}:${r.reminderHour}:${r.reminderMinute}:'
              '${r.remindDaysBefore}',
        )
        .join('|');
  }

  Future<bool> _shouldSkipRepairReschedule(List<BillReminder> reminders) async {
    final fp = _scheduleFingerprint(reminders);
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_fingerprintKey);
    if (stored != fp) return false;

    final enabledCount = reminders.where((r) => r.isEnabled).length;
    if (enabledCount == 0) {
      billReminderLog('rescheduleAll: SKIP repair — no enabled reminders');
      return true;
    }

    try {
      final pending = await _plugin.pendingNotificationRequests();
      final billPending = pending
          .where((p) => p.id != 999001 && p.id != 999002)
          .length;
      if (billPending >= enabledCount) {
        billReminderLog(
          'rescheduleAll: SKIP repair — fingerprint unchanged, '
          '$billPending pending alarm(s)',
        );
        return true;
      }
      billReminderLog(
        'rescheduleAll: repair needed — fingerprint ok but only '
        '$billPending/$enabledCount pending',
      );
    } catch (e) {
      billReminderLog('rescheduleAll: pending check failed ($e), will repair');
    }
    return false;
  }

  Future<void> _persistScheduleFingerprint(List<BillReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fingerprintKey, _scheduleFingerprint(reminders));
  }

  Future<void> _scheduleReminder(
    BillReminder reminder,
    AppLocalizations l10n,
    CurrencyPreferences money,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    final desiredDay =
        BillReminderDayHelper.clampStoredDay(reminder.dayOfMonth);
    final hour = reminder.reminderHour.clamp(0, 23);
    final minute = reminder.reminderMinute.clamp(0, 59);
    final lead = reminder.remindDaysBefore.clamp(0, 14);

    final due = BillReminderDayHelper.nextDueDate(
      dayOfMonth: desiredDay,
      hour: hour,
      minute: minute,
      now: now,
    );
    final notifyAt = BillReminderDayHelper.nextNotifyAt(
      due: due,
      leadDays: lead,
      dayOfMonth: desiredDay,
      hour: hour,
      minute: minute,
      now: now,
    );
    var fireAt = notifyAt;
    if (!fireAt.isAfter(now) && due.isAfter(now)) {
      fireAt = now.add(const Duration(minutes: 1));
      billReminderLog(
        'schedule: catch-up — notify $notifyAt passed, due $due still ahead → $fireAt',
      );
    }

    billReminderLog(
      'schedule: id=${reminder.id} title="${reminder.title}" '
      'now=$now due=$due leadDays=$lead notifyAt=$notifyAt fireAt=$fireAt '
      '(${fireAt.difference(now).inMinutes} min from now)',
    );

    final amountLabel = reminder.amount != null
        ? money.formatBase(reminder.amount!)
        : '';
    final hasAmount = amountLabel.isNotEmpty;

    final title = l10n.billReminderNotificationTitle(reminder.title);
    final body = _notificationBody(
      l10n: l10n,
      notifyAt: fireAt,
      due: due,
      hasAmount: hasAmount,
      amountLabel: amountLabel,
    );

    final id = _notificationId(reminder.id);
    final mode = await _androidScheduleMode();
    final details = _notificationDetails();
    final payload = body.trim().isEmpty ? reminder.title : body;

    // One-shot exact alarm (reliable on MIUI). Next month is re-scheduled on app
    // resume / boot via [BillReminderGate] and [ScheduledNotificationBootReceiver].
    await _plugin.zonedSchedule(
      id,
      title,
      payload,
      fireAt,
      details,
      androidScheduleMode: mode,
    );
    billReminderLog(
      'schedule: OK one-shot id=$id fireAt=$fireAt mode=$mode',
    );
  }

  String _notificationBody({
    required AppLocalizations l10n,
    required tz.TZDateTime notifyAt,
    required tz.TZDateTime due,
    required bool hasAmount,
    required String amountLabel,
  }) {
    final daysUntil = BillReminderDayHelper.daysUntilDue(notifyAt, due);
    if (daysUntil <= 0) {
      return hasAmount
          ? l10n.billReminderNotificationDueTodayWithAmount(amountLabel)
          : l10n.billReminderNotificationDueTodayPlain;
    }
    return hasAmount
        ? l10n.billReminderNotificationDueInDaysWithAmount(daysUntil, amountLabel)
        : l10n.billReminderNotificationDueInDaysPlain(daysUntil);
  }

  /// Shows a test notification in ~15 seconds (debug only).
  Future<void> debugFireTestNotification({String title = 'Bill reminder test'}) async {
    billReminderLog('debugFireTestNotification: requested');
    await initialize();
    final granted = await requestPermissionIfNeeded();
    if (!granted) {
      billReminderLog('debugFireTestNotification: permission denied');
      return;
    }

    final id = 999001;
    final details = _notificationDetails();
    final when = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 15));
    final mode = await _androidScheduleMode();
    try {
      await _plugin.show(
        id,
        title,
        'Test NOW — notifications work',
        details,
      );
      billReminderLog('debugFireTestNotification: show() fired immediately');

      await _plugin.zonedSchedule(
        id + 1,
        title,
        'Test in 15s — scheduled for $when',
        when,
        details,
        androidScheduleMode: mode,
      );
      billReminderLog('debugFireTestNotification: scheduled id=${id + 1} at $when');
      await _logPendingNotifications();
    } catch (e, st) {
      billReminderLogError('debugFireTestNotification failed', e, st);
    }
  }

  Future<void> _logPendingNotifications() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      billReminderLog('pending notifications: ${pending.length}');
      for (final p in pending) {
        billReminderLog('  pending id=${p.id} title=${p.title} body=${p.body}');
      }
    } catch (e) {
      billReminderLog('pending notifications query failed: $e');
    }
  }

  int _notificationId(String reminderId) =>
      reminderId.hashCode.abs() % 2147483647;

  Future<void> cancelAll() async {
    billReminderLog('cancelAll');
    await _plugin.cancelAll();
  }

  Future<void> cancelReminder(String reminderId) async {
    final id = _notificationId(reminderId);
    billReminderLog('cancelReminder id=$id');
    await _plugin.cancel(id);
  }
}
