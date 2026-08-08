import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/l10n/app_localizations.dart';
import 'package:volex_terminal/core/service_locator.dart';
import 'package:volex_terminal/services/user_mode_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/services/haptic_service.dart';

class MainNavigator extends StatefulWidget {
  final Widget child;

  const MainNavigator({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  UserMode _userMode = UserMode.explorer; // Default safely
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserMode();
  }

  Future<void> _loadUserMode() async {
    final mode = await getIt<UserModeService>().getCurrentMode();
    if (mounted) {
      setState(() {
        _userMode = mode;
        _isLoading = false;
      });
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/chart')) return 1;
    if (location.startsWith('/signals')) {
      return 1; // Signals also maps to index 1
    }
    if (location.startsWith('/predictions')) return 2;
    if (location.startsWith('/portfolio')) return 3;
    if (location.startsWith('/more')) return 4;
    return 0; // Home
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticService.instance.light();
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        // Conditional Navigation
        if (_userMode == UserMode.explorer) {
          context.go('/signals');
        } else {
          context.go('/chart');
        }
        break;
      case 2:
        context.go('/predictions');
        break;
      case 3:
        context.go('/portfolio');
        break;
      case 4:
        context.go('/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: VxColors.background,
        body: Center(child: CircularProgressIndicator(color: VxColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: VxColors.background,
      body: Stack(
        children: [
          widget.child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingGlassNav(
              selectedIndex: _calculateSelectedIndex(context),
              onTap: (index) => _onItemTapped(index, context),
              userMode: _userMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingGlassNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final UserMode userMode;

  const _FloatingGlassNav({
    required this.selectedIndex,
    required this.onTap,
    required this.userMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Solid, docked bar. Opaque so page content never bleeds through, with a
    // hairline top border for separation — a clean, standard trading-app nav
    // rather than a translucent floating pill.
    return Container(
      decoration: const BoxDecoration(
        color: VxColors.surface,
        border: Border(
          top: BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
          _NavIcon(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: l10n.navHome,
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          if (userMode == UserMode.explorer)
            _NavIcon(
              icon: Icons.sensors_outlined,
              activeIcon: Icons.sensors,
              label: l10n.navSignals,
              isSelected: selectedIndex == 1,
              onTap: () => onTap(1),
            )
          else
            _NavIcon(
              icon: Icons.terminal_outlined,
              activeIcon: Icons.terminal,
              label: 'Terminal',
              isSelected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
          _NavIcon(
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights,
            label: l10n.navPredict,
            isSelected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavIcon(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            label: l10n.navWallet,
            isSelected: selectedIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavIcon(
            icon: Icons.more_horiz_outlined,
            activeIcon: Icons.more_horiz,
            label: l10n.navMore,
            isSelected: selectedIndex == 4,
            onTap: () => onTap(4),
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? VxColors.primary : VxColors.textTertiary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: VxTypography.caption.copyWith(
              fontSize: 10,
              color: isSelected ? VxColors.primary : VxColors.textTertiary,
              letterSpacing: 0.2,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
