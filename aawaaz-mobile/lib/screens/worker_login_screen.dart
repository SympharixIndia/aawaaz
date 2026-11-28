import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/backend_service.dart';
import '../models/api/user_dto.dart';
import '../models/worker.dart';
import 'query_capture_screen.dart';

/// Worker login (username + numeric PIN) — authenticates against the backend,
/// then navigates to [destination] (defaults to the query-capture flow).
class WorkerLoginScreen extends StatefulWidget {
  final Widget Function(Worker worker)? destination;
  const WorkerLoginScreen({super.key, this.destination});

  @override
  State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
}

class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _pin = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _username.dispose();
    _pin.dispose();
    super.dispose();
  }

  /// Carries the authenticated user into the (currently in-memory) query flow.
  Worker _toWorker(UserDto u) => Worker(
        id: u.id.toString(),
        username: u.username,
        name: u.name,
        password: '',
        languageCode: u.languageCode,
        registeredAt: DateTime.now(),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final backend = context.read<BackendService>();
    final navigator = Navigator.of(context);
    try {
      final user = await backend.login(_username.text, _pin.text);
      if (!mounted) return;
      final worker = _toWorker(user);
      final build = widget.destination ?? (w) => QueryCaptureScreen(worker: w);
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => build(worker)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.statusCode == 401
            ? 'Username or password incorrect.'
            : e.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearError(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your username' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pin,
                  decoration: const InputDecoration(
                    labelText: 'Password (PIN)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _clearError(),
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your PIN' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }
}
