import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design_system/vx_colors.dart';
import '../../design_system/vx_icons.dart';
import '../../../engine/risk_manager.dart';

class RiskSettingsScreen extends StatefulWidget {
  const RiskSettingsScreen({super.key});

  @override
  State<RiskSettingsScreen> createState() => _RiskSettingsScreenState();
}

class _RiskSettingsScreenState extends State<RiskSettingsScreen> {
  final _riskManager = RiskManager();
  late TextEditingController _dailyLimitController;
  Map<String, dynamic> _status = {};

  @override
  void initState() {
    super.initState();
    _status = _riskManager.getStatus();
    _dailyLimitController =
        TextEditingController(text: _status['maxDailyLoss'].toString());

    // Auto-refresh status every second to show live PnL impact
    // In a real app, use a Stream. For now, simple poll for UI freshness.
    // actually, RiskManager has safetyStream but that's just for lock state.
    // Let's rely on manual refresh or periodic call if needed.
  }

  void _refresh() {
    setState(() {
      _status = _riskManager.getStatus();
    });
  }

  void _saveLimit() {
    final val = double.tryParse(_dailyLimitController.text);
    if (val != null && val > 0) {
      _riskManager.setDailyLossLimit(val);
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Daily Loss Limit updated to \$$val")));
    }
  }

  void _killSwitch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.surface,
        title: Text("Emergency Stop",
            style: GoogleFonts.jetBrainsMono(
                color: VxColors.neonRed, fontWeight: FontWeight.bold)),
        content: const Text(
          "This will IMMEDIATELY halt all strategies and block new orders.\n\nAre you sure?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VxColors.neonRed),
            onPressed: () {
              Navigator.pop(context);
              _riskManager.activateEmergencyStop();
              _refresh();
            },
            child: const Text("Kill Switch",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _resetSystem() {
    _riskManager.reset();
    _refresh();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("System Risk State Reset.")));
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _status['isEmergencyStopActive'] ?? false;
    final currentLoss = _status['currentDailyLoss'] ?? 0.0;
    final limit = _status['maxDailyLoss'] ?? 100.0;
    final progress = (currentLoss / limit).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Risk Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isLocked
                  ? VxColors.neonRed.withValues(alpha: 0.1)
                  : VxColors.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isLocked ? VxColors.neonRed : VxColors.neonGreen,
                  width: 2),
            ),
            child: Row(
              children: [
                Icon(isLocked ? VxIcons.lock : VxIcons.shieldOk,
                    size: 40,
                    color: isLocked ? VxColors.neonRed : VxColors.neonGreen),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isLocked ? "System Locked" : "System Active",
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isLocked
                                ? VxColors.neonRed
                                : VxColors.neonGreen)),
                    Text(
                        isLocked
                            ? "Emergency Stop Engaged"
                            : "Risk Gates Operational",
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Daily Loss Configuration
          Text("Daily Loss Limit",
              style: GoogleFonts.jetBrainsMono(
                  color: VxColors.neonCyan, fontSize: 12)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dailyLimitController,
                  style: GoogleFonts.jetBrainsMono(
                      color: Colors.white, fontSize: 16),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: "\$ ",
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    labelText: "Max Daily Loss",
                    labelStyle: const TextStyle(color: Colors.white38),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _saveLimit,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  backgroundColor: VxColors.neonCyan,
                ),
                child: const Text("Update",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Current Loss: \$${currentLoss.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white70)),
                  Text("${(progress * 100).toStringAsFixed(1)}%",
                      style: TextStyle(color: _getColor(progress))),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                color: _getColor(progress),
                minHeight: 8,
              ),
            ],
          ),

          const SizedBox(height: 48),

          // DANGER ZONE
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: VxColors.neonRed.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(16),
              color: VxColors.neonRed.withValues(alpha: 0.05),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(VxIcons.warning, color: VxColors.neonRed),
                    SizedBox(width: 8),
                    Text("Danger Zone",
                        style: TextStyle(
                            color: VxColors.neonRed,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    SizedBox(width: 8),
                    Icon(VxIcons.warning, color: VxColors.neonRed),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isLocked ? null : _killSwitch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VxColors.neonRed,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(VxIcons.power),
                    label: const Text("Activate Kill Switch",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _resetSystem,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: VxColors.neonGreen),
                        foregroundColor: VxColors.neonGreen,
                      ),
                      icon: const Icon(VxIcons.unlock),
                      label: const Text("Unlock System",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(double progress) {
    if (progress < 0.5) return VxColors.neonGreen;
    if (progress < 0.8) return Colors.orange;
    return VxColors.neonRed;
  }
}
