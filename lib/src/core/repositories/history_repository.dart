import '../database/app_database.dart';
import '../models/game_models.dart';

class HistoryFilter {
  const HistoryFilter({required this.id, required this.label});

  final String id;
  final String label;
}

class HistoryRepository {
  static const filters = [
    HistoryFilter(id: 'all', label: 'Tudo'),
    HistoryFilter(id: 'missions', label: 'Missões'),
    HistoryFilter(id: 'objectives', label: 'Objetivos'),
    HistoryFilter(id: 'sessions', label: 'Sessões'),
    HistoryFilter(id: 'projects', label: 'Projetos'),
    HistoryFilter(id: 'rewards', label: 'Recompensas'),
    HistoryFilter(id: 'system', label: 'Sistema'),
  ];

  Future<List<HistoryEvent>> getEvents({
    String filter = 'all',
    int limit = 80,
  }) async {
    final db = await AppDatabase.instance.database;
    final safeLimit = limit.clamp(10, 200).toInt();
    final where = _whereForFilter(filter);

    final rows = await db.query(
      'history_events',
      where: where.sql,
      whereArgs: where.args,
      orderBy: 'occurred_at DESC',
      limit: safeLimit,
    );

    return rows.map(HistoryEvent.fromMap).toList();
  }

  Future<HistoryStats> getStats() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) AS total_events,
        COALESCE(SUM(xp_delta), 0) AS total_xp,
        COALESCE(SUM(coins_delta), 0) AS total_coins,
        COALESCE(SUM(CASE WHEN type = 'mission_completion' THEN 1 ELSE 0 END), 0) AS mission_events,
        COALESCE(SUM(CASE WHEN type IN ('objective_completion', 'objective_progress') THEN 1 ELSE 0 END), 0) AS objective_events,
        COALESCE(SUM(CASE WHEN type = 'manual_session' THEN 1 ELSE 0 END), 0) AS session_events,
        COALESCE(SUM(CASE WHEN type = 'project_completion' THEN 1 ELSE 0 END), 0) AS project_events,
        COALESCE(MIN(occurred_at), '') AS first_event_at,
        COALESCE(MAX(occurred_at), '') AS last_event_at
      FROM history_events;
    ''');

    if (rows.isEmpty) return HistoryStats.empty();
    return HistoryStats.fromMap(rows.first);
  }

  Future<List<HistoryEvent>> getRecentRewardEvents({int limit = 8}) async {
    final db = await AppDatabase.instance.database;
    final safeLimit = limit.clamp(3, 30).toInt();
    final rows = await db.query(
      'history_events',
      where: 'xp_delta != 0 OR coins_delta != 0',
      orderBy: 'occurred_at DESC',
      limit: safeLimit,
    );

    return rows.map(HistoryEvent.fromMap).toList();
  }

  _HistoryWhere _whereForFilter(String filter) {
    return switch (filter) {
      'missions' => const _HistoryWhere(
          sql: 'type = ?',
          args: ['mission_completion'],
        ),
      'objectives' => const _HistoryWhere(
          sql: 'type IN (?, ?)',
          args: ['objective_completion', 'objective_progress'],
        ),
      'sessions' => const _HistoryWhere(
          sql: 'type = ?',
          args: ['manual_session'],
        ),
      'projects' => const _HistoryWhere(
          sql: 'type = ?',
          args: ['project_completion'],
        ),
      'rewards' => const _HistoryWhere(
          sql: 'xp_delta != 0 OR coins_delta != 0',
          args: [],
        ),
      'system' => const _HistoryWhere(
          sql: 'type = ?',
          args: ['system'],
        ),
      _ => const _HistoryWhere(sql: null, args: []),
    };
  }
}

class _HistoryWhere {
  const _HistoryWhere({required this.sql, required this.args});

  final String? sql;
  final List<Object?> args;
}
