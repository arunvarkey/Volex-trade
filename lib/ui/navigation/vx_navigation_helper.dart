import 'package:flutter/material.dart';

/// Helper to control MainNavigator tabs from anywhere in the app
class VxNavigationHelper {
  // Notifier for the main tab index (0: Lab, 1: Terminal, 2: Settings)
  static final ValueNotifier<int> tabIndexNotifier = ValueNotifier<int>(0);

  static void switchTab(int index) {
    tabIndexNotifier.value = index;
  }

  static void navigateToLab() => switchTab(0);
  static void navigateToTerminal() => switchTab(1);
  static void navigateToAnalyst() => switchTab(1); // Alias for Terminal
  static void navigateToSettings() => switchTab(2);
}
