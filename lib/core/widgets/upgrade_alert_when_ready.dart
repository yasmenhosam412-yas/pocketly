import 'dart:async';

import 'package:upgrader/upgrader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUpgradeAlertNavFixApplied = 'pocketly_upgrade_alert_play_fix_v2';

/// Mounts [UpgradeAlert] only after [navigatorKey] has a context.
///
/// Showing the dialog from [MaterialApp.builder] can run before the navigator
/// exists. A failed show used to mark the alert as already seen, so a later
/// Play Store update never appeared.
class UpgradeAlertWhenReady extends StatefulWidget {
  const UpgradeAlertWhenReady({
    super.key,
    required this.navigatorKey,
    required this.appUpgrader,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Upgrader appUpgrader;
  final Widget child;

  @override
  State<UpgradeAlertWhenReady> createState() => _UpgradeAlertWhenReadyState();
}

class _UpgradeAlertWhenReadyState extends State<UpgradeAlertWhenReady> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_prepareAndWait());
    });
  }

  Future<void> _prepareAndWait() async {
    await _clearStaleCooldownOnce();
    if (!mounted) return;
    _waitForNavigator();
  }

  Future<void> _clearStaleCooldownOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kUpgradeAlertNavFixApplied) == true) return;
      await Upgrader.clearSavedSettings();
      await prefs.setBool(_kUpgradeAlertNavFixApplied, true);
      if (kDebugMode) {
        debugPrint('upgrader: cleared stale alert cooldown');
      }
    } catch (_) {}
  }

  void _waitForNavigator([int attempt = 0]) {
    if (!mounted) return;
    if (widget.navigatorKey.currentContext != null) {
      setState(() => _ready = true);
      return;
    }
    if (attempt >= 80) {
      if (kDebugMode) {
        debugPrint('upgrader: navigator never became ready');
      }
      return;
    }
    Future<void>.delayed(
      const Duration(milliseconds: 50),
      () => _waitForNavigator(attempt + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return widget.child;
    return UpgradeAlert(
      navigatorKey: widget.navigatorKey,
      upgrader: widget.appUpgrader,
      child: widget.child,
    );
  }
}

/// Shared Pocketly [Upgrader] configuration.
Upgrader createPocketlyUpgrader({required String languageCode}) {
  return Upgrader(
    languageCode: languageCode,
    // Arabic builds are used in Egypt. The US Play listing often has no
    // version for this app, so the update dialog never appeared.
    countryCode: languageCode == 'ar' ? 'EG' : null,
    clientHeaders: const {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    },
    messages: UpgraderMessages(code: languageCode),
    debugLogging: kDebugMode,
    durationUntilAlertAgain: const Duration(days: 1),
    willDisplayUpgrade: ({
      required bool display,
      String? installedVersion,
      UpgraderVersionInfo? versionInfo,
    }) {
      if (kDebugMode) {
        debugPrint(
          'upgrader: willDisplay=$display '
          'installed=$installedVersion store=${versionInfo?.appStoreVersion}',
        );
      }
    },
  );
}
