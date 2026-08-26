import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:imrpo/core/services/android_notification_permission.dart';
import 'package:imrpo/core/services/bill_reminder_debug_log.dart';
import 'package:imrpo/core/services/currency_preferences.dart';
import 'package:imrpo/core/services/daily_digest_preferences.dart';
import 'package:imrpo/core/services/daily_digest_summary_service.dart';
import 'package:imrpo/core/utils/daily_digest_body_formatter.dart';
import 'package:imrpo/core/services/locale_preferences.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

enum DailyDigestScheduleMode { repair, full }

class DailyDigestNotificationService {
  DailyDigestNotificationService._();

  static final DailyDigestNotificationService instance =
      DailyDigestNotificationService._();

  static const notificationId = 888001;
  static const _channelId = 'daily_digest';
  static const _channelName = 'Daily summary';
  static const _fingerprintKey = 'daily_digest_schedule_fingerprint';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final DailyDigestSummaryService _summaryService = DailyDigestSummaryService();

  bool _initialized = false;
  bool _rescheduleInProgress = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Daily recap of your spending',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );
    await _android?.createNotificationChannel(channel);
    _initialized = true;
    billReminderLog('dailyDigest: initialized');
  }

  Future<bool> requestPermissionIfNeeded() async {
    return requestAndroidNotificationPermission();
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    try {
      final exact = await _android?.canScheduleExactNotifications() ?? false;
      return exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Daily recap of your spending',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        category: AndroidNotificationCategory.status,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  Future<void> reschedule({
    DailyDigestScheduleMode mode = DailyDigestScheduleMode.full,
  }) async {
    if (_rescheduleInProgress) return;
    _rescheduleInProgress = true;
    try {
      await _rescheduleImpl(mode: mode);
    } finally {
      _rescheduleInProgress = false;
    }
  }

  Future<void> _rescheduleImpl({
    required DailyDigestScheduleMode mode,
  }) async {
    await initialize();

    final prefs = getIt<DailyDigestPreferences>();
    if (!prefs.enabled) {
      billReminderLog('dailyDigest: SKIP — disabled');
      await cancel();
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_fingerprintKey);
      return;
    }

    final granted = await requestPermissionIfNeeded();
    if (!granted) {
      billReminderLog('dailyDigest: SKIP — permission denied');
      return;
    }

    final fireAt = _nextFireAt(prefs.hour, prefs.minute);
    final summary =
        await _summaryService.buildForNotificationFireAt(fireAt.toLocal());

    if (mode == DailyDigestScheduleMode.repair &&
        await _shouldSkipRepair(fireAt, prefs, summary)) {
      return;
    }

    await cancel();

    final l10n = lookupAppLocalizations(getIt<LocalePreferences>().locale);
    final money = getIt<CurrencyPreferences>();
    final title = l10n.dailyDigestNotificationTitle;
    final body = formatDailyDigestNotificationBody(l10n, money, summary);

    final modeAndroid = await _androidScheduleMode();
    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      fireAt,
      _notificationDetails(),
      androidScheduleMode: modeAndroid,
      payload: 'daily_digest',
    );

    billReminderLog(
      'dailyDigest: scheduled fireAt=$fireAt body="$body"',
    );
    await _persistFingerprint(fireAt, prefs, summary);
  }

  tz.TZDateTime _nextFireAt(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var fireAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour.clamp(0, 23),
      minute.clamp(0, 59),
    );
    if (!fireAt.isAfter(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }
    return fireAt;
  }

  String _fingerprint(
    tz.TZDateTime fireAt,
    DailyDigestPreferences prefs,
    DailyDigestSummary? summary,
  ) {
    final s = summary;
    return '${prefs.enabled}:${prefs.hour}:${prefs.minute}:'
        '${fireAt.year}${fireAt.month}${fireAt.day}:'
        '${s?.expenseCount ?? 0}:${s?.incomeCount ?? 0}:'
        '${s?.expenseTotal ?? 0}:${s?.incomeTotal ?? 0}:${s?.monthNet ?? 0}';
  }

  Future<bool> _shouldSkipRepair(
    tz.TZDateTime fireAt,
    DailyDigestPreferences prefs,
    DailyDigestSummary? summary,
  ) async {
    final fp = _fingerprint(fireAt, prefs, summary);
    final sp = await SharedPreferences.getInstance();
    if (sp.getString(_fingerprintKey) != fp) return false;

    try {
      final pending = await _plugin.pendingNotificationRequests();
      final hasDigest = pending.any((p) => p.id == notificationId);
      if (hasDigest) {
        billReminderLog('dailyDigest: SKIP repair — fingerprint unchanged');
        return true;
      }
    } catch (e) {
      billReminderLog('dailyDigest: pending check failed ($e)');
    }
    return false;
  }

  Future<void> _persistFingerprint(
    tz.TZDateTime fireAt,
    DailyDigestPreferences prefs,
    DailyDigestSummary? summary,
  ) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_fingerprintKey, _fingerprint(fireAt, prefs, summary));
  }

  Future<void> cancel() async {
    await _plugin.cancel(notificationId);
  }
}
