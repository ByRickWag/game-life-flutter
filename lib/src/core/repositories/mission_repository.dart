import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/game_models.dart';
import '../services/reward_service.dart';
import '../services/progression_service.dart';
import '../services/area_progression_service.dart';
import '../utils/id_generator.dart';
import '../utils/period_utils.dart';
import 'achievement_repository.dart';

class CreateMissionInput {
  const CreateMissionInput({
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.areaId,
    required this.attributeIds,
    required this.xpReward,
    this.isCompound = false,
    this.notes = '',
  });

  final String title;
  final String description;
  final String type;
  final String difficulty;
  final String? areaId;
  final List<String> attributeIds;
  final int xpReward;
  final bool isCompound;
  final String notes;

  String? get primaryAttributeId => attributeIds.isEmpty ? null : attributeIds.first;
}

class CompleteMissionResult {
  const CompleteMissionResult({
    required this.completed,
    required this.message,
    required this.xpGained,
    required this.coinsGained,
  });

  final bool completed;
  final String message;
  final int xpGained;
  final int coinsGained;
}


class MissionTaskStats {
  const MissionTaskStats({required this.total, required this.done});

  final int total;
  final int done;

  int get pending => (total - done).clamp(0, total).toInt();
  double get progress => total <= 0 ? 0 : (done / total).clamp(0, 1).toDouble();
  bool get allDone => total > 0 && done >= total;
}

