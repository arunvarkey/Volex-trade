import 'package:flutter/material.dart';

import '../../../ui/design_system/vx_colors.dart';
import '../../../ui/design_system/vx_typography.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';

/// The trading journal.
///
/// The Academy's psychology lesson prescribes journaling every trade with why
/// you entered and how you felt — this is where that happens, and where the
/// resulting behavioural pattern becomes visible.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _service = JournalService.instance;

  @override
  void initState() {
    super.initState();
    _service.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        title: const Text('Trading Journal'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openComposer,
        backgroundColor: VxColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New entry'),
      ),
      body: AnimatedBuilder(
        animation: _service,
        builder: (context, _) {
          final entries = _service.entries;
          if (entries.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: entries.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == 0) return _buildSummary(entries.length);
              return _buildEntryCard(entries[i - 1]);
            },
          );
        },
      ),
    );
  }

  Widget _buildSummary(int total) {
    final risky = _service.riskyMoodCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: VxText.caption(
        risky == 0
            ? '$total ${total == 1 ? 'entry' : 'entries'}'
            : '$total ${total == 1 ? 'entry' : 'entries'} · $risky logged in a '
                'risky state (anxious, greedy or revenge)',
        color: VxColors.textTertiary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined,
                size: 44, color: VxColors.textTertiary),
            const SizedBox(height: 16),
            VxText.subtitle('Your journal is empty'),
            const SizedBox(height: 8),
            VxText.body(
              'Write down why you entered a trade and how you felt. Over time '
              'the patterns in your own behaviour become obvious — and fixable.',
              color: VxColors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry e) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VxColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _moodChip(e.mood),
              if (e.symbol != null) ...[
                const SizedBox(width: 8),
                VxText.caption(e.symbol!, color: VxColors.textSecondary),
              ],
              const Spacer(),
              VxText.caption(_formatDate(e.createdAt),
                  color: VxColors.textTertiary),
              IconButton(
                tooltip: 'Delete entry',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: VxColors.textTertiary),
                onPressed: () => _service.remove(e.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          VxText.body(e.note),
        ],
      ),
    );
  }

  Widget _moodChip(JournalMood mood) {
    final color = mood.isRisky ? VxColors.warning : VxColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        mood.label,
        style: TextStyle(
            color: color, fontSize: 10.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

  Future<void> _openComposer() async {
    final entry = await showModalBottomSheet<JournalEntry>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _JournalComposer(),
    );
    if (entry != null) await _service.add(entry);
  }
}

/// Compose sheet: the note, an optional market, and the mood.
class _JournalComposer extends StatefulWidget {
  const _JournalComposer();

  @override
  State<_JournalComposer> createState() => _JournalComposerState();
}

class _JournalComposerState extends State<_JournalComposer> {
  final _noteController = TextEditingController();
  final _symbolController = TextEditingController();
  JournalMood _mood = JournalMood.neutral;

  @override
  void dispose() {
    _noteController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VxText.subtitle('New journal entry'),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 4,
            autofocus: true,
            style: VxTypography.body.copyWith(color: VxColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Why did you take this trade? How did you feel?',
              hintStyle:
                  VxTypography.body.copyWith(color: VxColors.textTertiary),
              filled: true,
              fillColor: VxColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _symbolController,
            textCapitalization: TextCapitalization.characters,
            style: VxTypography.body.copyWith(color: VxColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Market (optional), e.g. BTCUSDT',
              hintStyle:
                  VxTypography.caption.copyWith(color: VxColors.textTertiary),
              filled: true,
              fillColor: VxColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          VxText.caption('How did you feel?', color: VxColors.textSecondary),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in JournalMood.values)
                GestureDetector(
                  onTap: () => setState(() => _mood = m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _mood == m
                          ? (m.isRisky ? VxColors.warning : VxColors.primary)
                              .withValues(alpha: 0.18)
                          : VxColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _mood == m
                            ? (m.isRisky ? VxColors.warning : VxColors.primary)
                            : VxColors.border,
                      ),
                    ),
                    child: Text(
                      m.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: _mood == m
                            ? (m.isRisky ? VxColors.warning : VxColors.primary)
                            : VxColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: VxColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save entry'),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a note before saving')),
      );
      return;
    }
    final symbol = _symbolController.text.trim().toUpperCase();
    Navigator.pop(
      context,
      JournalEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        note: note,
        mood: _mood,
        createdAt: DateTime.now(),
        symbol: symbol.isEmpty ? null : symbol,
      ),
    );
  }
}
