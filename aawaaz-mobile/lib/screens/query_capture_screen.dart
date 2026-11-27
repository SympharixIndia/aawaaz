import 'package:flutter/material.dart';

import '../models/worker.dart';
import '_placeholder.dart';

/// Voice query capture for a logged-in worker. The spoken flow (TTS prompt ->
/// STT -> categorize -> confirm -> store) lands in build Step 5; for now this
/// confirms the worker was recognised.
class QueryCaptureScreen extends StatelessWidget {
  final Worker worker;
  const QueryCaptureScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Namaste, ${worker.name}')),
      body: PlaceholderBody(
        icon: Icons.mic,
        message: 'Logged in as ${worker.name} (${worker.username}).\n\n'
            'Voice query flow coming in Step 5,\n'
            'and "My status" in Step 6.',
      ),
    );
  }
}
