import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Centralized Icon System for Volex Terminal
/// Uses a mix of Cupertino (iOS-style/Sharp) and Material Icons
/// to achieve a "Technical/Cyber" aesthetic.
class VxIcons {
  VxIcons._();

  // --- Navigation ---
  static const IconData navHome = CupertinoIcons.house_fill;
  static const IconData navPortfolio = CupertinoIcons.chart_pie_fill;
  static const IconData navAnalyst = CupertinoIcons.chart_bar_fill;
  static const IconData navSettings = CupertinoIcons.settings_solid;

  // --- Core Toggles (Settings) ---
  static const IconData liveTrading =
      CupertinoIcons.bolt_horizontal_circle_fill;
  static const IconData paperTrading = CupertinoIcons.lab_flask_solid;
  static const IconData proMode = CupertinoIcons.rocket_fill;

  // --- Settings Items ---
  static const IconData notifications = CupertinoIcons.bell_fill;
  static const IconData security = CupertinoIcons.shield_fill;
  static const IconData appearance = CupertinoIcons.paintbrush_fill;
  static const IconData help = CupertinoIcons.question_circle_fill;

  // --- Security & Risk ---
  static const IconData biometric = CupertinoIcons
      .hand_draw_fill; // or fingerprint if available, usually Material has better fingerprint
  static const IconData fingerprint =
      Icons.fingerprint; // Material is better for this specific metaphor
  static const IconData lock = CupertinoIcons.lock_fill;
  static const IconData unlock = CupertinoIcons.lock_open_fill;
  static const IconData shieldOk = CupertinoIcons
      .shield_fill; // Fallback as check variant might not exist in this version
  static const IconData warning = CupertinoIcons.exclamationmark_triangle_fill;
  static const IconData power = CupertinoIcons.power;

  // --- Common ---
  static const IconData chevronRight = CupertinoIcons.chevron_right;
  static const IconData back = CupertinoIcons.arrow_left;
  static const IconData close = CupertinoIcons.xmark;
  static const IconData search = CupertinoIcons.search;

  // --- Dashboard/Cockpit ---
  static const IconData trendFlat = CupertinoIcons.minus;
  static const IconData trendUp = CupertinoIcons.arrow_up_right;
  static const IconData trendDown = CupertinoIcons.arrow_down_right;
}
