import 'package:equatable/equatable.dart';

enum ScheduledNotificationKind { billReminder, dailyDigest, push }

class ScheduledNotificationItem extends Equatable {
  final ScheduledNotificationKind kind;
  final DateTime scheduledAt;
  final String title;
  final String subtitle;
  final String description;
  final String? reminderId;

  const ScheduledNotificationItem({
    required this.kind,
    required this.scheduledAt,
    required this.title,
    required this.subtitle,
    required this.description,
    this.reminderId,
  });

  @override
  List<Object?> get props =>
      [kind, scheduledAt, title, subtitle, description, reminderId];
}
