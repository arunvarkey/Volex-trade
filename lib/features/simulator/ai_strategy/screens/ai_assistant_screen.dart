// lib/features/simulator/ai_strategy/screens/ai_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../ui/design_system/vx_colors.dart';
import '../../../../features/subscriptions/services/subscription_service.dart';
import 'package:volex_terminal/ui/design_system/vx_haptics.dart';
import '../services/template_library.dart';
import '../services/ai_service.dart';
import '../models/strategy_template.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  StrategyTemplate? _selectedTemplate;
  final _controller = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _suggestion;
  String? _reasoning;

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionService>();

    // Check access
    if (!subscription.canUseAiAssistant) {
      return _buildPaywallPrompt(context);
    }

    return Scaffold(
      backgroundColor: VxColors.deepBlack,
      appBar: AppBar(
        backgroundColor: VxColors.deepBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(
          children: [
            Icon(Icons.psychology, color: VxColors.neonPurple, size: 24),
            SizedBox(width: 8),
            Text(
              'AI STRATEGY ASSISTANT',
              style: TextStyle(
                color: VxColors.neonPurple,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VxColors.neonPurple.withValues(alpha: 0.2),
                    VxColors.neonCyan.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(color: VxColors.neonPurple.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: VxColors.neonPurple),
                      SizedBox(width: 8),
                      Text(
                        'HOW IT WORKS',
                        style: TextStyle(
                          color: VxColors.neonPurple,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Choose a strategy template\n'
                    '2. Describe your trading goal\n'
                    '3. AI suggests optimal parameters\n'
                    '4. Review and backtest',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Template selector
            _buildSectionHeader('CHOOSE TEMPLATE'),
            const SizedBox(height: 12),
            _buildTemplateDropdown(),

            const SizedBox(height: 24),

            // Description input
            _buildSectionHeader('DESCRIBE YOUR GOAL'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    'e.g., "I want to catch short-term bounces on Bitcoin when it\'s oversold, '
                    'with tight stop losses and quick profit taking"',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: VxColors.neonPurple.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: VxColors.neonPurple, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ||
                        _selectedTemplate == null ||
                        _controller.text.isEmpty
                    ? null
                    : _generateSuggestion,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(VxColors.deepBlack),
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_loading ? 'THINKING...' : 'GET AI SUGGESTION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VxColors.neonPurple,
                  foregroundColor: VxColors.deepBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // Suggestion display
            if (_suggestion != null) ...[
              const SizedBox(height: 32),
              _buildSuggestionCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaywallPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.deepBlack,
      appBar: AppBar(
        backgroundColor: VxColors.deepBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        title:
            const Text('AI ASSISTANT', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, color: VxColors.neonPurple, size: 80),
              const SizedBox(height: 24),
              const Text(
                'PREMIUM FEATURE',
                style: TextStyle(
                  color: VxColors.neonPurple,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AI Strategy Assistant is available with Premium subscription',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.push('/paywall'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VxColors.neonPurple,
                  foregroundColor: VxColors.deepBlack,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('UPGRADE TO PREMIUM'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: VxColors.neonCyan,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTemplateDropdown() {
    final templates = TemplateLibrary.all;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<StrategyTemplate>(
        value: _selectedTemplate,
        hint: Text('Select a template...',
            style: TextStyle(color: Colors.grey[600])),
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white),
        items: templates.map((template) {
          return DropdownMenuItem(
            value: template,
            child: Row(
              children: [
                Icon(template.icon, color: VxColors.neonCyan, size: 20),
                const SizedBox(width: 12),
                Text(template.name),
              ],
            ),
          );
        }).toList(),
        onChanged: (template) {
          setState(() {
            _selectedTemplate = template;
            _suggestion = null;
            _reasoning = null;
          });
        },
      ),
    );
  }

  Widget _buildSuggestionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VxColors.neonGreen.withValues(alpha: 0.1),
            VxColors.neonCyan.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: VxColors.neonGreen.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: VxColors.neonGreen),
              SizedBox(width: 8),
              Text(
                'AI SUGGESTED CONFIGURATION',
                style: TextStyle(
                  color: VxColors.neonGreen,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Parameters
          ..._selectedTemplate!.parameters.map((param) {
            final value = _suggestion![param.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    param.label,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      color: VxColors.neonCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),

          if (_reasoning != null) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.grey[800]),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.psychology,
                    color: VxColors.neonPurple, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _reasoning!,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _acceptSuggestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VxColors.neonGreen,
                    foregroundColor: VxColors.deepBlack,
                  ),
                  child: const Text('ACCEPT & BACKTEST'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _generateSuggestion,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VxColors.neonPurple,
                    side: const BorderSide(color: VxColors.neonPurple),
                  ),
                  child: const Text('REGENERATE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generateSuggestion() async {
    if (_selectedTemplate == null || _controller.text.isEmpty) return;

    setState(() {
      _loading = true;
      _suggestion = null;
      _reasoning = null;
    });

    try {
      final aiService = GetIt.I<AIService>();
      final result = await aiService.suggestParameters(
        template: _selectedTemplate!,
        userDescription: _controller.text,
      );

      if (result.isSuccess && mounted && result.value != null) {
        final fullReasoning = result.value!['reasoning'] as String? ?? '';
        await _typeSuggestion(result.value!, fullReasoning);
      } else if (mounted) {
        setState(() => _loading = false);
        _showError(result.error ?? 'Failed to get suggestion');
        VxHaptics.error();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Error: $e');
        VxHaptics.error();
      }
    }
  }

  Future<void> _typeSuggestion(
      Map<String, dynamic> suggestion, String reasoning) async {
    setState(() {
      _loading = false;
      _suggestion = suggestion;
      _reasoning = '';
    });

    VxHaptics.success();

    // Typing effect for reasoning
    final words = reasoning.split(' ');
    for (var i = 0; i < words.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 30));
      setState(() {
        _reasoning = '${_reasoning!} ${words[i]}';
      });
      if (i % 5 == 0) VxHaptics.light();
    }
  }

  void _acceptSuggestion() {
    if (_suggestion == null || _selectedTemplate == null) return;

    VxHaptics.medium();

    final strategy = _selectedTemplate!.instantiate({
      ..._suggestion!,
      'name': 'AI: ${_controller.text.split(' ').take(4).join(' ')}',
    });

    context.push('/simulator/backtest', extra: strategy);
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.deepBlack,
        title: const Text('ERROR', style: TextStyle(color: VxColors.neonRed)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: VxColors.neonCyan)),
          ),
        ],
      ),
    );
  }
}
