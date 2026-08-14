import 'package:flutter/material.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_spacing.dart';
import 'package:volex_terminal/engine/notifications/notification_bus.dart';
import 'package:volex_terminal/engine/notifications/notification_model.dart';
import 'package:volex_terminal/core/service_locator.dart';
import 'package:volex_terminal/core/services/auth/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationBus = getIt<NotificationBus>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: VxColors.surface,
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: StreamBuilder<List<VolexNotification>>(
        // Using historyStream which emits List<VolexNotification>
        stream: _notificationBus.historyStream,
        initialData: _notificationBus.history,
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? _notificationBus.history;

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: VxSpacing.small),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: VxColors.border.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationTile(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: VxColors.textTertiary,
          ),
          SizedBox(height: VxSpacing.large),
          Text(
            'No notifications yet',
            style: TextStyle(
              color: VxColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: VxSpacing.small),
          Text(
            'You\'ll be notified about signals, trades, and updates',
            style: TextStyle(
              color: VxColors.textTertiary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(VolexNotification notification) {
    final icon = _getIconForType(notification.type);
    final color = _getColorForType(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: VxColors.neonRed.withValues(alpha: 0.2),
        child: const Icon(Icons.delete, color: VxColors.neonRed),
      ),
      onDismissed: (direction) {
        final dismissedItem = notification;
        _notificationBus.remove(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification dismissed'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                _notificationBus.add(dismissedItem);
              },
            ),
          ),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VxSpacing.medium,
          vertical: VxSpacing.small,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: notification.isRead ? VxColors.textSecondary : Colors.white,
            fontSize: 15,
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification
                  .message, // AppNotification.body -> VolexNotification.message
              style: const TextStyle(
                color: VxColors.textTertiary,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(notification.timestamp),
              style: const TextStyle(
                color: VxColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: VxColors.neonCyan,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          if (!notification.isRead) {
            _notificationBus.markAsRead(notification.id);
          }
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.strategy: // Was 'signal'
        return Icons.show_chart;
      case NotificationType.order: // Was 'trade'
        return Icons.swap_horiz;
      case NotificationType.risk: // Was 'alert'
        return Icons.warning_amber;
      case NotificationType.system:
        return Icons.info_outline;
      case NotificationType.user: // Was 'achievement'
        return Icons.emoji_events;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.strategy:
        return VxColors.neonCyan;
      case NotificationType.order:
        return VxColors.neonGreen;
      case NotificationType.risk:
        return VxColors.warning;
      case NotificationType.system:
        return VxColors.info;
      case NotificationType.user:
        return VxColors.neonPurple;
    }
  }

  void _handleNotificationTap(VolexNotification notification) {
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.strategy:
        // Navigate to signals tab
        context.go('/'); // Assuming home is signals or has signals tab
        break;
      case NotificationType.order:
        // Navigate to portfolio
        context.go('/portfolio'); // Assuming this route exists
        break;
      default:
        break;
    }
  }

  void _markAllAsRead() {
    final userId = getIt<AuthService>().currentUser?.uid ?? 'unknown';
    _notificationBus.markAllAsRead(userId); // Add userId argument
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.surface,
        title: const Text('Clear all notifications?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _notificationBus.clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: VxColors.neonRed,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
