import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Requires three back presses (within [resetAfter]) to leave the app.
class TripleBackToExit extends StatefulWidget {
  final Widget child;

  /// Used when this screen has its own back action (e.g. signup).
  final VoidCallback? onAlternateBack;

  const TripleBackToExit({
    super.key,
    required this.child,
    this.onAlternateBack,
  });

  @override
  State<TripleBackToExit> createState() => _TripleBackToExitState();
}

class _TripleBackToExitState extends State<TripleBackToExit> {
  static const _requiredPresses = 3;
  static const _resetAfter = Duration(seconds: 2);

  int _presses = 0;
  DateTime? _lastPress;

  void _handlePop(bool didPop, Object? result) {
    if (didPop) return;

    if (widget.onAlternateBack != null) {
      widget.onAlternateBack!();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    final now = DateTime.now();
    if (_lastPress == null || now.difference(_lastPress!) > _resetAfter) {
      _presses = 0;
    }
    _lastPress = now;
    _presses++;

    if (_presses >= _requiredPresses) {
      SystemNavigator.pop();
      return;
    }

    final remaining = _requiredPresses - _presses;
    final l10n = AppLocalizations.of(context)!;
    final message = remaining == 1
        ? l10n.exitPressOnceMore
        : l10n.exitPressTwiceMore;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: _resetAfter,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: widget.child,
    );
  }
}
