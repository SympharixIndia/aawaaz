import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'data/backend_service.dart';
import 'screens/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load backend connection config; tolerate a missing .env (falls back to defaults).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // ApiConfig provides sensible defaults when .env isn't present.
  }
  runApp(
    Provider<BackendService>(
      create: (_) => BackendService(),
      child: const AawaazApp(),
    ),
  );
}

class AawaazApp extends StatelessWidget {
  const AawaazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: aawaazTheme(Brightness.light),
      darkTheme: aawaazTheme(Brightness.dark),
      home: const HomeScreen(),
    );
  }
}
