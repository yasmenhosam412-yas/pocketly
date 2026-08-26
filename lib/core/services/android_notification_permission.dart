import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool>? _notificationRequest;

/// Serializes Android notification permission prompts (only one can run at a time).
Future<bool> requestAndroidNotificationPermission() {
  if (defaultTargetPlatform != TargetPlatform.android) {
    return Future<bool>.value(true);
  }
  return _notificationRequest ??= _request().whenComplete(() {
    _notificationRequest = null;
  });
}

Future<bool> _request() async {
  var status = await Permission.notification.status;
  if (!status.isGranted) {
    status = await Permission.notification.request();
  }
  return status.isGranted;
}
