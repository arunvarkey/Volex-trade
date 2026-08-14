import 'package:flutter/material.dart';
import 'package:volex_terminal/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../design_system/vx_colors.dart';
import '../../design_system/vx_typography.dart';
import '../../design_system/vx_card.dart';
import '../../widgets/glossary_sheet.dart';
import '../../../services/profile_service.dart';
import '../../../engine/execution_manager.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = context.watch<ProfileService>();
    final execution = context.watch<ExecutionManager>();

    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: VxText.subtitle(AppLocalizations.of(context).profileTitle),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: VxColors.surface,
                    backgroundImage: profileService.profileImage != null
                        ? FileImage(profileService.profileImage!)
                        : null,
                    child: profileService.profileImage == null
                        ? Text(
                            _initials(profileService.displayName),
                            style: VxTypography.h1
                                .copyWith(color: VxColors.primary),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: VxColors.primary,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt,
                            size: 18, color: Colors.white),
                        onPressed: () =>
                            _showImageSourceDialog(context, profileService),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Editable name
            GestureDetector(
              onTap: () => _editName(context, profileService),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VxText.heading2(profileService.displayName),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_outlined,
                      size: 18, color: VxColors.textTertiary),
                ],
              ),
            ),
            const SizedBox(height: 4),
            VxText.body(AppLocalizations.of(context).profilePaperTrader,
                color: VxColors.textSecondary),

            const SizedBox(height: 40),

            _buildStatCard(execution),

            const SizedBox(height: 24),

            _buildInfoList(execution),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'T';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _buildStatCard(ExecutionManager execution) {
    final closed =
        execution.positions.where((p) => !p.isOpen).toList(growable: false);
    final trades = closed.length;
    final wins = closed.where((p) => (p.realizedPnL ?? 0) > 0).length;
    final winRate = trades > 0 ? (wins / trades * 100) : 0.0;
    final pnl = execution.totalPnL;

    return VxCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
                "Win Rate", trades > 0 ? "${winRate.toStringAsFixed(0)}%" : "—",
                termId: 'win_rate'),
            _buildStatItem("Trades", "$trades"),
            _buildStatItem(
              "P&L",
              "${pnl >= 0 ? '+' : '-'}\$${pnl.abs().toStringAsFixed(0)}",
              color: pnl >= 0 ? VxColors.positive : VxColors.negative,
              termId: 'pnl',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value,
      {Color? color, String? termId}) {
    final labelStyle =
        VxTypography.body.copyWith(color: Colors.white38, fontSize: 10);
    return Column(
      children: [
        termId != null
            ? InfoLabel(text: label, termId: termId, style: labelStyle)
            : Text(label, style: labelStyle),
        const SizedBox(height: 4),
        VxText.subtitle(value, color: color ?? VxColors.textPrimary),
      ],
    );
  }

  Widget _buildInfoList(ExecutionManager execution) {
    return Column(
      children: [
        _buildInfoTile(Icons.account_balance_wallet_outlined, "Balance",
            "\$${execution.balance.toStringAsFixed(0)}"),
        _buildInfoTile(Icons.science_outlined, "Mode", "Paper (simulated)"),
        _buildInfoTile(
            Icons.bolt_outlined, "Active strategies", "${execution.activeStrategyIds.length}"),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.white38, size: 20),
      title: VxText.body(label, color: Colors.white38),
      trailing: VxText.body(value),
    );
  }

  Future<void> _editName(BuildContext context, ProfileService service) async {
    final controller = TextEditingController(
        text: service.hasCustomName ? service.displayName : '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VxColors.surface,
        title: VxText.subtitle("Your name"),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          style: const TextStyle(color: Colors.white),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Alex',
            hintStyle: TextStyle(color: Colors.white24),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: VxColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: VxColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await service.setDisplayName(name);
    }
  }

  void _showImageSourceDialog(BuildContext context, ProfileService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VxColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: VxColors.primary),
                title: const Text("Take photo",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  service.pickAndProcessImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: VxColors.primary),
                title: const Text("Choose from gallery",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  service.pickAndProcessImage(ImageSource.gallery);
                },
              ),
              if (service.profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: VxColors.negative),
                  title: const Text("Remove photo",
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    service.clearImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