class MissionRepository {
  Future<List<Mission>> getActiveMissions() async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT
        missions.*,
        areas.name AS area_name,
        attributes.name AS attribute_name
      FROM missions
      LEFT JOIN areas ON areas.id = missions.area_id
      LEFT JOIN attributes ON attributes.id = missions.attribute_id
      WHERE missions.is_active = 1
      ORDER BY
        CASE missions.type
          WHEN 'daily' THEN 1
          WHEN 'weekly' THEN 2
          WHEN 'monthly' THEN 3
          WHEN 'special' THEN 4
          ELSE 5
        END,
        missions.created_at DESC;
    ''');

    return rows.map(Mission.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> getAreas() async {
    final db = await AppDatabase.instance.database;
    return db.query('areas', orderBy: 'sort_order ASC');
  }

  Future<List<Map<String, Object?>>> getAttributes() async {
    final db = await AppDatabase.instance.database;
    return db.query('attributes', orderBy: 'sort_order ASC');
  }

  Future<List<String>> getAttributeIdsForMission(String missionId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'item_attribute_links',
      columns: ['attribute_id'],
      where: 'item_type = ? AND item_id = ?',
      whereArgs: ['mission', missionId],
      orderBy: 'is_primary DESC, weight DESC, created_at ASC',
    );

    return rows
        .map((row) => row['attribute_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<Map<String, bool>> getCurrentPeriodCompletionMap(
    List<Mission> missions,
  ) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final result = <String, bool>{};

    for (final mission in missions) {
      final range = PeriodUtils.rangeForMissionType(mission.type, now);
      final rows = await db.query(
        'mission_completions',
        columns: ['id'],
        where: 'mission_id = ? AND completed_on >= ? AND completed_on < ?',
        whereArgs: [mission.id, range.startIso, range.endIso],
        limit: 1,
      );
      result[mission.id] = rows.isNotEmpty;
    }

    return result;
  }

  Future<int> getMissionXpCap({
    required String type,
    required String difficulty,
  }) async {
    final db = await AppDatabase.instance.database;
    return RewardService(db).missionXpCapFromSettings(
      type: type,
      difficulty: difficulty,
    );
  }

  Future<MissionReward> previewReward({
    required String type,
    required String difficulty,
  }) async {
    final db = await AppDatabase.instance.database;
    return RewardService(db).calculateMissionReward(
      type: type,
      difficulty: difficulty,
    );
  }

  Future<void> createMission(CreateMissionInput input) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final missionId = IdGenerator.create('mission');
    final attributeIds = _normalizeAttributeIds(input.attributeIds);
    final reward = await RewardService(db).calculateMissionReward(
      type: input.type,
      difficulty: input.difficulty,
    );
    final xpCap = await RewardService(db).missionXpCapFromSettings(
      type: input.type,
      difficulty: input.difficulty,
    );
    final xpReward = RewardService.clampXpToCap(
      value: input.xpReward,
      cap: xpCap,
    );

    await db.transaction((txn) async {
      await txn.insert(
        'missions',
        {
          'id': missionId,
          'title': input.title.trim(),
          'description': input.description.trim(),
          'type': input.type,
          'difficulty': input.difficulty,
          'area_id': input.areaId,
          'attribute_id': attributeIds.isEmpty ? null : attributeIds.first,
          'xp_reward': xpReward,
          'coins_reward': reward.coins,
          'is_active': 1,
          'is_compound': input.isCompound ? 1 : 0,
          'notes': input.notes.trim(),
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _replaceAttributeLinks(
        txn: txn,
        itemType: 'mission',
        itemId: missionId,
        attributeIds: attributeIds,
        nowIso: now,
      );
    });
  }

  Future<void> updateMission({
    required String missionId,
    required CreateMissionInput input,
    bool deleteTasksWhenConvertingToSimple = false,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final attributeIds = _normalizeAttributeIds(input.attributeIds);
    final reward = await RewardService(db).calculateMissionReward(
      type: input.type,
      difficulty: input.difficulty,
    );
    final xpCap = await RewardService(db).missionXpCapFromSettings(
      type: input.type,
      difficulty: input.difficulty,
    );
    final xpReward = RewardService.clampXpToCap(
      value: input.xpReward,
      cap: xpCap,
    );

    await db.transaction((txn) async {
      final taskStats = await _getMissionTaskStats(txn, missionId);
      if (!input.isCompound && taskStats.total > 0) {
        if (!deleteTasksWhenConvertingToSimple) {
          throw StateError(
            'Esta missão possui subtarefas. Confirme a remoção do checklist antes de convertê-la para simples.',
          );
        }

        await txn.delete(
          'mission_tasks',
          where: 'mission_id = ?',
          whereArgs: [missionId],
        );
      }

      await txn.update(
        'missions',
        {
          'title': input.title.trim(),
          'description': input.description.trim(),
          'type': input.type,
          'difficulty': input.difficulty,
          'area_id': input.areaId,
          'attribute_id': attributeIds.isEmpty ? null : attributeIds.first,
          'xp_reward': xpReward,
          'coins_reward': reward.coins,
          'is_compound': input.isCompound ? 1 : 0,
          'notes': input.notes.trim(),
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [missionId],
      );

      await _replaceAttributeLinks(
        txn: txn,
        itemType: 'mission',
        itemId: missionId,
        attributeIds: attributeIds,
        nowIso: now,
      );

      await txn.insert(
        'history_events',
        {
          'id': IdGenerator.create('history'),
          'title': 'Missão editada: ${input.title.trim()}',
          'description': 'Título, descrição, recompensa ou atributos foram ajustados.',
          'type': 'mission_updated',
          'xp_delta': 0,
          'coins_delta': 0,
          'occurred_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  Future<CompleteMissionResult> completeMission(Mission mission) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final range = PeriodUtils.rangeForMissionType(mission.type, now);

    final existing = await db.query(
      'mission_completions',
      where: 'mission_id = ? AND completed_on >= ? AND completed_on < ?',
      whereArgs: [mission.id, range.startIso, range.endIso],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return CompleteMissionResult(
        completed: false,
        message: _duplicateMessage(mission.type),
        xpGained: 0,
        coinsGained: 0,
      );
    }

    final stats = await getMissionTaskStats(mission.id);
    final shouldValidateChecklist = mission.isCompound || stats.total > 0;

    if (shouldValidateChecklist) {
      if (stats.total == 0) {
        return const CompleteMissionResult(
          completed: false,
          message: 'Adicione pelo menos uma subtarefa antes de concluir esta missão composta.',
          xpGained: 0,
          coinsGained: 0,
        );
      }
      if (!stats.allDone) {
        return CompleteMissionResult(
          completed: false,
          message: 'Checklist incompleto: ${stats.done}/${stats.total} subtarefas concluídas.',
          xpGained: 0,
          coinsGained: 0,
        );
      }
    }

    await db.transaction((txn) async {
      await txn.insert(
        'mission_completions',
        {
          'id': IdGenerator.create('completion'),
          'mission_id': mission.id,
          'completed_on': nowIso,
          'xp_gained': mission.xpReward,
          'coins_gained': mission.coinsReward,
          'notes': null,
          'created_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      final heroRows = await txn.query(
        'hero_profiles',
        where: 'id = ?',
        whereArgs: ['main_hero'],
        limit: 1,
      );

      if (heroRows.isNotEmpty) {
        final hero = heroRows.first;
        final currentXp = _readInt(hero, 'xp');
        final currentCoins = _readInt(hero, 'coins');
        final newXp = currentXp + mission.xpReward;
        final newCoins = currentCoins + mission.coinsReward;
        final newLevel = await ProgressionService.levelFromXp(txn, newXp);

        await txn.update(
          'hero_profiles',
          {
            'xp': newXp,
            'coins': newCoins,
            'level': newLevel,
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: ['main_hero'],
        );
      }

      await _applyAttributeRewardsForItem(
        txn: txn,
        itemType: 'mission',
        itemId: mission.id,
        fallbackAttributeId: mission.attributeId,
        xp: mission.xpReward,
        nowIso: nowIso,
      );

      await AreaProgressionService.applyAreaXp(
        executor: txn,
        areaId: mission.areaId,
        xp: mission.xpReward,
        nowIso: nowIso,
      );

      await txn.insert(
        'history_events',
        {
          'id': IdGenerator.create('history'),
          'title': 'Missão concluída: ${mission.title}',
          'description':
              '+${mission.xpReward} XP, +${mission.coinsReward} coins em ${mission.typeLabel}.',
          'type': 'mission_completion',
          'xp_delta': mission.xpReward,
          'coins_delta': mission.coinsReward,
          'occurred_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });

    await AchievementRepository().refreshAutomaticAchievements();

    return CompleteMissionResult(
      completed: true,
      message:
          'Missão concluída! +${mission.xpReward} XP e +${mission.coinsReward} coins.',
      xpGained: mission.xpReward,
      coinsGained: mission.coinsReward,
    );
  }

  Future<CompleteMissionResult> undoMissionCompletion(Mission mission) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final range = PeriodUtils.rangeForMissionType(mission.type, now);

    final rows = await db.query(
      'mission_completions',
      where: 'mission_id = ? AND completed_on >= ? AND completed_on < ?',
      whereArgs: [mission.id, range.startIso, range.endIso],
      orderBy: 'completed_on DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return const CompleteMissionResult(
        completed: false,
        message: 'Essa missão não está concluída neste período.',
        xpGained: 0,
        coinsGained: 0,
      );
    }

    final completion = rows.first;
    final xpToRemove = _readInt(completion, 'xp_gained');
    final coinsToRemove = _readInt(completion, 'coins_gained');

    await db.transaction((txn) async {
      await txn.delete(
        'mission_completions',
        where: 'id = ?',
        whereArgs: [completion['id']],
      );

      final heroRows = await txn.query(
        'hero_profiles',
        where: 'id = ?',
        whereArgs: ['main_hero'],
        limit: 1,
      );

      if (heroRows.isNotEmpty) {
        final hero = heroRows.first;
        final currentXp = _readInt(hero, 'xp');
        final currentCoins = _readInt(hero, 'coins');
        final newXp = (currentXp - xpToRemove).clamp(0, 1 << 31).toInt();
        final newCoins = (currentCoins - coinsToRemove).clamp(0, 1 << 31).toInt();

        await txn.update(
          'hero_profiles',
          {
            'xp': newXp,
            'coins': newCoins,
            'level': await ProgressionService.levelFromXp(txn, newXp),
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: ['main_hero'],
        );
      }

      await _applyAttributeRewardsForItem(
        txn: txn,
        itemType: 'mission',
        itemId: mission.id,
        fallbackAttributeId: mission.attributeId,
        xp: -xpToRemove,
        nowIso: nowIso,
      );

      await AreaProgressionService.applyAreaXp(
        executor: txn,
        areaId: mission.areaId,
        xp: -xpToRemove,
        nowIso: nowIso,
      );

      await txn.insert(
        'history_events',
        {
          'id': IdGenerator.create('history'),
          'title': 'Conclusão desfeita: ${mission.title}',
          'description': '-$xpToRemove XP, -$coinsToRemove coins removidos por correção manual.',
          'type': 'mission_completion_undone',
          'xp_delta': -xpToRemove,
          'coins_delta': -coinsToRemove,
          'occurred_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });

    return CompleteMissionResult(
      completed: true,
      message: 'Conclusão desfeita. -$xpToRemove XP e -$coinsToRemove coins.',
      xpGained: -xpToRemove,
      coinsGained: -coinsToRemove,
    );
  }


  Future<MissionTaskStats> getMissionTaskStats(String missionId) async {
    final db = await AppDatabase.instance.database;
    return _getMissionTaskStats(db, missionId);
  }


  Future<MissionTaskStats> _getMissionTaskStats(
    DatabaseExecutor executor,
    String missionId,
  ) async {
    final rows = await executor.rawQuery('''
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

