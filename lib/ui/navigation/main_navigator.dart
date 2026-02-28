import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:volex_terminal/core/service_locator.dart';
import 'package:volex_terminal/services/user_mode_service.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';
import 'package:volex_terminal/ui/widgets/vx_holographic_card.dart';
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
    if (location.startsWith('/portfolio')) return 2;
    if (location.startsWith('/more')) return 3;
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
        context.go('/portfolio');
        break;
      case 3:
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
            left: 20,
            right: 20,
            bottom: 24,
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
    return VxHolographicCard(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      borderRadius: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'HOME',
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          if (userMode == UserMode.explorer)
            _NavIcon(
              icon: Icons.sensors_outlined,
              activeIcon: Icons.sensors,
              label: 'SIGNALS',
              isSelected: selectedIndex == 1,
              onTap: () => onTap(1),
            )
          else
            _NavIcon(
              icon: Icons.terminal_outlined,
              activeIcon: Icons.terminal,
              label: 'TERMINAL',
              isSelected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
          _NavIcon(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            label: 'WALLET',
            isSelected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavIcon(
            icon: Icons.more_horiz_outlined,
            activeIcon: Icons.more_horiz,
            label: 'MORE',
            isSelected: selectedIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
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
            color: isSelected ? VxColors.neonCyan : Colors.white38,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: VxTypography.caption.copyWith(
              fontSize: 9,
              color: isSelected ? VxColors.neonCyan : Colors.white24,
              letterSpacing: 1.0,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
