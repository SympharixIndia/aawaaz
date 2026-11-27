import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../data/api_client.dart';
import '../data/backend_service.dart';

/// New-worker registration: username + name + numeric PIN + profession + language.
/// Submits to the backend (`POST /api/workers`).
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _name = TextEditingController();
  final _pin = TextEditingController();
  final _profession = TextEditingController();
  String _languageCode = supportedLanguages.first.code;
  bool _submitting = false;

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _pin.dispose();
    _profession.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);

    final backend = context.read<BackendService>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final worker = await backend.registerWorker(
        username: _username.text,
        name: _name.text,
        password: _pin.text,
        profession: _profession.text.trim().isEmpty ? null : _profession.text.trim(),
        languageCode: _languageCode,
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text('Registered ${worker.name}. You can now file a request.')));
      navigator.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.statusCode == 409
          ? 'That username is already taken.'
          : e.message;
      messenger.showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
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
                    helperText: 'Used to log in',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a username' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    helperText: 'Your actual name',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _profession,
                  decoration: const InputDecoration(
                    labelText: 'Profession (optional)',
                    helperText: 'e.g. operator, helper',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pin,
                  decoration: const InputDecoration(
                    labelText: 'Numeric password (PIN)',
                    helperText: 'Digits only, at least 4',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Enter a numeric PIN';
                    if (t.length < 4) return 'PIN must be at least 4 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _languageCode,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final lang in supportedLanguages)
                      DropdownMenuItem(value: lang.code, child: Text(lang.label)),
                  ],
                  onChanged: (v) => setState(() => _languageCode = v!),
                ),
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
                      : const Text('Register', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
