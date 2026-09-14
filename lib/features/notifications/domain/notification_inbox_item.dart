import 'package:equatable/equatable.dart';
import 'package:imrpo/features/notifications/domain/scheduled_notification_item.dart';

class NotificationInboxItem extends Equatable {
  final String id;
  final ScheduledNotificationKind kind;
  final DateTime scheduledAt;
  final String title;
  final String subtitle;
  final String description;
  final DateTime? readAt;

  const NotificationInboxItem({
    required this.id,
    required this.kind,
    required this.scheduledAt,
    required this.title,
    required this.subtitle,
    required this.description,
    this.readAt,
  });

  bool get isUnread => readAt == null;

  factory NotificationInboxItem.fromScheduled(ScheduledNotificationItem item) {
    return NotificationInboxItem(
      id: item.inboxId,
      kind: item.kind,
      scheduledAt: item.scheduledAt,
      title: item.title,
      subtitle: item.subtitle,
      description: item.description,
    );
  }

  NotificationInboxItem markRead() => NotificationInboxItem(
        id: id,
        kind: kind,
        scheduledAt: scheduledAt,
        title: title,
        subtitle: subtitle,
        description: description,
        readAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'scheduledAt': scheduledAt.toIso8601String(),
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'readAt': readAt?.toIso8601String(),
      };

  factory NotificationInboxItem.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? 'push';
    final kind = ScheduledNotificationKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => ScheduledNotificationKind.push,
    );
    return NotificationInboxItem(
      id: json['id'] as String,
      kind: kind,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, kind, scheduledAt, title, subtitle, description, readAt];
}

extension ScheduledNotificationInboxId on ScheduledNotificationItem {
  String get inboxId => switch (kind) {
        ScheduledNotificationKind.billReminder =>
          'bill_${reminderId ?? 'x'}_${scheduledAt.millisecondsSinceEpoch}',
        ScheduledNotificationKind.dailyDigest =>
          'digest_${scheduledAt.year}-${scheduledAt.month}-${scheduledAt.day}',
        ScheduledNotificationKind.push =>
          'push_${scheduledAt.millisecondsSinceEpoch}',
      };
}
