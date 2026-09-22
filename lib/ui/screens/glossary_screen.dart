import 'dart:async';

import 'package:flutter/material.dart';

import 'package:volex_terminal/core/analytics/vx_funnel.dart';
import 'package:volex_terminal/core/glossary.dart';
import 'package:volex_terminal/ui/design_system/vx_colors.dart';
import 'package:volex_terminal/ui/design_system/vx_typography.dart';

/// Every term the app uses, in one searchable place.
///
/// The glossary already existed as a set of definitions reachable by tapping a
/// "?" next to a label, which works only if you happen to be standing on the
/// screen that shows that label. Someone who read the word "drawdown" in a
/// lesson, or heard "short" somewhere and wants to know what it means, had
/// nowhere to look it up.
class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  /// Debounce for the search analytics. Cancelled on dispose — a pending
  /// timer that fires after the screen is gone would touch `_filtered` on a
  /// defunct State.
  Timer? _searchLog;

  @override
  void dispose() {
    _searchLog?.cancel();
    _search.dispose();
    super.dispose();
  }

  List<MapEntry<String, GlossaryEntry>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return Glossary.all;
    // Searches the definitions too, so looking up a word you half-remember
    // ("the one about losing streaks") still finds the entry.
    return Glossary.all.where((e) {
      final v = e.value;
      return v.term.toLowerCase().contains(q) ||
          v.simple.toLowerCase().contains(q) ||
          v.detail.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    return Scaffold(
      backgroundColor: VxColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Glossary'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: (v) {
                setState(() => _query = v);
                // Debounced: onChanged fires per keystroke, and logging
                // "s", "sh", "sha", "shar" would bury the one term the user
                // actually meant. The misses are the valuable half — they
                // are a list, written by users, of vocabulary we are
                // missing.
                _searchLog?.cancel();
                _searchLog = Timer(const Duration(milliseconds: 1200), () {
                  final q = v.trim();
                  if (q.length < 2) return;
                  VxFunnel.glossarySearched(q, found: _filtered.isNotEmpty);
                });
              },
              style: VxTypography.body,
              decoration: InputDecoration(
                hintText: 'Search terms',
                hintStyle: VxTypography.body
                    .copyWith(color: VxColors.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: VxColors.textTertiary),
                filled: true,
                fillColor: VxColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${results.length} of ${Glossary.all.length} terms',
                style: VxTypography.caption,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No term matches "${_search.text}". If you met this '
                        'word inside Volex and it is not here, it is a gap '
                        'worth reporting.',
                        textAlign: TextAlign.center,
                        style: VxTypography.bodySmall,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _TermTile(results[i].value),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Collapsed to the one-line explanation, expanding to the full detail. The
/// plain-English line is the part most people need, so it is what shows first.
class _TermTile extends StatelessWidget {
  final GlossaryEntry entry;

  const _TermTile(this.entry);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VxColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: VxColors.textTertiary,
          collapsedIconColor: VxColors.textTertiary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(
            entry.term,
            style: VxTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              entry.simple,
              style: VxTypography.bodySmall.copyWith(height: 1.4),
            ),
          ),
          children: [
            Text(
              entry.detail,
              style: VxTypography.bodySmall.copyWith(
                color: VxColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
