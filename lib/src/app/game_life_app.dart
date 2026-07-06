import 'package:flutter/material.dart';

import 'app_startup_gate.dart';
import 'app_theme.dart';

class GameLifeApp extends StatelessWidget {
  const GameLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Life',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppStartupGate(),
    );
  }
}
