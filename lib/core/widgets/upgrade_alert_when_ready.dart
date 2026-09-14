import 'dart:async';

import 'package:app_upgrader_flutter/app_upgrader_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUpgradeAlertNavFixApplied = 'pocketly_upgrade_alert_nav_fix_v1';

/// Mounts [AppUpgradeAlert] only after [navigatorKey] has a context.
///
/// [AppUpgradeAlert] in [MaterialApp.builder] can evaluate before the navigator
/// exists. The package then sets `_displayed` / last-alerted prefs even when
/// [showDialog] fails, so the prompt never appears again for days.
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
        debugPrint('AppUpgrader: cleared stale alert cooldown (nav fix)');
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
        debugPrint('AppUpgrader: navigator never became ready');
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
    return AppUpgradeAlert(
      navigatorKey: widget.navigatorKey,
      appUpgrader: widget.appUpgrader,
      child: widget.child,
    );
  }
}

/// Shared Pocketly [Upgrader] configuration.
Upgrader createPocketlyUpgrader({required String languageCode}) {
  return Upgrader(
    languageCode: languageCode,
    messages: UpgraderMessages(code: languageCode),
    debugLogging: kDebugMode,
    durationUntilAlertAgain: const Duration(days: 1),
    willDisplayUpgrade: ({
      required bool display,
      String? minAppVersion,
      String? releaseNote,
      String? installedVersion,
      String? appStoreVersion,
    }) {
      if (kDebugMode) {
        debugPrint(
          'AppUpgrader: willDisplay=$display '
          'installed=$installedVersion store=$appStoreVersion '
          'min=$minAppVersion',
        );
      }
    },
  );
}
