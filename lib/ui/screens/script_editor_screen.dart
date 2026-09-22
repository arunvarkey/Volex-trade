import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/vx_colors.dart';
import '../design_system/vx_typography.dart';
import 'package:volex_terminal/ui/widgets/feature_intro.dart';

class ScriptEditorScreen extends StatefulWidget {
  final String? initialScript;
  const ScriptEditorScreen({super.key, this.initialScript});

  @override
  State<ScriptEditorScreen> createState() => _ScriptEditorScreenState();
}

class _ScriptEditorScreenState extends State<ScriptEditorScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialScript != null) {
      _codeController.text = widget.initialScript!;
    } else {
      _loadDraft();
    }
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString('last_draft_script');
    if (draft != null && draft.isNotEmpty) {
      setState(() => _codeController.text = draft);
    } else {
      _codeController.text = """
def on_candle(candle):
    # Example: Simple Moving Average Cross
    
    # 1. Calculate Indicators
    rsi = indicators.rsi(period=14)
    sma_20 = indicators.sma(period=20)
    
    # 2. Logic
    if rsi < 30 and candle.close > sma_20:
        volex.buy(amount=0.1)
        print("Buying the dip!")
        
    elif rsi > 70:
        volex.sell(amount=0.1)
        print("Taking profits.")
""";
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insertSnippet(String text) {
    final textSelection = _codeController.selection;
    if (textSelection.start == -1) {
      // Append to end if no selection
      final newText = _codeController.text + text;
      _codeController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } else {
      final newText = _codeController.text.replaceRange(
        textSelection.start,
        textSelection.end,
        text,
      );
      final myTextLength = text.length;
      _codeController.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: textSelection.start + myTextLength),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: VxColors.surface,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(Icons.code, color: VxColors.neonCyan, size: 20),
              const SizedBox(width: 8),
              VxText.monoBold("Script Editor", fontSize: 14),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save, color: VxColors.neonCyan),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('last_draft_script', _codeController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Draft Saved to Disk")));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: VxColors.neonCyan),
            tooltip: 'Publish to Marketplace',
            onPressed: () async {
              // Mock Publish Flow
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Publish Strategy"),
                  content:
                      const Text("Publish this strategy to the marketplace?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Strategy Published Successfully!")),
                        );
                        Navigator.pop(context); // Close Editor
                      },
                      child: const Text("Publish"),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                // Simulate Engine Integration
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Validating Strategy Syntax... Passed."),
                    backgroundColor: VxColors.neonGreen,
                  ),
                );
                Future.delayed(const Duration(seconds: 1), () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("Simulation complete. Strategy is stable."),
                        backgroundColor: VxColors.neonCyan,
                      ),
                    );
                    Navigator.of(context).pop(_codeController.text);
                  }
                });
              },
              icon: const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text("Simulate",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: VxColors.neonCyan,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const FeatureIntro(
            featureId: 'script_editor',
            icon: Icons.code_rounded,
            what: 'Write your own trading rules as code, when the ready-made '
                'templates cannot express the idea you have in mind.',
            when: 'This one is for people who already program. If you do not, '
                'nothing here is missing from the rest of the app — Strategy '
                'Studio builds the same kinds of rules without code.',
          ),
          // Code Editor Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1E1E1E), // VS Code Dark bg
              child: TextField(
                controller: _codeController,
                focusNode: _focusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: VxTypography.price.copyWith(
                  color: const Color(0xFFD4D4D4), // VS Code text
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                enableInteractiveSelection: true,
              ),
            ),
          ),
          _buildHelperToolbar(),
        ],
      ),
    );
  }

  Widget _buildHelperToolbar() {
    return Container(
      height: 48,
      color: VxColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _SnippetButton("def ", onTap: () => _insertSnippet("def ")),
          _SnippetButton("if ", onTap: () => _insertSnippet("if ")),
          _SnippetButton("else:", onTap: () => _insertSnippet("else:\n    ")),
          _SnippetButton(":", onTap: () => _insertSnippet(":")),
          _SnippetButton(" (", onTap: () => _insertSnippet(" (")),
          _SnippetButton(") ", onTap: () => _insertSnippet(") ")),
          _SnippetButton("volex.buy()",
              onTap: () => _insertSnippet("volex.buy(amount=0.1)")),
          _SnippetButton("volex.sell()",
              onTap: () => _insertSnippet("volex.sell(amount=0.1)")),
          _SnippetButton("rsi", onTap: () => _insertSnippet("rsi")),
          _SnippetButton("sma", onTap: () => _insertSnippet("sma")),
          _SnippetButton("print()", onTap: () => _insertSnippet("print()")),
        ],
      ),
    );
  }
}

class _SnippetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SnippetButton(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: VxColors.background,
          foregroundColor: VxColors.neonCyan,
          elevation: 0,
          side: BorderSide(color: VxColors.neonCyan.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style:
              VxTypography.price.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
