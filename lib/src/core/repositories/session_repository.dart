import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/game_models.dart';
import '../services/reward_service.dart';
import '../services/progression_service.dart';
import '../services/area_progression_service.dart';
import '../utils/id_generator.dart';
import 'achievement_repository.dart';

class CreateSessionInput {
  const CreateSessionInput({
    required this.title,
    required this.sessionType,
    required this.areaId,
    required this.attributeIds,
    required this.durationMinutes,
    required this.notes,
  });

  final String title;
  final String sessionType;
  final String? areaId;
  final List<String> attributeIds;
  final int durationMinutes;
  final String notes;

  String? get primaryAttributeId => attributeIds.isEmpty ? null : attributeIds.first;
}

class CreateSessionResult {
  const CreateSessionResult({
    required this.saved,
    required this.message,
    required this.xpGained,
    required this.coinsGained,
  });

  final bool saved;
  final String message;
  final int xpGained;
  final int coinsGained;
}

class SessionRepository {
  Future<List<ManualSession>> getRecentSessions({int limit = 40}) async {
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery('''
      SELECT
        sessions.*,
        COALESCE(sessions.session_type, 'general') AS session_type,
        areas.name AS area_name,
        attributes.name AS attribute_name
      FROM sessions
      LEFT JOIN areas ON areas.id = sessions.area_id
      LEFT JOIN attributes ON attributes.id = sessions.attribute_id
      ORDER BY sessions.created_at DESC
      LIMIT ?;
    ''', [limit]);

    return rows.map(ManualSession.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> getAreas() async {
    final db = await AppDatabase.instance.database;
    return db.query('areas', orderBy: 'sort_order ASC');
  }

  Future<List<Map<String, Object?>>> getAttributes() async {
    final db = await AppDatabase.instance.database;
    return db.query('attributes', orderBy: 'sort_order ASC');
  }

  Future<SessionReward> previewReward({required int durationMinutes}) async {
    final db = await AppDatabase.instance.database;
    return RewardService(db).calculateSessionReward(
      durationMinutes: durationMinutes,
    );
  }

  Future<CreateSessionResult> createSession(CreateSessionInput input) async {
    if (input.title.trim().isEmpty) {
      return const CreateSessionResult(
        saved: false,
        message: 'Digite um título para a sessão.',
        xpGained: 0,
        coinsGained: 0,
      );
    }

    if (input.durationMinutes <= 0) {
      return const CreateSessionResult(
        saved: false,
        message: 'Digite uma duração maior que zero.',
        xpGained: 0,
        coinsGained: 0,
      );
    }

    final db = await AppDatabase.instance.database;
    final nowIso = DateTime.now().toIso8601String();
    final sessionId = IdGenerator.create('session');
    final attributeIds = _normalizeAttributeIds(input.attributeIds);
    final reward = await RewardService(db).calculateSessionReward(
      durationMinutes: input.durationMinutes,
    );

    await db.transaction((txn) async {
      await txn.insert(
        'sessions',
        {
          'id': sessionId,
          'title': input.title.trim(),
          'session_type': input.sessionType,
          'area_id': input.areaId,
          'attribute_id': attributeIds.isEmpty ? null : attributeIds.first,
          'duration_minutes': input.durationMinutes,
          'notes': input.notes.trim().isEmpty ? null : input.notes.trim(),
          'xp_gained': reward.xp,
          'coins_gained': reward.coins,
          'started_at': null,
          'ended_at': null,
          'created_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _replaceAttributeLinks(
        txn: txn,
        itemType: 'session',
        itemId: sessionId,
        attributeIds: attributeIds,
        nowIso: nowIso,
      );

      await _applyHeroReward(
        txn: txn,
        xp: reward.xp,
        coins: reward.coins,
        nowIso: nowIso,
      );

      await _applyAttributeRewardsForItem(
        txn: txn,
        itemType: 'session',
        itemId: sessionId,
        fallbackAttributeId: attributeIds.isEmpty ? null : attributeIds.first,
        xp: reward.xp,
        nowIso: nowIso,
      );

      await AreaProgressionService.applyAreaXp(
        executor: txn,
        areaId: input.areaId,
        xp: reward.xp,
        nowIso: nowIso,
      );

      await txn.insert(
        'history_events',
        {
          'id': IdGenerator.create('history'),
          'title': 'Sessão registrada: ${input.title.trim()}',
          'description':
              '${_durationLabel(input.durationMinutes)} de ${_typeLabel(input.sessionType)}. +${reward.xp} XP, +${reward.coins} coins.',
          'type': 'manual_session',
          'xp_delta': reward.xp,
          'coins_delta': reward.coins,
          'occurred_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });

    await AchievementRepository().refreshAutomaticAchievements();

    return CreateSessionResult(
      saved: true,
      message: reward.reachedCap
          ? 'Sessão registrada! +${reward.xp} XP e +${reward.coins} coins. Teto de XP da sessão atingido.'
          : 'Sessão registrada! +${reward.xp} XP e +${reward.coins} coins.',
      xpGained: reward.xp,
      coinsGained: reward.coins,
    );
  }

  Future<void> deleteSession(ManualSession session) async {
    final db = await AppDatabase.instance.database;
    final nowIso = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await _reverseHeroReward(
        txn: txn,
        xp: session.xpGained,
        coins: session.coinsGained,
        nowIso: nowIso,
      );

      await _reverseAttributeRewardsForItem(
        txn: txn,
        itemType: 'session',
        itemId: session.id,
        fallbackAttributeId: session.attributeId,
        xp: session.xpGained,
        nowIso: nowIso,
      );

      await AreaProgressionService.applyAreaXp(
        executor: txn,
        areaId: session.areaId,
        xp: -session.xpGained,
        nowIso: nowIso,
      );

      await txn.delete(
        'item_attribute_links',
        where: 'item_type = ? AND item_id = ?',
        whereArgs: ['session', session.id],
      );

      await txn.delete(
        'sessions',
        where: 'id = ?',
        whereArgs: [session.id],
      );

      await txn.insert(
        'history_events',
        {
          'id': IdGenerator.create('history'),
          'title': 'Sessão excluída: ${session.title}',
          'description':
              'Correção manual. -${session.xpGained} XP, -${session.coinsGained} coins revertidos.',
          'type': 'session_deleted',
          'xp_delta': -session.xpGained,
          'coins_delta': -session.coinsGained,
          'occurred_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
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


  Future<void> _reverseHeroReward({
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
    final newXp = (currentXp - xp).clamp(0, 1 << 31).toInt();
    final newCoins = (currentCoins - coins).clamp(0, 1 << 31).toInt();

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


  Future<void> _reverseAttributeRewardsForItem({
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
        await _subtractAttributeReward(
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
      await _subtractAttributeReward(
        txn: txn,
        attributeId: attributeId,
        xp: share,
        nowIso: nowIso,
      );
    }
  }

  Future<void> _subtractAttributeReward({
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
    final newAttributeXp = (currentAttributeXp - xp).clamp(0, 1 << 31).toInt();
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


  String _typeLabel(String type) {
    return switch (type) {
      'training' => 'treino',
      'study' => 'estudo',
      'devotional' => 'devocional',
      'programming' => 'programação',
      'project' => 'projeto',
      'organization' => 'organização',
      'reading' => 'leitura',
      'finance' => 'finanças',
      _ => 'sessão geral',
    };
  }

  String _durationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;

    if (hours <= 0) return '${minutes}min';
    if (rest == 0) return '${hours}h';
    return '${hours}h ${rest}min';
  }
}
