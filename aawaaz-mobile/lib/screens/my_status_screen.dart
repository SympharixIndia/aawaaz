import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/backend_service.dart';
import '../l10n/prompts.dart';
import '../models/api/request_dto.dart';
import '../models/worker.dart';
import '../services/voice_service.dart';
import '../ui/formatting.dart';

/// Lists the logged-in worker's requests (newest first) from the backend and
/// reads each one's status — the manager's reply, or "still pending" — aloud.
class MyStatusScreen extends StatefulWidget {
  final Worker worker;
  const MyStatusScreen({super.key, required this.worker});

  @override
  State<MyStatusScreen> createState() => _MyStatusScreenState();
}

class _MyStatusScreenState extends State<MyStatusScreen> {
  final _voice = VoiceService();
  late final Prompts _p = Prompts.forLanguage(widget.worker.languageCode);
  late BackendService _backend;
  late Future<List<RequestDto>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backend = context.read<BackendService>();
    _future = _backend.requestsForWorker(int.parse(widget.worker.id));
  }

  void _reload() => setState(() =>
      _future = _backend.requestsForWorker(int.parse(widget.worker.id)));

  Future<void> _speakStatus(RequestDto r) =>
      _voice.speak(_p.statusSpeech(r.managerComment), widget.worker.languageCode);

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My requests')),
      body: FutureBuilder<List<RequestDto>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(snap.error is ApiException
                        ? (snap.error as ApiException).message
                        : 'Could not load your requests.'),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _reload, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('You have no requests yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) =>
                  _StatusCard(request: items[i], onSpeak: _speakStatus),
            ),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final RequestDto request;
  final Future<void> Function(RequestDto) onSpeak;
  const _StatusCard({required this.request, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasReply =
        request.managerComment != null && request.managerComment!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(categoryIcon(request.categoryKey),
                    size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('#${request.id} · ${categoryLabel(request.categoryKey)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (request.createdAt != null)
                  Text(
                    '${dateGroupLabel(request.createdAt!.toLocal())}, '
                    '${timeLabel(request.createdAt!.toLocal())}',
                    style: TextStyle(color: scheme.outline, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.originalText),
            const SizedBox(height: 12),
            Chip(
              label: Text(statusLabel(request.status)),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hasReply ? 'Manager reply' : 'Status',
                      style: TextStyle(color: scheme.outline, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(hasReply ? request.managerComment! : 'Still pending'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => onSpeak(request),
                icon: const Icon(Icons.volume_up),
                label: const Text('Play aloud'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
