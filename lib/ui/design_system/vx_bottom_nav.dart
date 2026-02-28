import 'package:flutter/material.dart';
import 'vx_colors.dart';
import 'vx_icons.dart';

class VxBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  // We define the items internally now to ensure icon consistency
  // Ideally this might be passed in, but standardizing here is safer for the "Vx" system.
  static const List<BottomNavigationBarItem> defaultItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.science_outlined), // Material Icon for now (Lab)
      label: 'LAB',
    ),
    BottomNavigationBarItem(
      icon: Icon(VxIcons.navHome), // Reuse Home/Terminal icon
      label: 'TRADE',
    ),
    BottomNavigationBarItem(
      icon: Icon(VxIcons.navPortfolio),
      label: 'PORTFOLIO',
    ),
    BottomNavigationBarItem(
      icon: Icon(VxIcons.navSettings),
      label: 'SETTINGS',
    ),
  ];

  const VxBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    List<BottomNavigationBarItem>?
        items, // Optional override if absolutely needed
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: VxColors.surface,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: defaultItems,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: VxColors.neonCyan,
        unselectedItemColor: Colors.white38,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle:
            const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle:
            const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
