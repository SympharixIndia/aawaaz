import 'package:flutter/material.dart';

import '_placeholder.dart';

/// Worker login (username + PIN) before filing a request. Lands in build Step 3.
class WorkerLoginScreen extends StatelessWidget {
  const WorkerLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker login')),
      body: const PlaceholderBody(
        icon: Icons.login,
        message: 'Worker login (username + PIN) coming in Step 3,\n'
            'then the voice query flow in Step 5.',
      ),
    );
  }
}
