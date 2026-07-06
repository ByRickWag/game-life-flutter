import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/v3_commitment_models.dart';
import '../utils/id_generator.dart';
import '../utils/period_utils.dart';

class MissionTaskStats {
  const MissionTaskStats({required this.total, required this.done});

  final int total;
  final int done;

  int get pending => (total - done).clamp(0, total).toInt();
  double get progress => total <= 0 ? 0 : (done / total).clamp(0, 1).toDouble();
  bool get allDone => total > 0 && done >= total;
}

class MissionTaskRepository {
  Future<List<MissionTask>> getTasks(String missionId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'mission_tasks',
      where: 'mission_id = ?',
      whereArgs: [missionId],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(MissionTask.fromMap).toList();
  }

  Future<MissionTaskStats> getStats(String missionId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        COALESCE(SUM(CASE WHEN is_done = 1 THEN 1 ELSE 0 END), 0) AS done
      FROM mission_tasks
      WHERE mission_id = ?;
    ''', [missionId]);

    if (rows.isEmpty) return const MissionTaskStats(total: 0, done: 0);
    return MissionTaskStats(
      total: _readInt(rows.first, 'total'),
      done: _readInt(rows.first, 'done'),
    );
  }

  Future<void> addTask({
    required String missionId,
    required String title,
    String notes = '',
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await _ensureChecklistEditable(txn: txn, missionId: missionId);

      final countRows = await txn.rawQuery(
        'SELECT COUNT(*) AS total FROM mission_tasks WHERE mission_id = ?;',
        [missionId],
      );
      final sortOrder = _readInt(countRows.first, 'total') + 1;

      await txn.update(
        'missions',
        {
          'is_compound': 1,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [missionId],
      );

      await txn.insert(
        'mission_tasks',
        {
          'id': IdGenerator.create('mission_task'),
          'mission_id': missionId,
          'title': title.trim(),
          'notes': notes.trim(),
          'is_done': 0,
          'sort_order': sortOrder,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    String notes = '',
  }) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await _ensureChecklistEditable(txn: txn, taskId: taskId);
      await txn.update(
        'mission_tasks',
        {
          'title': title.trim(),
          'notes': notes.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );
    });
  }

  Future<void> toggleTask({
    required String taskId,
    required bool isDone,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await _ensureChecklistEditable(txn: txn, taskId: taskId);
      await txn.update(
        'mission_tasks',
        {
          'is_done': isDone ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );
    });
  }

  Future<void> deleteTask(String taskId) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await _ensureChecklistEditable(txn: txn, taskId: taskId);
      await txn.delete(
        'mission_tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );
    });
  }

  Future<void> clearCompletedState(String missionId) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'mission_tasks',
      {
        'is_done': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'mission_id = ?',
      whereArgs: [missionId],
    );
  }

  Future<double> getCompletionPercent(String missionId) async {
    final stats = await getStats(missionId);
    return stats.progress;
  }


  Future<void> _ensureChecklistEditable({
    required DatabaseExecutor txn,
    String? missionId,
    String? taskId,
  }) async {
    var resolvedMissionId = missionId;

    if (resolvedMissionId == null) {
      final taskRows = await txn.query(
        'mission_tasks',
        columns: ['mission_id'],
        where: 'id = ?',
        whereArgs: [taskId],
        limit: 1,
      );

      if (taskRows.isEmpty) {
        throw StateError('Subtarefa não encontrada.');
      }

      resolvedMissionId = taskRows.first['mission_id']?.toString();
    }

    if (resolvedMissionId == null || resolvedMissionId.isEmpty) {
      throw StateError('Missão não encontrada para esta subtarefa.');
    }

    final missionRows = await txn.query(
      'missions',
      columns: ['type'],
      where: 'id = ?',
      whereArgs: [resolvedMissionId],
      limit: 1,
    );

    if (missionRows.isEmpty) {
      throw StateError('Missão não encontrada.');
    }

    final missionType = missionRows.first['type']?.toString() ?? 'daily';
    final range = PeriodUtils.rangeForMissionType(missionType, DateTime.now());
    final completionRows = await txn.query(
      'mission_completions',
      columns: ['id'],
      where: 'mission_id = ? AND completed_on >= ? AND completed_on < ?',
      whereArgs: [resolvedMissionId, range.startIso, range.endIso],
      limit: 1,
    );

    if (completionRows.isNotEmpty) {
      throw StateError(
        'Checklist bloqueado: desfaça a conclusão da missão antes de alterar subtarefas.',
      );
    }
  }

  int _readInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
