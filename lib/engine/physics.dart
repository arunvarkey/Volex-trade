class Physics {
  // Config
  static const double kFriction = 0.95; // Air resistance (0.90 - 0.99)
  static const double kSpringK =
      0.1; // Spring constant for bouncy limits (future)
  static const double kMinVelocity = 10.0; // Cutoff to stop float math

  /// Apply friction decay to velocity
  static double applyFriction(double velocity, double dt) {
    // Simple exponential decay approximation
    // vNew = vOld * (friction ^ dt_steps)
    // For 60fps fixed step, just mult is fine.
    return velocity * kFriction;
  }

  /// Clamp view offset
  static double clampOffset(
      double offset, double contentWidth, double screenWidth) {
    // Min offset: -overscroll (let's say 0 for hard stop)
    // Max offset: contentWidth - screenWidth

    // We actually scroll from Right to Left usually in trading,
    // but let's assume standard Left-to-Right for MVP.
    // 0 = Start of Data (Left)
    // Max = End of Data (Right).

    final maxScroll = contentWidth - screenWidth;
    if (maxScroll < 0) return 0; // Content fits screen

    return offset.clamp(0.0, maxScroll);
  }
}
