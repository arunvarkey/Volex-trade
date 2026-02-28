import 'package:flutter/material.dart';
import '../core/app_logger.dart';
import '../engine/execution_manager.dart';
import '../engine/risk_manager.dart';
import '../engine/access_control_service.dart';
import 'design_system/vx_colors.dart';
import 'design_system/vx_typography.dart';
import 'design_system/vx_spacing.dart';
import 'marketplace_page.dart';
import 'creator_dashboard/creator_dashboard_page.dart';

import 'package:provider/provider.dart';
import 'notifications/notification_center.dart';

class OperatorConsolePage extends StatefulWidget {
  final ExecutionManager? executionManager;

  const OperatorConsolePage({super.key, this.executionManager});

  @override
  State<OperatorConsolePage> createState() => _OperatorConsolePageState();
}

class _OperatorConsolePageState extends State<OperatorConsolePage> {
  final _accessService = AccessControlService();
  final _riskManager = RiskManager();
  final List<String> _logBuffer = [];

  @override
  void initState() {
    super.initState();
    _logBuffer.add("SYSTEM: CONSOLE_INITIALIZED // ENCRYPTION_ACTIVE");
  }

  void _addLog(String msg) {
    AppLogger.info("CONSOLE: $msg");
    setState(() {
      _logBuffer.insert(0,
          "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} // $msg");
      if (_logBuffer.length > 50) _logBuffer.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final execManager = widget.executionManager ??
        Provider.of<ExecutionManager>(context, listen: false);

    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: VxText.heading2("OPERATOR_CONSOLE", color: Colors.white),
        backgroundColor: Colors.black45,
        elevation: 0,
        actions: [
          StreamBuilder<UserRole>(
              stream: _accessService.roleStream,
              initialData: _accessService.currentRole,
              builder: (context, snapshot) {
                final role = snapshot.data!;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: ActionChip(
                      label: VxText.monoBold("ROLE_${role.name.toUpperCase()}",
                          fontSize: 10, color: Colors.black),
                      backgroundColor: role == UserRole.operator
                          ? VxColors.neonCyan
                          : Colors.grey,
                      onPressed: () {
                        final newRole = role == UserRole.operator
                            ? UserRole.trader
                            : UserRole.operator;
                        _accessService.setRole(newRole);
                        _addLog("LEVEL_SHIFT: Switched to ${newRole.name}");
                      },
                    ),
                  ),
                );
              }),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.notifications_none,
                  color: VxColors.neonCyan),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      endDrawer: const NotificationCenter(),
      body: StreamBuilder<UserRole>(
          stream: _accessService.roleStream,
          initialData: _accessService.currentRole,
          builder: (context, snapshot) {
            final role = snapshot.data!;
            final isOperator = role == UserRole.operator;

            return Padding(
              padding: const EdgeInsets.all(VxSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader("SYSTEM_HEALTH_CORE"),
                        _buildHealthPanel(),
                        const SizedBox(height: 32),
                        _sectionHeader("RISK_AUTHORITY_CONTROLS"),
                        if (isOperator) ...[
                          _buildRiskPanel(execManager),
                        ] else ...[
                          VxText.body(
                              "ACCESS_RESTRICTED // REQUIRES_OPERATOR_LEVEL",
                              color: Colors.white10),
                        ],
                        const SizedBox(height: 32),
                        _sectionHeader("EXECUTION_ENGINE_MODE"),
                        if (isOperator) ...[
                          _buildExecutionModePanel(execManager),
                        ] else ...[
                          VxText.body(
                              "MODE: ${execManager.liveExecutionMode.name.toUpperCase()} (LOCKED)",
                              color: Colors.white10),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _sectionHeader("LIVE_ACTIVITY_FEED // SERIAL_DAEMON"),
                        Expanded(
                            child: Container(
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              border: Border.all(color: Colors.white10),
                              borderRadius: BorderRadius.circular(12)),
                          child: ListView.builder(
                              itemCount: _logBuffer.length,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemBuilder: (ctx, i) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: VxText.mono(_logBuffer[i],
                                      fontSize: 11, color: Colors.white70),
                                );
                              }),
                        ))
                      ],
                    ),
                  )
                ],
              ),
            );
          }),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "creator",
            backgroundColor: Colors.purpleAccent.withOpacity(0.8),
            label: VxText.bodyBold("CREATOR_DASH"),
            icon: const Icon(Icons.analytics, size: 20),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      const CreatorDashboardPage(creatorId: "creator_1")));
            },
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "marketplace",
            backgroundColor: VxColors.neonMagenta.withOpacity(0.8),
            label: VxText.bodyBold("MARKETPLACE"),
            icon: const Icon(Icons.store, size: 20),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MarketplacePage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: VxText.monoBold(title, color: VxColors.neonMagenta, fontSize: 10),
    );
  }

  Widget _buildHealthPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.01),
          border: Border.all(color: VxColors.neonCyan.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _statRow("ENGINE_V6", "ONLINE", VxColors.neonGreen),
          _statRow("EXCHANGE_BUS", "CONNECTED", VxColors.neonGreen),
          StreamBuilder<bool>(
              stream: _riskManager.safetyStream,
              initialData: _riskManager.isLocked,
              builder: (ctx, snap) {
                final locked = snap.data ?? false;
                return _statRow("EMERGENCY_STOP", locked ? "ACTIVE" : "ARMED",
                    locked ? VxColors.neonRed : VxColors.neonGreen);
              })
        ],
      ),
    );
  }

  Widget _buildRiskPanel(ExecutionManager mgr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: VxColors.neonRed.withOpacity(0.02),
          border: Border.all(color: VxColors.neonRed.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
                icon: const Icon(Icons.warning, color: Colors.white, size: 18),
                label: VxText.bodyBold("ACTIVATE_EMERGENCY_STOP"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VxColors.neonRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  _riskManager.activateEmergencyStop();
                  _addLog("OPERATOR: Emergency stop activated.");
                }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white10),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      _riskManager.reset();
                      _addLog("OPERATOR: Risk state reset.");
                    },
                    child: VxText.body("RESET_STATE", color: Colors.white)),
              ),
              const SizedBox(width: 12),
              if (_accessService.canTriggerReconciliation)
                Expanded(
                  child: OutlinedButton.icon(
                      icon: const Icon(Icons.sync,
                          size: 16, color: VxColors.neonCyan),
                      label: VxText.body("RECONCILE", color: VxColors.neonCyan),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: VxColors.neonCyan.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        mgr.reconcile();
                        _addLog("OPERATOR: Manual sync triggered.");
                      }),
                )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionModePanel(ExecutionManager mgr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _modeButton(mgr, LiveExecutionMode.manualOnly, "MANUAL_CONTROL"),
          _modeButton(mgr, LiveExecutionMode.autoCapped, "AUTO_CAPPED"),
          _modeButton(mgr, LiveExecutionMode.fullAuto, "FULL_AUTONOMY"),
        ],
      ),
    );
  }

  Widget _modeButton(
      ExecutionManager mgr, LiveExecutionMode mode, String label) {
    return RadioListTile<LiveExecutionMode>(
      title: VxText.monoBold(label, fontSize: 13, color: Colors.white),
      value: mode,
      groupValue: mgr.liveExecutionMode,
      activeColor: VxColors.neonCyan,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      onChanged: (val) {
        mgr.setLiveExecutionMode(val!);
        _addLog("MODE_SHIFT: ${label.toUpperCase()} active.");
      },
    );
  }

  Widget _statRow(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VxText.mono(label, fontSize: 11, color: Colors.white38),
          VxText.monoBold(val, fontSize: 11, color: color),
        ],
      ),
    );
  }
}
