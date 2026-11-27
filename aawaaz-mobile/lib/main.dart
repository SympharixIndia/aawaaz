import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'data/app_repository.dart';
import 'screens/home_screen.dart';
import 'ui/theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppRepository()..seedDemoData(),
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
