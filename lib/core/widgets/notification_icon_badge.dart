import 'package:flutter/material.dart';

/// Small count badge for notification icons (e.g. home header bell).
class NotificationIconBadge extends StatelessWidget {
  final int count;

  const NotificationIconBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final label = count > 99 ? '99+' : '$count';

    return Positioned(
      right: -2,
      top: -2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
