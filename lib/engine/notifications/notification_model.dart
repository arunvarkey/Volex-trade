enum NotificationType {
  strategy, // BUY, SELL, EXIT, FLAT
  order, // Fill, Rebject, Partial
  risk, // Limits, Drawdown
  system, // Network, Sync
  user, // Start/Stop, Settings
}

enum NotificationSeverity {
  info,
  warning,
  critical,
}

class VolexNotification {
  final String id;
  final NotificationType type;
  final NotificationSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final String userId;
  final String? routeTarget; // e.g. '/strategies/1'
  final Map<String, dynamic>? metadata;
  bool isRead;

  VolexNotification({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.userId,
    this.routeTarget,
    this.metadata,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'severity': severity.index,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'routeTarget': routeTarget,
      'metadata': metadata,
      'isRead': isRead,
    };
  }

  factory VolexNotification.fromJson(Map<String, dynamic> json) {
    return VolexNotification(
      id: json['id'],
      type: NotificationType.values[json['type']],
      severity: NotificationSeverity.values[json['severity']],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      routeTarget: json['routeTarget'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      isRead: json['isRead'] ?? false,
    );
  }
}
