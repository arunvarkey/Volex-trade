import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_toolbar.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/design_system/vx_status_badge.dart';
import 'package:volex_terminal/ui/design_system/vx_toast.dart';
import 'package:volex_terminal/ui/screens/notifications/components/risk_banner.dart';
import '../../engine/notifications/notification_bus.dart';
import '../../engine/notifications/notification_model.dart';
import '../../engine/sync/cloud_sync_service.dart';
import '../../data/market_data_repository.dart';
import '../../domain/candle_model.dart';
import 'dart:async';
import '../design_system/vx_action_center.dart';

class VxAppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final String currentLocation;

  const VxAppShell({
    super.key,
    required this.navigationShell,
    required this.currentLocation,
  });

  @override
  State<VxAppShell> createState() => _VxAppShellState();
}

class _VxAppShellState extends State<VxAppShell> {
  StreamSubscription? _notifSub;
  VolexNotification? _activeRisk;
  VolexNotification? _currentToast;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _notifSub = NotificationBus().onNotification.listen(_handleNotification);
    CloudSyncService().init();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _handleNotification(VolexNotification note) {
    if (note.severity == NotificationSeverity.critical &&
        note.type == NotificationType.risk) {
      setState(() => _activeRisk = note);
    } else {
      _showToast(note);
    }
  }

  void _showToast(VolexNotification note) {
    _toastTimer?.cancel();
    setState(() => _currentToast = note);
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _currentToast = null);
    });
  }

  void _onTabTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      // A common pattern when switching branches is to support
      // navigating to the initial location when tapping the item that is
      // already active.
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    final navItems = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined), label: "HOME"),
      const BottomNavigationBarItem(
          icon: Icon(Icons.show_chart), label: "STRATS"),
      const BottomNavigationBarItem(
          icon: Icon(Icons.assessment_outlined), label: "ANALYST"),
      const BottomNavigationBarItem(icon: Icon(Icons.history), label: "LOGS"),
      const BottomNavigationBarItem(
          icon: Icon(Icons.mail_outline), label: "INBOX"),
      const BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined), label: "CONFIG"),
    ];

    Widget body = Stack(
      children: [
        widget.navigationShell,
        // Risk Banner - Top Positioned
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            reverseDuration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: _activeRisk != null
                ? RiskBanner(
                    key: const ValueKey('risk_banner'),
                    title: _activeRisk!.title,
                    message: _activeRisk!.message,
                    onAcknowledge: () => setState(() => _activeRisk = null),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        // Toast - Bottom Positioned
        Positioned(
          bottom: isDesktop ? 20 : 80,
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: _currentToast != null
                ? Center(
                    key: ValueKey(_currentToast!.id),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: VxToast(
                        title: _currentToast!.title,
                        message: _currentToast!.message,
                        icon: _getIconForType(_currentToast!.type),
                        color: _getColorForType(_currentToast!.type),
                        onDismiss: () => setState(() => _currentToast = null),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: VxColors.background,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: VxColors.surface,
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: _onTabTapped,
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: const TextStyle(
                  color: VxColors.neonCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
              unselectedLabelTextStyle:
                  const TextStyle(color: Colors.white38, fontSize: 10),
              selectedIconTheme: const IconThemeData(color: VxColors.neonCyan),
              unselectedIconTheme: const IconThemeData(color: Colors.white38),
              useIndicator: false,
              destinations: navItems
                  .map((e) => NavigationRailDestination(
                        icon: e.icon,
                        label: Text(e.label!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ))
                  .toList(),
              leading: _buildRailLeading(),
            ),
            const VerticalDivider(width: 1, color: Colors.white10),
            Expanded(
              child: Column(
                children: [
                  VxToolbar(
                    title: VxText.title("VOLEX TERMINAL", color: Colors.white),
                    actions: [_buildHeaderStatus(), const SizedBox(width: 16)],
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: VxColors.background,
        appBar: VxToolbar(
          title: VxText.subtitle("VOLEX", color: Colors.white),
          actions: [
            Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildHeaderStatus())
          ],
        ),
        body: body,
        floatingActionButton: const VxActionCenter(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _onTabTapped,
          backgroundColor: VxColors.surface,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: VxColors.neonCyan,
          unselectedItemColor: Colors.white38,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: navItems,
        ),
      );
    }
  }

  Widget _buildRailLeading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: VxColors.neonCyan.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: VxColors.neonCyan),
        ),
        child: const Center(
            child: Icon(Icons.terminal, color: VxColors.neonCyan, size: 20)),
      ),
    );
  }

  Widget _buildHeaderStatus() {
    return StreamBuilder<SyncStatus>(
      stream: CloudSyncService().statusStream,
      initialData: CloudSyncService().currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.idle;
        return Row(
          children: [
            if (status != SyncStatus.idle) ...[
              _buildSyncIndicator(status),
              const SizedBox(width: 12),
            ],
            StreamBuilder<Candle>(
              stream: MarketDataRepository().updatesStream,
              builder: (context, snapshot) {
                final price = snapshot.hasData
                    ? snapshot.data!.close.toStringAsFixed(2)
                    : "---";
                return VxText.monoBold("BTC $price", color: VxColors.neonGreen);
              },
            ),
            const SizedBox(width: 16),
            const VxStatusBadge(
                label: "SIMULATION", style: VxBadgeStyle.info, outline: true),
          ],
        );
      },
    );
  }

  Widget _buildSyncIndicator(SyncStatus status) {
    String label = "SYNCED";
    Color color = VxColors.neonCyan;
    bool showSpinner = false;

    switch (status) {
      case SyncStatus.syncing:
        label = "SYNCING...";
        color = Colors.orange;
        showSpinner = true;
        break;
      case SyncStatus.success:
        label = "CLOUD SAVED";
        color = VxColors.neonGreen;
        break;
      case SyncStatus.error:
        label = "SYNC ERROR";
        color = VxColors.neonRed;
        break;
      case SyncStatus.idle:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          VxText.monoBold(label, color: color, fontSize: 9),
        ],
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.strategy:
        return Icons.trending_up;
      case NotificationType.order:
        return Icons.check_circle_outline;
      case NotificationType.risk:
        return Icons.warning_amber_rounded;
      case NotificationType.system:
        return Icons.dns;
      case NotificationType.user:
        return Icons.person_outline;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.strategy:
        return VxColors.neonGreen;
      case NotificationType.order:
        return VxColors.neonCyan;
      case NotificationType.risk:
        return VxColors.neonRed;
      case NotificationType.system:
        return Colors.orange;
      case NotificationType.user:
        return Colors.purpleAccent;
    }
  }
}
