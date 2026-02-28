import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import 'vx_colors.dart';

class TradeSuccessConfetti extends StatefulWidget {
  final ConfettiController controller;

  const TradeSuccessConfetti({
    super.key,
    required this.controller,
  });

  @override
  State<TradeSuccessConfetti> createState() => _TradeSuccessConfettiState();
}

class _TradeSuccessConfettiState extends State<TradeSuccessConfetti> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConfettiWidget(
        confettiController: widget.controller,
        blastDirectionality: BlastDirectionality.explosive,
        // Don't blast too much
        emissionFrequency: 0.05,
        numberOfParticles: 20,
        gravity: 0.1,
        colors: const [
          VxColors.neonGreen,
          VxColors.neonCyan,
          Colors.white,
        ],
      ),
    );
  }
}
