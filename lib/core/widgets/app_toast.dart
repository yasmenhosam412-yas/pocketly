import 'dart:async';

import 'package:flutter/material.dart';
import 'package:imrpo/core/utils/app_colors.dart';

/// Floating feedback drawn on the root overlay so it stays above modal sheets.
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    bool error = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    hide();

    final entry = OverlayEntry(
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return Positioned(
          left: 16,
          right: 16,
          bottom: 24 + media.viewInsets.bottom + media.viewPadding.bottom,
          child: IgnorePointer(
            child: Material(
              color: error ? AppColors.error : AppColors.success,
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, hide);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    if (entry == null) return;
    if (entry.mounted) entry.remove();
  }

  static void error(BuildContext context, String message) =>
      show(context, message, error: true);

  static void success(BuildContext context, String message) =>
      show(context, message, error: false);
}
