import 'package:flutter/material.dart';

import '_placeholder.dart';

/// New-worker registration. Full form (username + name + PIN + language) lands
/// in build Step 2.
class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: const PlaceholderBody(
        icon: Icons.person_add,
        message: 'Registration form coming in Step 2\n'
            '(username, name, numeric PIN, language).',
      ),
    );
  }
}
