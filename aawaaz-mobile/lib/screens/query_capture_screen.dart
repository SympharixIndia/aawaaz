import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_repository.dart';
import '../l10n/prompts.dart';
import '../models/worker.dart';
import '../services/categorizer.dart';
import '../services/voice_service.dart';
import '../ui/formatting.dart';

enum _Phase { loading, ready, listening, confirming, done }

/// The core voice loop for a logged-in worker:
/// prompt (TTS) -> listen (STT) -> categorize -> confirm -> store -> acknowledge.
class QueryCaptureScreen extends StatefulWidget {
  final Worker worker;
  const QueryCaptureScreen({super.key, required this.worker});

  @override
  State<QueryCaptureScreen> createState() => _QueryCaptureScreenState();
}

class _QueryCaptureScreenState extends State<QueryCaptureScreen> {
  final _voice = VoiceService();
  late final Prompts _p = Prompts.forLanguage(widget.worker.languageCode);

  _Phase _phase = _Phase.loading;
  bool _sttAvailable = true;
  String _transcript = '';
  CategorizationResult? _result;
  int? _ticketNo;

  String get _lang => widget.worker.languageCode;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    _sttAvailable = await _voice.initStt();
    if (!mounted) return;
    setState(() => _phase = _Phase.ready);
    await _voice.speak('Namaste ${widget.worker.name}. ${_p.ask}', _lang);
  }

  Future<void> _listen() async {
    setState(() {
      _transcript = '';
      _phase = _Phase.listening;
    });
    await _voice.listen(
      languageCode: _lang,
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _transcript = text);
        if (isFinal) _onHeard(text);
      },
    );
  }

  void _onHeard(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() => _phase = _Phase.ready);
      _voice.speak(_p.noInput, _lang);
      return;
    }
    _confirm(trimmed);
  }

  Future<void> _confirm(String text) async {
    final result = Categorizer.categorize(text);
    setState(() {
      _transcript = text;
      _result = result;
      _phase = _Phase.confirming;
    });
    await _voice.speak(_p.confirm(text), _lang);
  }

  Future<void> _typeInstead() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_p.ask),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) _confirm(text.trim());
  }

  Future<void> _confirmYes() async {
    final repo = context.read<AppRepository>();
    final query = repo.addQuery(
      workerId: widget.worker.id,
      transcript: _transcript,
      languageCode: _lang,
      categoryKey: _result!.categoryKey,
      urgency: _result!.urgency,
    );
    setState(() {
      _ticketNo = query.ticketNo;
      _phase = _Phase.done;
    });
    await _voice.speak(_p.acknowledge(query.ticketNo), _lang);
  }

  Future<void> _confirmNo() async {
    setState(() {
      _transcript = '';
      _result = null;
      _phase = _Phase.ready;
    });
    await _voice.speak(_p.retry, _lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Namaste, ${widget.worker.name}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_phase) {
            _Phase.loading => const Center(child: CircularProgressIndicator()),
            _Phase.ready => _buildReady(),
            _Phase.listening => _buildListening(),
            _Phase.confirming => _buildConfirming(),
            _Phase.done => _buildDone(),
          },
        ),
      ),
    );
  }

  Widget _buildReady() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_p.ask,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 40),
        _MicButton(onPressed: _sttAvailable ? _listen : null),
        const SizedBox(height: 16),
        Text(_sttAvailable ? _p.tapToSpeak : 'Speech not available',
            style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: _typeInstead,
          icon: const Icon(Icons.keyboard),
          label: const Text('Type instead'),
        ),
      ],
    );
  }

  Widget _buildListening() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Listening…', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 24),
        Icon(Icons.graphic_eq,
            size: 72, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(_transcript,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () async {
            await _voice.stopListening();
            _onHeard(_transcript);
          },
          child: const Text('Done speaking'),
        ),
      ],
    );
  }

  Widget _buildConfirming() {
    final scheme = Theme.of(context).colorScheme;
    final category =
        context.read<AppRepository>().categoryByKey(_result!.categoryKey);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_p.confirmPrefix,
            style: TextStyle(color: scheme.outline, fontSize: 16)),
        const SizedBox(height: 8),
        Text('"$_transcript"',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(category.label)),
            Chip(
              label: Text(urgencyLabel(_result!.urgency)),
              side: BorderSide(color: urgencyColor(_result!.urgency, scheme)),
              labelStyle:
                  TextStyle(color: urgencyColor(_result!.urgency, scheme)),
              backgroundColor: Colors.transparent,
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(_p.confirmSuffix,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _confirmNo,
                style:
                    FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                icon: const Icon(Icons.close),
                label: Text(_p.no),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: _confirmYes,
                style:
                    FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                icon: const Icon(Icons.check),
                label: Text(_p.yes),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDone() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, size: 96, color: scheme.primary),
        const SizedBox(height: 24),
        const Text('Request filed', style: TextStyle(fontSize: 22)),
        const SizedBox(height: 8),
        Text('Ticket #$_ticketNo',
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _MicButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _MicButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: onPressed == null ? scheme.surfaceContainerHighest : scheme.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 140,
          height: 140,
          child: Icon(Icons.mic,
              size: 64,
              color: onPressed == null
                  ? scheme.outline
                  : scheme.onPrimary),
        ),
      ),
    );
  }
}
