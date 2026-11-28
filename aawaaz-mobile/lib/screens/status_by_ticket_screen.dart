import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/backend_service.dart';
import '../l10n/prompts.dart';
import '../models/api/request_dto.dart';
import '../services/voice_service.dart';
import '../ui/formatting.dart';

/// Worker checks a request by ticket number (no login). Shows and speaks the
/// current status + the manager's reply, in the request's own language.
class StatusByTicketScreen extends StatefulWidget {
  const StatusByTicketScreen({super.key});

  @override
  State<StatusByTicketScreen> createState() => _StatusByTicketScreenState();
}

class _StatusByTicketScreenState extends State<StatusByTicketScreen> {
  final _voice = VoiceService();
  final _ticket = TextEditingController();

  bool _loading = false;
  String? _error;
  RequestDto? _result;

  @override
  void dispose() {
    _voice.dispose();
    _ticket.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final raw = _ticket.text.trim();
    final id = int.tryParse(raw);
    if (id == null) {
      setState(() => _error = 'Enter a valid ticket number.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    final backend = context.read<BackendService>();
    try {
      final request = await backend.requestByTicket(id);
      if (!mounted) return;
      setState(() {
        _result = request;
        _loading = false;
      });
      _speak(request);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.statusCode == 404
            ? 'No request found with that number.'
            : e.message;
      });
    }
  }

  void _speak(RequestDto r) {
    final prompts = Prompts.forLanguage(r.originalLanguage);
    _voice.speak(prompts.statusSpeech(r.workerReply), r.originalLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check request status')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Enter your ticket number',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _ticket,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Ticket number',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _check(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _check,
                style:
                    FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Check status', style: TextStyle(fontSize: 18)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 24),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (_result != null) ...[
                const SizedBox(height: 24),
                _ResultCard(request: _result!, onReplay: () => _speak(_result!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final RequestDto request;
  final VoidCallback onReplay;
  const _ResultCard({required this.request, required this.onReplay});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reply = request.workerReply;
    final hasReply = reply != null && reply.trim().isNotEmpty;
    return Card(
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
                  Text(hasReply ? reply : 'Still pending'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onReplay,
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
