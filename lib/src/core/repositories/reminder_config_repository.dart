import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/v3_commitment_models.dart';
import '../utils/id_generator.dart';

class UpsertReminderInput {
  const UpsertReminderInput({
    this.id,
    required this.itemType,
    this.itemId,
    required this.title,
    required this.body,
    required this.reminderType,
    this.timeOfDay,
    this.scheduledDate,
    required this.isEnabled,
  });

  final String? id;
  final String itemType;
  final String? itemId;
  final String title;
  final String body;
  final String reminderType;
  final String? timeOfDay;
  final String? scheduledDate;
  final bool isEnabled;
}

class ReminderConfigRepository {
  Future<List<ReminderConfig>> getAll({bool onlyEnabled = false}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'reminder_configs',
      where: onlyEnabled ? 'is_enabled = ?' : null,
      whereArgs: onlyEnabled ? [1] : null,
      orderBy: 'reminder_type ASC, title ASC',
    );
    return rows.map(ReminderConfig.fromMap).toList();
  }

  Future<String> upsert(UpsertReminderInput input) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final id = input.id ?? IdGenerator.create('reminder');
    final values = {
      'id': id,
      'item_type': input.itemType,
      'item_id': input.itemId,
      'title': input.title.trim(),
      'body': input.body.trim(),
      'reminder_type': input.reminderType,
      'time_of_day': input.timeOfDay,
      'scheduled_date': input.scheduledDate,
      'is_enabled': input.isEnabled ? 1 : 0,
      'updated_at': now,
    };

    final exists = await db.query(
      'reminder_configs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (exists.isEmpty) {
      await db.insert(
        'reminder_configs',
        {
          ...values,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.update(
        'reminder_configs',
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    return id;
  }

  Future<void> setEnabled(String reminderId, bool enabled) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'reminder_configs',
      {
        'is_enabled': enabled ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [reminderId],
    );
  }
}
