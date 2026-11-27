import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_repository.dart';
import '../models/query.dart';
import '../ui/formatting.dart';
import 'category_priorities_screen.dart';

/// Manager dashboard: all queries grouped by date, sorted by priority within a
/// date, with per-query comment + status editing.
class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager dashboard'),
        actions: [
          IconButton(
            tooltip: 'Category priorities',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const CategoryPrioritiesScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<AppRepository>(
        builder: (context, repo, _) {
          final groups = _groupByDate(repo.queriesByPriority);
          if (groups.isEmpty) {
            return const Center(child: Text('No requests yet.'));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final entry in groups)
                ..._dateSection(context, repo, entry.key, entry.value),
            ],
          );
        },
      ),
    );
  }

  /// Groups a priority-sorted list by date (newest date first), preserving the
  /// incoming priority order within each date.
  List<MapEntry<DateTime, List<Query>>> _groupByDate(List<Query> sorted) {
    final map = <DateTime, List<Query>>{};
    for (final q in sorted) {
      map.putIfAbsent(dateKey(q.createdAt), () => []).add(q);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  List<Widget> _dateSection(
    BuildContext context,
    AppRepository repo,
    DateTime date,
    List<Query> queries,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          dateGroupLabel(date),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      for (final q in queries) _QueryCard(query: q, repo: repo),
    ];
  }
}

class _QueryCard extends StatelessWidget {
  final Query query;
  final AppRepository repo;
  const _QueryCard({required this.query, required this.repo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final worker = repo.workerById(query.workerId);
    final category = repo.categoryByKey(query.categoryKey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => _editComment(context),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: urgencyColor(query.urgency, scheme),
                width: 6,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${query.ticketNo} · ${worker?.name ?? 'Unknown'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(timeLabel(query.createdAt),
                      style: TextStyle(color: scheme.outline, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    avatar: Icon(categoryIcon(category.key), size: 18),
                    label: Text(category.label),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(urgencyLabel(query.urgency)),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: urgencyColor(query.urgency, scheme)),
                    labelStyle:
                        TextStyle(color: urgencyColor(query.urgency, scheme)),
                    backgroundColor: Colors.transparent,
                  ),
                  Chip(
                    label: Text(statusLabel(query.status)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(query.transcript),
              if (query.managerComment != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.reply, size: 16, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(query.managerComment!)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _editComment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommentSheet(query: query, repo: repo),
    );
  }
}

class _CommentSheet extends StatefulWidget {
  final Query query;
  final AppRepository repo;
  const _CommentSheet({required this.query, required this.repo});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  late final TextEditingController _comment =
      TextEditingController(text: widget.query.managerComment ?? '');
  late QueryStatus _status = widget.query.status;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _save() {
    widget.repo
        .addManagerComment(widget.query.id, _comment.text, status: _status);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Reply to #${widget.query.ticketNo}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _comment,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comment (played back to the worker)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<QueryStatus>(
            segments: [
              for (final s in QueryStatus.values)
                ButtonSegment(value: s, label: Text(statusLabel(s))),
            ],
            selected: {_status},
            onSelectionChanged: (set) => setState(() => _status = set.first),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
