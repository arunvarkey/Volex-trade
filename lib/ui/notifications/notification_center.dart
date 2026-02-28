import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../engine/notifications/notification_bus.dart';
import '../../engine/notifications/notification_model.dart';
import '../design_system/vx_colors.dart';
import '../design_system/vx_typography.dart';
import '../design_system/vx_spacing.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  final NotificationBus _bus = NotificationBus();
  List<VolexNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
    _bus.onNotification.listen((_) {
      if (mounted) _load();
    });
  }

  void _load() {
    setState(() {
      _notifications = _bus.history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: VxColors.surface.withOpacity(0.95),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_notifications[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          VxSpacing.md, 40, VxSpacing.xs, VxSpacing.md),
      color: VxColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VxText.monoBold("NOTIFICATIONS", color: Colors.white, fontSize: 16),
          IconButton(
            icon:
                const Icon(Icons.done_all, color: VxColors.neonCyan, size: 20),
            onPressed: () {
              _bus.markAllAsRead('current_user');
              _load();
            },
            tooltip: "Mark all read",
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none_outlined,
              size: 48, color: Colors.white10),
          const SizedBox(height: 16),
          VxText.body("No notifications", color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(VolexNotification note) {
    Color color = VxColors.neonCyan;
    if (note.type == NotificationType.risk) color = VxColors.neonRed;
    if (note.type == NotificationType.system) color = VxColors.warning;
    if (note.type == NotificationType.strategy) color = VxColors.neonGreen;

    return Dismissible(
      key: Key(note.id),
      onDismissed: (direction) {
        _bus.markAsRead(note.id);
      },
      child: Container(
        padding: const EdgeInsets.all(VxSpacing.md),
        decoration: BoxDecoration(
          color:
              note.isRead ? Colors.transparent : Colors.white.withOpacity(0.03),
          border: const Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(note.type),
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      VxText.monoBold(note.title,
                          color: Colors.white, fontSize: 13),
                      VxText.mono(DateFormat('HH:mm').format(note.timestamp),
                          color: Colors.white24, fontSize: 10),
                    ],
                  ),
                  const SizedBox(height: 4),
                  VxText.body(note.message,
                      color: Colors.white60, fontSize: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.strategy:
        return Icons.auto_fix_high;
      case NotificationType.order:
        return Icons.shopping_cart_outlined;
      case NotificationType.risk:
        return Icons.gpp_maybe_outlined;
      case NotificationType.system:
        return Icons.terminal_outlined;
      case NotificationType.user:
        return Icons.person_outline;
      default:
        return Icons.notifications_none;
    }
  }
}
