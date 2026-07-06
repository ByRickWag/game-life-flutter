import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/game_models.dart';
import '../services/reward_service.dart';
import '../services/progression_service.dart';
import '../services/area_progression_service.dart';
import '../utils/id_generator.dart';
import 'achievement_repository.dart';

class CreateObjectiveInput {
  const CreateObjectiveInput({
    required this.title,
    required this.description,
    required this.areaId,
    required this.attributeIds,
    required this.targetValue,
    required this.unit,
    required this.difficulty,
    required this.xpReward,
  });

  final String title;
  final String description;
  final String? areaId;
  final List<String> attributeIds;
  final double targetValue;
  final String unit;
  final String difficulty;
  final int xpReward;

  String? get primaryAttributeId => attributeIds.isEmpty ? null : attributeIds.first;
}

class AddObjectiveProgressResult {
  const AddObjectiveProgressResult({
    required this.saved,
    required this.completedNow,
    required this.message,
    required this.xpGained,
    required this.coinsGained,
  });

  final bool saved;
  final bool completedNow;
  final String message;
  final int xpGained;
  final int coinsGained;
}

class ObjectiveRepository {
  Future<List<Objective>> getActiveObjectives() async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT
        objectives.*,
        areas.name AS area_name,
        attributes.name AS attribute_name
      FROM objectives
      LEFT JOIN areas ON areas.id = objectives.area_id
      LEFT JOIN attributes ON attributes.id = objectives.attribute_id
      WHERE objectives.status = 'active'
      ORDER BY objectives.created_at DESC;
    ''');

    return rows.map(Objective.fromMap).toList();
  }

  Future<List<Objective>> getCompletedObjectives({int limit = 12}) async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT
        objectives.*,
        areas.name AS area_name,
        attributes.name AS attribute_name
      FROM objectives
      LEFT JOIN areas ON areas.id = objectives.area_id
      LEFT JOIN attributes ON attributes.id = objectives.attribute_id
      WHERE objectives.status = 'completed'
      ORDER BY objectives.updated_at DESC
      LIMIT ?;
    ''', [limit]);

    return rows.map(Objective.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> getAreas() async {
    final db = await AppDatabase.instance.database;
    return db.query('areas', orderBy: 'sort_order ASC');
  }

  Future<List<Map<String, Object?>>> getAttributes() async {
    final db = await AppDatabase.instance.database;
    return db.query('attributes', orderBy: 'sort_order ASC');
  }

  Future<int> getObjectiveXpCap({required String difficulty}) async {
    final db = await AppDatabase.instance.database;
    return RewardService(db).objectiveXpCapFromSettings(difficulty: difficulty);
  }

  Future<ObjectiveReward> previewReward({required String difficulty}) async {
    final db = await AppDatabase.instance.database;
    return RewardService(db).calculateObjectiveReward(difficulty: difficulty);
  }

  Future<void> createObjective(CreateObjectiveInput input) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final objectiveId = IdGenerator.create('objective');
    final attributeIds = _normalizeAttributeIds(input.attributeIds);
    final reward = await RewardService(db).calculateObjectiveReward(
      difficulty: input.difficulty,
    );
    final xpCap = await RewardService(db).objectiveXpCapFromSettings(
      difficulty: input.difficulty,
    );
    final xpReward = RewardService.clampXpToCap(
      value: input.xpReward,
      cap: xpCap,
    );

    await db.transaction((txn) async {
      await txn.insert(
        'objectives',
        {
          'id': objectiveId,
          'title': input.title.trim(),
          'description': input.description.trim(),
          'area_id': input.areaId,
          'attribute_id': attributeIds.isEmpty ? null : attributeIds.first,
          'target_value': input.targetValue,
          'current_value': 0.0,
          'unit': input.unit.trim(),
          'xp_reward': xpReward,
          'coins_reward': reward.coins,
          'status': 'active',
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _replaceAttributeLinks(
        txn: txn,
        itemType: 'objective',
        itemId: objectiveId,
        attributeIds: attributeIds,
        nowIso: now,
      );
    });
  }

  Future<AddObjectiveProgressResult> addProgress({
    required Objective objective,
    required double valueDelta,
    required String notes,
  }) async {
    if (valueDelta <= 0) {
      return const AddObjectiveProgressResult(
        saved: false,
        completedNow: false,
        message: 'Digite um progresso maior que zero.',
        xpGained: 0,
        coinsGained: 0,
      );
    }

    final db = await AppDatabase.instance.database;
    final nowIso = DateTime.now().toIso8601String();

    var completedNow = false;
    var xpGained = 0;
    var coinsGained = 0;
    var message = 'Progresso registrado.';

    await db.transaction((txn) async {
      final objectiveRows = await txn.query(
        'objectives',
        where: 'id = ?',
        whereArgs: [objective.id],
        limit: 1,
      );

      if (objectiveRows.isEmpty) {
        throw StateError('Objetivo não encontrado.');
      }

      final currentObjective = Objective.fromMap({
        ...objectiveRows.first,
        'area_name': objective.areaName,
        'attribute_name': objective.attributeName,
      });

      if (currentObjective.status != 'active') {
        message = 'Esse objetivo não está ativo.';
        return;
      }

      final unclampedValue = currentObjective.currentValue + valueDelta;
      final newValue = unclampedValue > currentObjective.targetValue
          ? currentObjective.targetValue
          : unclampedValue;
      final willComplete = newValue >= currentObjective.targetValue;
      final newStatus = willComplete ? 'completed' : 'active';

      await txn.insert(
        'objective_progress_entries',
        {
          'id': IdGenerator.create('objective_progress'),
          'objective_id': objective.id,
          'value_delta': valueDelta,
          'notes': notes.trim().isEmpty ? null : notes.trim(),
          'created_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await txn.update(
        'objectives',
        {
          'current_value': newValue,
          'status': newStatus,
          'updated_at': nowIso,
        },
        where: 'id = ?',
        whereArgs: [objective.id],
      );

      if (willComplete) {
        completedNow = true;
        xpGained = currentObjective.xpReward;
        coinsGained = currentObjective.coinsReward;

        await _applyHeroReward(
          txn: txn,
          xp: xpGained,
          coins: coinsGained,
          nowIso: nowIso,
        );

        await _applyAttributeRewardsForItem(
          txn: txn,
          itemType: 'objective',
          itemId: currentObjective.id,
          fallbackAttributeId: currentObjective.attributeId,
          xp: xpGained,
          nowIso: nowIso,
        );

        await AreaProgressionService.applyAreaXp(
          executor: txn,
          areaId: currentObjective.areaId,
          xp: xpGained,
          nowIso: nowIso,
        );

        await txn.insert(
          'history_events',
          {
            'id': IdGenerator.create('history'),
            'title': 'Objetivo concluído: ${currentObjective.title}',
            'description':
                '+$xpGained XP, +$coinsGained coins. Meta: ${currentObjective.progressText}.',
            'type': 'objective_completion',
            'xp_delta': xpGained,
            'coins_delta': coinsGained,
            'occurred_at': nowIso,
          },
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        message = 'Objetivo concluído! +$xpGained XP e +$coinsGained coins.';
      } else {
        await txn.insert(
          'history_events',
          {
            'id': IdGenerator.create('history'),
            'title': 'Progresso em objetivo: ${currentObjective.title}',
            'description':
                '+${formatNumber(valueDelta)} ${currentObjective.unit}. Total: ${formatNumber(newValue)} / ${formatNumber(currentObjective.targetValue)} ${currentObjective.unit}.',
            'type': 'objective_progress',
            'xp_delta': 0,
            'coins_delta': 0,
            'occurred_at': nowIso,
          },
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        message =
            'Progresso registrado: ${formatNumber(newValue)} / ${formatNumber(currentObjective.targetValue)} ${currentObjective.unit}.';
      }
    });

    if (completedNow) {
      await AchievementRepository().refreshAutomaticAchievements();
    }

    return AddObjectiveProgressResult(
      saved: true,
      completedNow: completedNow,
      message: message,
      xpGained: xpGained,
      coinsGained: coinsGained,
    );
  }

  Future<void> archiveObjective(String objectiveId) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'objectives',
      {
        'status': 'archived',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [objectiveId],
    );
  }

  Future<void> _applyHeroReward({
    required Transaction txn,
    required int xp,
    required int coins,
    required String nowIso,
  }) async {
    final heroRows = await txn.query(
      'hero_profiles',
      where: 'id = ?',
      whereArgs: ['main_hero'],
      limit: 1,
    );

    if (heroRows.isEmpty) return;

    final hero = heroRows.first;
    final currentXp = readInt(hero, 'xp');
    final currentCoins = readInt(hero, 'coins');
    final newXp = currentXp + xp;
    final newCoins = currentCoins + coins;

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
      (sum, row) => sum + readInt(row, 'weight'),
    );

    if (totalWeight <= 0) return;

    var remainingXp = xp;
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final attributeId = row['attribute_id']?.toString() ?? '';
      if (attributeId.isEmpty) continue;

      final share = index == rows.length - 1
          ? remainingXp
          : ((xp * readInt(row, 'weight')) / totalWeight)
              .round()
              .clamp(0, remainingXp)
              .toInt();
      remainingXp -= share;

      if (share <= 0) continue;
      await _applyAttributeReward(
        txn: txn,
        attributeId: attributeId,
        xp: share,
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
    final currentAttributeXp = readInt(attribute, 'xp');
    final newAttributeXp = currentAttributeXp + xp;
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

}
