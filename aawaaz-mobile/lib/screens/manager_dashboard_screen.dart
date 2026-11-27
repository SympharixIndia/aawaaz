import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/backend_service.dart';
import '../models/api/request_dto.dart';
import '../models/query.dart';
import '../ui/formatting.dart';
import 'category_priorities_screen.dart';

/// Manager dashboard: the selected day's requests (backend-sorted by priority),
/// with per-request comment + status editing.
class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  late BackendService _backend;
  DateTime _date = DateTime.now();
  late Future<List<RequestDto>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backend = context.read<BackendService>();
    _future = _backend.listRequests(date: _date);
  }

  void _reload() => setState(() => _future = _backend.listRequests(date: _date));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      _date = picked;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager dashboard'),
        actions: [
          IconButton(
            tooltip: 'Pick date',
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
          IconButton(
            tooltip: 'Category priorities',
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CategoryPrioritiesScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text(dateGroupLabel(_date),
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                    onPressed: _reload, icon: const Icon(Icons.refresh)),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<RequestDto>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _ErrorView(
                      message: _describe(snap.error), onRetry: _reload);
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView(children: const [
                      SizedBox(height: 240),
                      Center(child: Text('No requests for this day.')),
                    ]),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _RequestCard(
                      request: items[i],
                      onEdit: () => _editComment(items[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editComment(RequestDto r) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CommentSheet(request: r, backend: _backend),
    );
    if (saved == true) _reload();
  }

  String _describe(Object? e) =>
      e is ApiException ? e.message : 'Something went wrong.';
}

class _RequestCard extends StatelessWidget {
  final RequestDto request;
  final VoidCallback onEdit;
  const _RequestCard({required this.request, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = (request.translatedText?.isNotEmpty ?? false)
        ? request.translatedText!
        : request.originalText;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onEdit,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color: urgencyColor(request.urgency, scheme), width: 6),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('#${request.id} · Worker #${request.workerId}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (request.createdAt != null)
                    Text(timeLabel(request.createdAt!.toLocal()),
                        style: TextStyle(color: scheme.outline, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    avatar: Icon(categoryIcon(request.categoryKey), size: 18),
                    label: Text(categoryLabel(request.categoryKey)),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(urgencyLabel(request.urgency)),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: urgencyColor(request.urgency, scheme)),
                    labelStyle:
                        TextStyle(color: urgencyColor(request.urgency, scheme)),
                    backgroundColor: Colors.transparent,
                  ),
                  Chip(
                    label: Text(statusLabel(request.status)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(text),
              if (request.managerComment?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.reply, size: 16, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(request.managerComment!)),
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
}

class _CommentSheet extends StatefulWidget {
  final RequestDto request;
  final BackendService backend;
  const _CommentSheet({required this.request, required this.backend});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  late final TextEditingController _comment =
      TextEditingController(text: widget.request.managerComment ?? '');
  late QueryStatus _status = widget.request.status;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    try {
      await widget.backend.updateRequest(
        widget.request.id,
        status: _status,
        managerComment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      );
      if (!mounted) return;
      navigator.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
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
          Text('Reply to #${widget.request.id}',
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
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
