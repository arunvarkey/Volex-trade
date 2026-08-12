import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:volex_terminal/core/services/auth/security_service.dart';
import 'package:volex_terminal/core/service_locator.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';

/// Secure PIN Entry Screen
/// Features:
/// - 6-digit PIN entry
/// - Animated dot indicators
/// - Biometric fallback
/// - Lockout display
/// - Haptic feedback
class PinEntryScreen extends StatefulWidget {
  final PinEntryMode mode;
  final String? oldPin; // For change PIN flow

  const PinEntryScreen({
    super.key,
    required this.mode,
    this.oldPin,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

enum PinEntryMode {
  setup, // First time PIN setup
  verify, // Verify existing PIN
  change, // Change PIN (requires old PIN first)
}

class _PinEntryScreenState extends State<PinEntryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final SecurityService _authService = getIt<SecurityService>();

  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Shake animation for errors
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Listen for app lifecycle changes to clear PIN on background
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeController.dispose();
    // Clear PIN from memory
    _pin = '';
    _confirmPin = '';
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (mounted) {
        // Clear PIN sensitive data when app is backgrounded
        setState(() {
          _pin = '';
          _confirmPin = '';
          // We don't reset _isConfirming to avoid confusing state if user returns immediately,
          // but clearing the input prevents visual exposure of the PIN.
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if locked out
    if (_authService.isLockedOut) {
      return _buildLockoutScreen();
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _pin = '';
          _confirmPin = '';
        }
      },
      child: Scaffold(
        backgroundColor: VxColors.deepBlack,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 60),
                    _buildPinDots(),
                    const SizedBox(height: 40),
                    if (_errorMessage != null) _buildErrorMessage(),
                    const SizedBox(height: 20),
                    _buildNumberPad(),
                    const SizedBox(height: 20),
                    if (widget.mode == PinEntryMode.verify)
                      _buildBiometricButton(),
                    if (widget.mode == PinEntryMode.setup && !_isConfirming)
                      _buildSkipForNowButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title;
    String subtitle;

    switch (widget.mode) {
      case PinEntryMode.setup:
        title = _isConfirming ? 'Confirm PIN' : 'Create PIN';
        subtitle = _isConfirming
            ? 'Enter your PIN again'
            : 'Create a 6-digit PIN to secure your account';
        break;
      case PinEntryMode.verify:
        title = 'Enter PIN';
        subtitle = 'Enter your 6-digit PIN to continue';
        break;
      case PinEntryMode.change:
        title = widget.oldPin == null ? 'Enter Current PIN' : 'Enter New PIN';
        subtitle = widget.oldPin == null
            ? 'Enter your current PIN'
            : 'Create a new 6-digit PIN';
        break;
    }

    return Column(
      children: [
        // Lock Icon
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [VxColors.neonCyan, VxColors.neonCyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_outline,
            color: Colors.white,
            size: 40,
          ),
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < _pin.length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? VxColors.neonCyan : Colors.transparent,
            border: Border.all(
              color: isFilled ? VxColors.neonCyan : Colors.white30,
              width: 2,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: VxColors.neonCyan.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VxColors.neonRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: VxColors.neonRed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: VxColors.neonRed,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: VxColors.neonRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildNumberRow(['1', '2', '3']),
          _buildNumberRow(['4', '5', '6']),
          _buildNumberRow(['7', '8', '9']),
          _buildNumberRow(['', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: numbers.map((number) {
          if (number.isEmpty) {
            return const SizedBox(width: 70, height: 70);
          }

          return _buildNumberButton(number);
        }).toList(),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    final isBackspace = number == '⌫';

    return InkWell(
      onTap: () => _onNumberTap(number),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: VxColors.surface.withValues(alpha: 0.3),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: isBackspace
              ? const Icon(
                  Icons.backspace_outlined,
                  color: Colors.white70,
                  size: 24,
                )
              : Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSkipForNowButton() {
    return TextButton(
      onPressed: () => getIt<SecurityService>().skipSetupForNow(),
      child: const Text(
        'Explore first — set up PIN later',
        style: TextStyle(
          color: VxColors.textSecondary,
          fontSize: 13,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white24,
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return FutureBuilder<bool>(
      future: _authService.isBiometricAvailable,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();

        return TextButton.icon(
          onPressed: _onBiometricTap,
          icon: const Icon(Icons.fingerprint, size: 28),
          label: const Text(
            'Use Biometrics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            foregroundColor: VxColors.neonCyan,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        );
      },
    );
  }

  Widget _buildLockoutScreen() {
    final remaining = _authService.lockoutRemaining;

    return Scaffold(
      backgroundColor: VxColors.deepBlack,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: VxColors.neonRed.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock,
                    color: VxColors.neonRed,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Account Locked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Too many failed attempts.\nPlease try again in ${remaining?.inMinutes ?? 0} minutes.',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // HANDLERS
  // ============================================

  void _onNumberTap(String number) {
    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _errorMessage = null;

      if (number == '⌫') {
        // Backspace
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        // Add number
        if (_pin.length < 6) {
          _pin += number;

          // Auto-submit when 6 digits entered
          if (_pin.length == 6) {
            _handlePinComplete();
          }
        }
      }
    });
  }

  Future<void> _handlePinComplete() async {
    // Small delay for UX
    await Future.delayed(const Duration(milliseconds: 300));

    switch (widget.mode) {
      case PinEntryMode.setup:
        await _handleSetupMode();
        break;
      case PinEntryMode.verify:
        await _handleVerifyMode();
        break;
      case PinEntryMode.change:
        await _handleChangeMode();
        break;
    }
  }

  Future<void> _handleSetupMode() async {
    if (!_isConfirming) {
      // First entry - move to confirmation
      _confirmPin = _pin;
      setState(() {
        _isConfirming = true;
        _pin = '';
      });
    } else {
      // Confirmation entry
      if (_pin == _confirmPin) {
        // PINs match - set up
        try {
          await _authService.setupPin(_pin);

          if (mounted) {
            // Clear PINs from memory
            _pin = '';
            _confirmPin = '';
            if (Navigator.canPop(context)) {
              Navigator.pop(context, true);
            }
          }
        } on PinValidationException catch (e) {
          _showError(e.message);
          _shake();
          // Reset just the current attempt, keep first pin?
          // Actually if it's weak, the FIRST pin was weak. We should reset everything.
          setState(() {
            _isConfirming = false;
            _pin = '';
            _confirmPin = '';
          });
        } catch (e) {
          _showError('Setup failed: ${e.toString()}');
          _shake();
        }
      } else {
        // PINs don't match
        _showError('PINs do not match');
        setState(() {
          _isConfirming = false;
          _pin = '';
          _confirmPin = '';
        });
        _shake();
      }
    }
  }

  Future<void> _handleVerifyMode() async {
    final success = await _authService.verifyPin(_pin);

    if (success && mounted) {
      // Clear PIN from memory
      _pin = '';
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } else {
      _showError('Incorrect PIN');
      setState(() => _pin = '');
      _shake();
    }
  }

  Future<void> _handleChangeMode() async {
    if (widget.oldPin == null) {
      // First verify old PIN
      final success = await _authService.verifyPin(_pin);

      if (success && mounted) {
        // Move to new PIN entry
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PinEntryScreen(
              mode: PinEntryMode.change,
              oldPin: _pin,
            ),
          ),
        );
      } else {
        _showError('Incorrect current PIN');
        setState(() => _pin = '');
        _shake();
      }
    } else {
      // Setup new PIN
      await _handleSetupMode();
    }
  }

  Future<void> _onBiometricTap() async {
    final success = await _authService.authenticateWithBiometrics();

    if (success && mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } else {
      _showError('Biometric authentication failed');
      _shake();
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);

    // Auto-clear error after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _errorMessage = null);
      }
    });
  }

  void _shake() {
    HapticFeedback.heavyImpact();
    _shakeController.forward().then((_) => _shakeController.reverse());
  }
}
