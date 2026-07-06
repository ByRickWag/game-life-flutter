import 'package:sqflite/sqflite.dart';

/// Centraliza a evolução de áreas/domínios da vida.
///
/// Regra V4.3:
/// - toda área começa no nível 1;
/// - a cada 100 XP acumulados, a área ganha +1 ponto;
/// - valores negativos são aceitos para reversões, mas XP nunca fica abaixo de 0.
class AreaProgressionService {
  const AreaProgressionService._();

  static const int xpPerPoint = 100;

  static Future<void> ensureAreaRows(
    DatabaseExecutor executor, {
    String? nowIso,
  }) async {
    final now = nowIso ?? DateTime.now().toIso8601String();
    await executor.rawInsert('''
      INSERT OR IGNORE INTO hero_areas (id, area_id, points, xp, created_at, updated_at)
      SELECT 'hero_area_' || areas.id, areas.id, 0, 0, ?, ?
      FROM areas;
    ''', [now, now]);
  }

  static Future<void> applyAreaXp({
    required DatabaseExecutor executor,
    required String? areaId,
    required int xp,
    required String nowIso,
  }) async {
    final safeAreaId = areaId?.trim() ?? '';
    if (safeAreaId.isEmpty || xp == 0) return;

    await ensureAreaRows(executor, nowIso: nowIso);

    final rows = await executor.rawQuery(
      'SELECT xp FROM hero_areas WHERE area_id = ? LIMIT 1;',
      [safeAreaId],
    );

    if (rows.isEmpty) {
      final areaRows = await executor.rawQuery(
        'SELECT id FROM areas WHERE id = ? LIMIT 1;',
        [safeAreaId],
      );
      if (areaRows.isEmpty) return;

      await executor.rawInsert(
        '''
        INSERT OR IGNORE INTO hero_areas (id, area_id, points, xp, created_at, updated_at)
        VALUES (?, ?, 0, 0, ?, ?);
        ''',
        ['hero_area_$safeAreaId', safeAreaId, nowIso, nowIso],
      );
    }

    final currentRows = rows.isEmpty
        ? await executor.rawQuery(
            'SELECT xp FROM hero_areas WHERE area_id = ? LIMIT 1;',
            [safeAreaId],
          )
        : rows;

    final currentXp = currentRows.isEmpty ? 0 : _readInt(currentRows.first, 'xp');
    final newXp = (currentXp + xp).clamp(0, 1 << 31).toInt();

    await executor.rawUpdate(
      '''
      UPDATE hero_areas
      SET xp = ?,
          points = ?,
          updated_at = ?
      WHERE area_id = ?;
      ''',
      [newXp, newXp ~/ xpPerPoint, nowIso, safeAreaId],
    );
  }

  static int _readInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
