import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/v3_commitment_models.dart';
import '../utils/id_generator.dart';

class SessionTimerRepository {
  Future<SessionTimerDraft?> getActiveTimer() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'session_timers',
      where: 'status IN (?, ?)',
      whereArgs: ['running', 'paused'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SessionTimerDraft.fromMap(rows.first);
  }

  Future<String> createDraft({
    required String title,
    required String sessionType,
    String? areaId,
    String notes = '',
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final id = IdGenerator.create('timer');
    await db.insert(
      'session_timers',
      {
        'id': id,
        'title': title.trim(),
        'session_type': sessionType,
        'area_id': areaId,
        'status': 'idle',
        'started_at': null,
        'paused_at': null,
        'finished_at': null,
        'elapsed_seconds': 0,
        'total_paused_seconds': 0,
        'notes': notes.trim(),
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return id;
  }

  Future<void> updateStatus({
    required String timerId,
    required String status,
    int? elapsedSeconds,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final values = <String, Object?>{
      'status': status,
      'updated_at': now,
    };

    if (status == 'running') values['started_at'] = now;
    if (status == 'paused') values['paused_at'] = now;
    if (status == 'finished') values['finished_at'] = now;
    if (elapsedSeconds != null) values['elapsed_seconds'] = elapsedSeconds;

    await db.update(
      'session_timers',
      values,
      where: 'id = ?',
      whereArgs: [timerId],
    );
  }
}
