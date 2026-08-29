import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum VoicePermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

/// Runtime microphone (and iOS speech) permission for voice add.
class VoicePermission {
  VoicePermission._();

  static Future<VoicePermissionResult> request() async {
    if (kIsWeb) return VoicePermissionResult.denied;

    final mic = await _requestOne(Permission.microphone);
    if (mic != VoicePermissionResult.granted) return mic;

    if (Platform.isIOS) {
      final speech = await _requestOne(Permission.speech);
      if (speech != VoicePermissionResult.granted) return speech;
    }

    return VoicePermissionResult.granted;
  }

  static Future<VoicePermissionResult> _requestOne(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) {
      return VoicePermissionResult.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return VoicePermissionResult.permanentlyDenied;
    }
    status = await permission.request();
    if (status.isGranted || status.isLimited) {
      return VoicePermissionResult.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return VoicePermissionResult.permanentlyDenied;
    }
    return VoicePermissionResult.denied;
  }

  static Future<bool> openSettings() => openAppSettings();
}
