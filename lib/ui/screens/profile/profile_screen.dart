import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design_system/vx_colors.dart';
import '../../design_system/vx_typography.dart';
import '../../design_system/vx_card.dart';
import '../../../services/profile_service.dart';
import '../settings/settings_screen.dart'; // [NEW]

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = context.watch<ProfileService>();

    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: VxText.subtitle("Operator Profile"),
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

            // Avatar Section
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
                        ? const Icon(Icons.person,
                            size: 60, color: VxColors.neonCyan)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: VxColors.neonCyan,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt,
                            size: 20, color: Colors.black),
                        onPressed: () =>
                            _showImageSourceDialog(context, profileService),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            VxText.heading2("John Doe"),
            VxText.body("Elite Operator", color: VxColors.neonCyan),

            const SizedBox(height: 48),

            _buildStatCard(context),

            const SizedBox(height: 24),

            _buildInfoList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context) {
    return VxCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("Win Rate", "68%"),
            _buildStatItem("Total Trades", "1.2k"),
            _buildStatItem("Profit", "+14.2%"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        VxText.body(label, color: Colors.white38, fontSize: 10),
        const SizedBox(height: 4),
        VxText.subtitle(value, color: VxColors.neonCyan),
      ],
    );
  }

  Widget _buildInfoList() {
    return Column(
      children: [
        _buildInfoTile(Icons.email, "Email", "j.doe@volex.terminal"),
        _buildInfoTile(Icons.calendar_today, "Joined", "Jan 2026"),
        _buildInfoTile(Icons.security, "Trust Score", "98/100"),
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

  void _showImageSourceDialog(BuildContext context, ProfileService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VxColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera, color: VxColors.neonCyan),
                title: const Text("Camera"),
                onTap: () {
                  // ProfileService.pickImage()
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: VxColors.neonCyan),
                title: const Text("Gallery"),
                onTap: () {
                  // ProfileService.pickImage()
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
