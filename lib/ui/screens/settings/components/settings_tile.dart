import 'package:flutter/material.dart';
import '../../../design_system/vx_typography.dart';
import '../../../design_system/vx_colors.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  factory SettingsTile.toggle({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: VxColors.neonCyan,
        activeTrackColor: VxColors.neonCyan.withValues(alpha: 0.3),
        inactiveThumbColor: Colors.white54,
        inactiveTrackColor: Colors.white10,
      ),
    );
  }

  factory SettingsTile.navigation({
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VxText.body(title,
                      color: isDestructive ? VxColors.neonRed : Colors.white),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    VxText.caption(subtitle!, color: Colors.white38),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
