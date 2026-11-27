import 'package:flutter/material.dart';

import '_placeholder.dart';

/// Manager login (hardcoded credentials) and dashboard. Lands in build Step 4.
class ManagerLoginScreen extends StatelessWidget {
  const ManagerLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manager')),
      body: const PlaceholderBody(
        icon: Icons.admin_panel_settings,
        message: 'Manager login + dashboard coming in Step 4.',
      ),
    );
  }
}
