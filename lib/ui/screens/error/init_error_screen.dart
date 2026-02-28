import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/service_locator.dart';
import '../../design_system/vx_colors.dart';

/// Modern error screen with diagnostics and retry functionality
class InitErrorScreen extends StatefulWidget {
  final String error;
  final InitializationResult? initResult;
  final VoidCallback onRetry;
  final VoidCallback? onDismiss;

  const InitErrorScreen({
    super.key,
    required this.error,
    this.initResult,
    required this.onRetry,
    this.onDismiss,
  });

  @override
  State<InitErrorScreen> createState() => _InitErrorScreenState();
}

class _InitErrorScreenState extends State<InitErrorScreen>
    with SingleTickerProviderStateMixin {
  bool _showDetails = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.deepBlack,
      body: SafeArea(
        child: FadeTransition(
          opacity: _controller,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  const SizedBox(height: 40),

                  // Error icon with animation
                  _buildErrorIcon(),

                  const SizedBox(height: 32),

                  // Error message
                  _buildErrorMessage(),

                  const SizedBox(height: 24),

                  // User-friendly explanation
                  _buildExplanation(),

                  const SizedBox(height: 32),

                  // Suggestions
                  _buildSuggestions(),

                  const SizedBox(height: 24),

                  // Diagnostics toggle
                  if (widget.initResult != null) _buildDiagnosticsToggle(),

                  // Diagnostics panel
                  if (_showDetails && widget.initResult != null)
                    _buildDiagnosticsPanel(),

                  const SizedBox(height: 24),

                  // Action buttons
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: VxColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.terminal,
            color: VxColors.neonCyan,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'VOLEX TERMINAL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: VxColors.neonRed.withOpacity(0.1),
              border: Border.all(
                color: VxColors.neonRed.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 50,
              color: VxColors.neonRed,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage() {
    return Column(
      children: [
        const Text(
          'Initialization Failed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _getUserFriendlyMessage(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getUserFriendlyMessage() {
    final error = widget.error.toLowerCase();

    if (error.contains('timeout')) {
      return 'The app took too long to start. This might be due to a slow connection.';
    } else if (error.contains('network') || error.contains('socket')) {
      return 'Could not connect to the network. Check your internet connection.';
    } else if (error.contains('permission')) {
      return 'The app doesn\'t have the required permissions.';
    } else if (error.contains('storage') || error.contains('persistence')) {
      return 'Could not access device storage. Check available space.';
    } else {
      return 'Something unexpected happened during startup.';
    }
  }

  Widget _buildExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: VxColors.neonRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: VxColors.neonRed.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Don\'t worry - your data is safe. We can try again.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = _getSuggestions();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Try these steps:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...suggestions.map((suggestion) => _buildSuggestionItem(suggestion)),
      ],
    );
  }

  List<String> _getSuggestions() {
    final error = widget.error.toLowerCase();

    if (error.contains('timeout') || error.contains('network')) {
      return [
        'Check your internet connection',
        'Try switching between WiFi and mobile data',
        'Wait a moment and try again',
      ];
    } else if (error.contains('storage')) {
      return [
        'Free up device storage space',
        'Clear app cache in device settings',
        'Restart your device',
      ];
    } else if (error.contains('permission')) {
      return [
        'Grant required permissions in settings',
        'Restart the app after granting permissions',
      ];
    } else {
      return [
        'Restart the app',
        'Check for app updates',
        'Restart your device',
      ];
    }
  }

  Widget _buildSuggestionItem(String suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: VxColors.neonCyan,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              suggestion,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsToggle() {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          _showDetails = !_showDetails;
        });
      },
      icon: Icon(
        _showDetails ? Icons.expand_less : Icons.expand_more,
        color: Colors.white54,
      ),
      label: Text(
        _showDetails ? 'Hide Details' : 'Show Technical Details',
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDiagnosticsPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Diagnostics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                color: VxColors.neonCyan,
                onPressed: _copyDiagnostics,
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDiagnosticRow('Error', widget.error),
          if (widget.initResult != null) ...[
            _buildDiagnosticRow(
              'Init Time',
              '${widget.initResult?.initTime.inMilliseconds ?? 0}ms',
            ),
            _buildDiagnosticRow(
              'Steps Completed',
              '${ServiceLocator.initLog.length}',
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Init Log:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text(
                ServiceLocator.initLog.join('\n'),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyDiagnostics() {
    final diagnostics = StringBuffer();
    diagnostics.writeln('Volex Terminal - Error Report');
    diagnostics.writeln('=' * 50);
    diagnostics.writeln('Error: ${widget.error}');
    if (widget.initResult != null) {
      diagnostics.writeln(
          'Init Time: ${widget.initResult?.initTime.inMilliseconds ?? 0}ms');
      diagnostics.writeln('Steps: ${ServiceLocator.initLog.length}');
    }
    diagnostics.writeln('\nInit Log:');
    diagnostics.writeln(ServiceLocator.initLog.join('\n'));

    Clipboard.setData(ClipboardData(text: diagnostics.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostics copied to clipboard'),
        backgroundColor: VxColors.neonCyan,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        // Retry button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: VxColors.neonCyan,
              foregroundColor: VxColors.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Dismiss button (if available)
        if (widget.onDismiss != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onDismiss,
              icon: const Icon(Icons.skip_next),
              label: const Text('Continue Anyway'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Exit button
        TextButton.icon(
          onPressed: () => SystemNavigator.pop(),
          icon: const Icon(Icons.exit_to_app, size: 16),
          label: const Text('Exit App'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white30,
          ),
        ),
      ],
    );
  }
}
