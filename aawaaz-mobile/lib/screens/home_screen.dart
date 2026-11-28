import 'package:flutter/material.dart';

import '../constants.dart';
import 'manager_login_screen.dart';
import 'query_capture_screen.dart';
import 'registration_screen.dart';
import 'status_by_ticket_screen.dart';
import 'worker_login_screen.dart';

/// Welcome screen: file a request, check status, register, or manager.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.record_voice_over,
                  size: 88, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Every worker's voice, on record",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const Spacer(),
              _BigButton(
                icon: Icons.mic,
                label: 'Register a request',
                primary: true,
                onPressed: () => _go(
                  context,
                  WorkerLoginScreen(
                    destination: (w) => QueryCaptureScreen(worker: w),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _BigButton(
                icon: Icons.fact_check,
                label: 'Check request status',
                onPressed: () => _go(
                  context,
                  WorkerLoginScreen(
                    destination: (w) => StatusByTicketScreen(worker: w),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _BigButton(
                icon: Icons.person_add,
                label: 'Register (new worker)',
                onPressed: () => _go(context, const RegistrationScreen()),
              ),
              const SizedBox(height: 32),
              TextButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Manager'),
                onPressed: () => _go(context, const ManagerLoginScreen()),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onPressed;

  const _BigButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(72),
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    );
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(icon, size: 28), const SizedBox(width: 12), Text(label)],
    );
    return primary
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : FilledButton.tonal(onPressed: onPressed, style: style, child: child);
  }
}
