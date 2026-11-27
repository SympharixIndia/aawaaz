import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_repository.dart';
import '../l10n/prompts.dart';
import '../models/query.dart';
import '../models/worker.dart';
import '../services/voice_service.dart';
import '../ui/formatting.dart';

/// Lists the logged-in worker's requests (newest first) and reads each one's
/// status — the manager's reply, or "still pending" — aloud in their language.
class MyStatusScreen extends StatefulWidget {
  final Worker worker;
  const MyStatusScreen({super.key, required this.worker});

  @override
  State<MyStatusScreen> createState() => _MyStatusScreenState();
}

class _MyStatusScreenState extends State<MyStatusScreen> {
  final _voice = VoiceService();
  late final Prompts _p = Prompts.forLanguage(widget.worker.languageCode);

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  Future<void> _speakStatus(Query q) =>
      _voice.speak(_p.statusSpeech(q.managerComment), widget.worker.languageCode);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My requests')),
      body: Consumer<AppRepository>(
        builder: (context, repo, _) {
          final queries = repo.queriesForWorker(widget.worker.id);
          if (queries.isEmpty) {
            return const Center(child: Text('You have no requests yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: queries.length,
            itemBuilder: (context, i) =>
                _StatusCard(query: queries[i], repo: repo, onSpeak: _speakStatus),
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Query query;
  final AppRepository repo;
  final Future<void> Function(Query) onSpeak;
  const _StatusCard(
      {required this.query, required this.repo, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final category = repo.categoryByKey(query.categoryKey);
    final hasReply =
        query.managerComment != null && query.managerComment!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(categoryIcon(category.key), size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('#${query.ticketNo} · ${category.label}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text('${dateGroupLabel(query.createdAt)}, ${timeLabel(query.createdAt)}',
                    style: TextStyle(color: scheme.outline, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(query.transcript),
            const SizedBox(height: 12),
            Chip(
              label: Text(statusLabel(query.status)),
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
                  Text(hasReply ? query.managerComment! : 'Still pending'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => onSpeak(query),
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
