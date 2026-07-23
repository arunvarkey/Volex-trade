import 'package:flutter/material.dart';

import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

import 'age_gate_service.dart';

/// Wraps the app: shows the age gate until the user confirms they meet the
/// 13+ minimum, then renders [child]. Shown before the PIN/auth gate.
class AgeGate extends StatefulWidget {
  final Widget child;
  const AgeGate({super.key, required this.child});

  @override
  State<AgeGate> createState() => _AgeGateState();
}

class _AgeGateState extends State<AgeGate> {
  final AgeGateService _service = AgeGateService.instance;

  @override
  void initState() {
    super.initState();
    _service.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        if (!_service.isLoaded) {
          return const _Scaffolded(
            child: Center(
              child: CircularProgressIndicator(color: VxColors.neonCyan),
            ),
          );
        }
        if (_service.isConfirmed) return widget.child;
        return _Scaffolded(
          child: _service.isBlocked
              ? const _BlockedView()
              : _AskView(service: _service),
        );
      },
    );
  }
}

class _Scaffolded extends StatelessWidget {
  final Widget child;
  const _Scaffolded({required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(color: VxColors.deepBlack, child: SafeArea(child: child)),
    );
  }
}

class _AskView extends StatelessWidget {
  final AgeGateService service;
  const _AskView({required this.service});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('🎓', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text('Before you start',
              textAlign: TextAlign.center,
              style: VxTypography.h1.copyWith(fontSize: 26)),
          const SizedBox(height: 12),
          Text(
            'Volex is a risk-free trading simulator for learning — no real '
            'money is ever used. To continue, please confirm your age.',
            textAlign: TextAlign.center,
            style: VxTypography.bodySmall.copyWith(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => service.confirmMeetsMinimum(),
            style: ElevatedButton.styleFrom(
              backgroundColor: VxColors.neonCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text("I'M ${AgeGateService.minimumAge} OR OLDER",
                style: const TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => service.declineUnderAge(),
            child: Text('I\'m under ${AgeGateService.minimumAge}',
                style: VxTypography.bodySmall
                    .copyWith(fontSize: 13, color: Colors.white54)),
          ),
          const SizedBox(height: 20),
          Text(
            'By continuing you agree this is an educational simulator and not '
            'financial advice.',
            textAlign: TextAlign.center,
            style: VxTypography.caption.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  const _BlockedView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_clock_rounded,
              size: 56, color: VxColors.neonYellow),
          const SizedBox(height: 20),
          Text('Come back soon',
              textAlign: TextAlign.center,
              style: VxTypography.h2.copyWith(fontSize: 22)),
          const SizedBox(height: 10),
          Text(
            'You need to be at least ${AgeGateService.minimumAge} to use '
            'Volex. We\'d love to have you when you\'re old enough!',
            textAlign: TextAlign.center,
            style: VxTypography.bodySmall.copyWith(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => AgeGateService.instance.reset(),
            child: Text('That was a mistake — go back',
                style: VxTypography.caption
                    .copyWith(fontSize: 12, color: VxColors.neonCyan)),
          ),
        ],
      ),
    );
  }
}
