import 'package:flutter/material.dart';

import 'src/app/game_life_app.dart';
import 'src/core/database/app_database.dart';
import 'src/core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Abre/cria o banco antes do app iniciar.
  await AppDatabase.instance.database;
  await NotificationService.instance.initialize();

  runApp(const GameLifeApp());
}
