import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:imrpo/core/config/app_router.dart';
import 'package:imrpo/core/services/android_notification_permission.dart';
import 'package:imrpo/core/services/notification_inbox_store.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/features/notifications/domain/notification_inbox_item.dart';
import 'package:imrpo/features/notifications/domain/scheduled_notification_item.dart';
import 'package:imrpo/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fcmTokenKey = 'pocketly_fcm_token_v1';
const _fcmChannelId = 'pocketly_push';
const _fcmChannelName = 'Pocketly alerts';

/// Top-level handler for FCM when the app is in the background / terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint(
      'FCM background: ${message.messageId} '
      'title=${message.notification?.title} data=${message.data}',
    );
  }
}

class FirebaseNotificationService {
  FirebaseNotificationService._();

  static final FirebaseNotificationService instance =
      FirebaseNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _token;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  StreamSubscription<String>? _onTokenSub;

  String? get token => _token;

  /// Initializes Firebase Core (idempotent) then messaging + local display.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      await _ensureLocalNotifications();
      await _requestPermission();
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _refreshToken();
      _onTokenSub = _messaging.onTokenRefresh.listen((t) {
        unawaited(_persistToken(t));
      });

      _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      _onOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        await _recordInInbox(initial);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openNotificationsHub();
        });
      }

      _initialized = true;
      if (kDebugMode) {
        debugPrint('FCM: initialized token=$_token');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('FCM: initialize failed: $e\n$st');
      }
    }
  }

  Future<void> _ensureLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _fcmChannelId,
        _fcmChannelName,
        description: 'Push notifications from Pockio',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  Future<void> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await requestAndroidNotificationPermission();
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      debugPrint('FCM: permission=${settings.authorizationStatus}');
    }
  }

  Future<void> _refreshToken() async {
    try {
      final t = await _messaging.getToken();
      if (t != null) await _persistToken(t);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM: getToken failed: $e');
    }
  }

  Future<void> _persistToken(String token) async {
    _token = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
    } catch (_) {}
    if (kDebugMode) debugPrint('FCM Token: $token');
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint(
        'FCM foreground: title=${message.notification?.title} '
        'body=${message.notification?.body} data=${message.data}',
      );
    }

    await _recordInInbox(message);
    await _showLocalNotification(message);
  }

  Future<void> _onNotificationOpened(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('FCM opened: ${message.messageId} data=${message.data}');
    }
    await _recordInInbox(message);
    _openNotificationsHub();
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    _openNotificationsHub();
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ??
        message.data['title']?.toString() ??
        'Pockio';
    final body = notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';

    if (title.isEmpty && body.isEmpty) return;

    final id = _notificationId(message);
    final payload = jsonEncode({
      'messageId': message.messageId,
      'route': message.data['route'] ?? AppRoutes.notifications,
      'data': message.data,
    });

    await _local.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _fcmChannelId,
          _fcmChannelName,
          channelDescription: 'Push notifications from Pockio',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> _recordInInbox(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Pockio';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';
    if (title.isEmpty && body.isEmpty) return;

    final sent = message.sentTime ?? DateTime.now();
    final id = message.messageId ??
        'push_${sent.millisecondsSinceEpoch}_${title.hashCode}';

    try {
      await getIt<NotificationInboxStore>().upsertDelivered(
        NotificationInboxItem(
          id: id,
          kind: ScheduledNotificationKind.push,
          scheduledAt: sent,
          title: title,
          subtitle: body,
          description: body,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('FCM: inbox upsert failed: $e');
    }
  }

  void _openNotificationsHub() {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;
    nav.pushNamed(AppRoutes.notifications);
  }

  int _notificationId(RemoteMessage message) {
    final raw = message.messageId ??
        '${message.notification?.title}${message.notification?.body}${message.sentTime}';
    return raw.hashCode & 0x7fffffff;
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    await _onTokenSub?.cancel();
    _onMessageSub = null;
    _onOpenedSub = null;
    _onTokenSub = null;
  }
}
