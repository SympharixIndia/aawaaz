import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/backend_service.dart';
import '../l10n/prompts.dart';
import '../models/api/request_dto.dart';
import '../models/worker.dart';
import '../services/spoken_number.dart';
import '../services/voice_service.dart';
import '../ui/formatting.dart';

/// Logged-in worker checks a request by ticket number — by voice (in their own
/// language) or by typing. Shows and speaks the status + the manager's reply.
class StatusByTicketScreen extends StatefulWidget {
  final Worker worker;
  const StatusByTicketScreen({super.key, required this.worker});

  @override
  State<StatusByTicketScreen> createState() => _StatusByTicketScreenState();
}

class _StatusByTicketScreenState extends State<StatusByTicketScreen> {
  final _voice = VoiceService();
  final _ticket = TextEditingController();
  late final Prompts _p = Prompts.forLanguage(widget.worker.languageCode);

  bool _loading = false;
  bool _listening = false;
  String? _error;
  RequestDto? _result;

  String get _lang => widget.worker.languageCode;

  @override
  void dispose() {
    _voice.dispose();
    _ticket.dispose();
    super.dispose();
  }

  /// Speak the prompt, then listen; parse the spoken number and look it up.
  Future<void> _listenForTicket() async {
    if (!await _voice.initStt()) {
      setState(() => _error = 'Speech not available — please type your ticket number.');
      return;
    }
    await _voice.speak(_p.ticketPrompt, _lang);
    if (!mounted) return;
    setState(() {
      _listening = true;
      _error = null;
    });
    await _voice.listen(
      languageCode: _lang,
      onResult: (text, isFinal) {
        if (!mounted || !isFinal) return;
        setState(() => _listening = false);
        final id = parseSpokenTicket(text);
        if (id == null) {
          setState(() => _error = 'I couldn\'t catch the number — try again or type it.');
        } else {
          _ticket.text = '$id';
          _lookup(id);
        }
      },
    );
  }

  Future<void> _checkTyped() async {
    final id = int.tryParse(_ticket.text.trim());
    if (id == null) {
      setState(() => _error = 'Enter a valid ticket number.');
      return;
    }
    await _lookup(id);
  }

  Future<void> _lookup(int id) async {
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
      _voice.speak(_p.statusSpeech(request.workerReply), _lang);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Check request status')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_listening ? 'Listening…' : _p.ticketPrompt,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              Center(
                child: Material(
                  color: _listening ? scheme.error : scheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: (_loading || _listening) ? null : _listenForTicket,
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Center(
                        child: Icon(_listening ? Icons.graphic_eq : Icons.mic,
                            size: 56, color: scheme.onPrimary),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                controller: _ticket,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Or type your ticket number',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _checkTyped(),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading ? null : _checkTyped,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Check status'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error)),
              ],
              if (_result != null) ...[
                const SizedBox(height: 24),
                _ResultCard(request: _result!, onReplay: () {
                  _voice.speak(_p.statusSpeech(_result!.workerReply), _lang);
                }),
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