  Future<void> deactivateMission(String missionId) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'missions',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [missionId],
    );
  }

  String _duplicateMessage(String type) {
    return switch (type) {
      'daily' => 'Essa missão diária já foi concluída hoje.',
      'weekly' => 'Essa missão semanal já foi concluída nesta semana.',
      'monthly' => 'Essa missão mensal já foi concluída neste mês.',
      'special' => 'Essa missão especial já foi concluída.',
      _ => 'Essa missão já foi concluída neste período.',
    };
  }



  List<String> _normalizeAttributeIds(List<String> ids) {
    final seen = <String>{};
    final result = <String>[];

    for (final id in ids) {
      final trimmed = id.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      result.add(trimmed);
      if (result.length >= 3) break;
    }

    return result;
  }

  List<int> _weightsForCount(int count) {
    return switch (count) {
      1 => [100],
      2 => [70, 30],
      _ => [50, 30, 20],
    };
  }

  Future<void> _replaceAttributeLinks({
    required Transaction txn,
    required String itemType,
    required String itemId,
    required List<String> attributeIds,
    required String nowIso,
  }) async {
    final normalized = _normalizeAttributeIds(attributeIds);
    final weights = _weightsForCount(normalized.length);

    await txn.delete(
      'item_attribute_links',
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [itemType, itemId],
    );

    for (var index = 0; index < normalized.length; index++) {
      await txn.insert(
        'item_attribute_links',
        {
          'id': IdGenerator.create('attr_link'),
          'item_type': itemType,
          'item_id': itemId,
          'attribute_id': normalized[index],
          'weight': weights[index],
          'is_primary': index == 0 ? 1 : 0,
          'created_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyAttributeRewardsForItem({
    required Transaction txn,
    required String itemType,
    required String itemId,
    required String? fallbackAttributeId,
    required int xp,
    required String nowIso,
  }) async {
    final rows = await txn.rawQuery('''
      SELECT attribute_id, weight
      FROM item_attribute_links
      WHERE item_type = ? AND item_id = ?
      ORDER BY is_primary DESC, weight DESC, created_at ASC;
    ''', [itemType, itemId]);

    if (rows.isEmpty) {
      if (fallbackAttributeId != null && fallbackAttributeId.isNotEmpty) {
        await _applyAttributeReward(
          txn: txn,
          attributeId: fallbackAttributeId,
          xp: xp,
          nowIso: nowIso,
        );
      }
      return;
    }

    final totalWeight = rows.fold<int>(
      0,
      (sum, row) => sum + _readInt(row, 'weight'),
    );

    if (totalWeight <= 0) return;

    final sign = xp < 0 ? -1 : 1;
    final absoluteXp = xp.abs();
    var remainingXp = absoluteXp;

    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final attributeId = row['attribute_id']?.toString() ?? '';
      if (attributeId.isEmpty) continue;

      final share = index == rows.length - 1
          ? remainingXp
          : ((absoluteXp * _readInt(row, 'weight')) / totalWeight)
              .round()
              .clamp(0, remainingXp)
              .toInt();
      remainingXp -= share;

      if (share <= 0) continue;
      await _applyAttributeReward(
        txn: txn,
        attributeId: attributeId,
        xp: share * sign,
        nowIso: nowIso,
      );
    }
  }

  Future<void> _applyAttributeReward({
    required Transaction txn,
    required String attributeId,
    required int xp,
    required String nowIso,
  }) async {
    final attributeRows = await txn.query(
      'hero_attributes',
      where: 'attribute_id = ?',
      whereArgs: [attributeId],
      limit: 1,
    );

    if (attributeRows.isEmpty) return;

    final attribute = attributeRows.first;
    final currentAttributeXp = _readInt(attribute, 'xp');
    final newAttributeXp = (currentAttributeXp + xp).clamp(0, 1 << 31).toInt();
    final newPoints = newAttributeXp ~/ 100;

    await txn.update(
      'hero_attributes',
      {
        'xp': newAttributeXp,
        'points': newPoints,
        'updated_at': nowIso,
      },
      where: 'attribute_id = ?',
      whereArgs: [attributeId],
    );
  }

  int _readInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
