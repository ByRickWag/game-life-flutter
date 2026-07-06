import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/game_models.dart';
import '../utils/id_generator.dart';
import '../services/progression_service.dart';
import '../services/area_progression_service.dart';
import 'achievement_repository.dart';

class CreateHabitInput {
  const CreateHabitInput({
    required this.title,
    required this.description,
    required this.type,
    required this.frequency,
    required this.unit,
    required this.targetValue,
    required this.limitValue,
    required this.areaId,
    required this.attributeIds,
    required this.xpReward,
    required this.coinsReward,
  });

  final String title;
  final String description;
  final String type;
  final String frequency;
  final String unit;
  final double targetValue;
  final double limitValue;
  final String? areaId;
  final List<String> attributeIds;
  final int xpReward;
  final int coinsReward;

  String? get primaryAttributeId => attributeIds.isEmpty ? null : attributeIds.first;
}

class HabitLogResult {
  const HabitLogResult({
    required this.message,
    required this.xpGained,
    required this.coinsGained,
    required this.rewardApplied,
  });

  final String message;
  final int xpGained;
  final int coinsGained;
  final bool rewardApplied;
}

class HabitRepository {
  Future<List<HabitWithStats>> getActiveHabitsWithStats() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT habits.*, areas.name AS area_name, attributes.name AS attribute_name
      FROM habits
      LEFT JOIN areas ON areas.id = habits.area_id
      LEFT JOIN attributes ON attributes.id = habits.attribute_id
      WHERE habits.is_active = 1
      ORDER BY
        CASE habits.type
          WHEN 'build' THEN 1
          WHEN 'maintain' THEN 2
          WHEN 'reduce' THEN 3
          WHEN 'avoid' THEN 4
          ELSE 5
        END,
        habits.created_at DESC;
    ''');

    final habits = rows.map(Habit.fromMap).toList();
    final result = <HabitWithStats>[];
    for (final habit in habits) {
      result.add(HabitWithStats(habit: habit, stats: await getCurrentStats(habit)));
    }
    return result;
  }

  Future<Habit?> getHabitById(String habitId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT habits.*, areas.name AS area_name, attributes.name AS attribute_name
      FROM habits
      LEFT JOIN areas ON areas.id = habits.area_id
      LEFT JOIN attributes ON attributes.id = habits.attribute_id
      WHERE habits.id = ?
      LIMIT 1;
    ''', [habitId]);

    if (rows.isEmpty) return null;
    return Habit.fromMap(rows.first);
  }

  Future<List<Map<String, Object?>>> getAreas() async {
    final db = await AppDatabase.instance.database;
    return db.query('areas', orderBy: 'sort_order ASC');
  }

  Future<List<Map<String, Object?>>> getAttributes() async {
    final db = await AppDatabase.instance.database;
    return db.query('attributes', orderBy: 'sort_order ASC');
  }

  Future<List<String>> getAttributeIdsForHabit(String habitId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'item_attribute_links',
      columns: ['attribute_id'],
      where: 'item_type = ? AND item_id = ?',
      whereArgs: ['habit', habitId],
      orderBy: 'is_primary DESC, weight DESC, created_at ASC',
    );

    return rows
        .map((row) => row['attribute_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<void> createHabit(CreateHabitInput input) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final habitId = IdGenerator.create('habit');
    final attributeIds = _normalizeAttributeIds(input.attributeIds);

    _validateInput(input);

    await db.transaction((txn) async {
      await txn.insert(
        'habits',
        {
          'id': habitId,
          'title': input.title.trim(),
          'description': input.description.trim(),
          'type': input.type,
          'frequency': input.frequency,
          'unit': input.unit,
          'target_value': _safeTarget(input),
          'limit_value': _safeLimit(input),
          'area_id': input.areaId,
          'attribute_id': attributeIds.isEmpty ? null : attributeIds.first,
          'xp_reward': _clampReward(input.xpReward, 0, 50),
          'coins_reward': _clampReward(input.coinsReward, 0, 20),
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _replaceAttributeLinks(
        txn: txn,
        itemType: 'habit',
        itemId: habitId,
        attributeIds: attributeIds,
        nowIso: now,
      );

      await _insertHistory(
        txn,
        title: 'Hábito criado: ${input.title.trim()}',
        description: 'Novo hábito ${_typeLabel(input.type).toLowerCase()} configurado para o ritmo ${_frequencyLabel(input.frequency).toLowerCase()}.',
        type: 'habit_created',
        xpDelta: 0,
        coinsDelta: 0,
        nowIso: now,
      );
    });
  }

  Future<void> updateHabit({
    required String habitId,
    required CreateHabitInput input,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final attributeIds = _normalizeAttributeIds(input.attributeIds);

    _validateInput(input);

    await db.transaction((txn) async {
      await txn.update(
        'habits',
        {
          'title': input.title.trim(),
          'description': input.description.trim(),
          'type': input.type,
          'frequency': input.frequency,
          'unit': input.unit,
          'target_value': _safeTarget(input),
          'limit_value': _safeLimit(input),
          'area_id': input.areaId,
          'attribute_id': attributeIds.isEmpty ? null : attributeIds.first,
          'xp_reward': _clampReward(input.xpReward, 0, 50),
          'coins_reward': _clampReward(input.coinsReward, 0, 20),
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [habitId],
      );

      await _replaceAttributeLinks(
        txn: txn,
        itemType: 'habit',
        itemId: habitId,
        attributeIds: attributeIds,
        nowIso: now,
      );

      await _insertHistory(
        txn,
        title: 'Hábito editado: ${input.title.trim()}',
        description: 'Configuração do hábito atualizada.',
        type: 'habit_updated',
        xpDelta: 0,
        coinsDelta: 0,
        nowIso: now,
      );
    });
  }

  Future<void> deactivateHabit(String habitId) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'habits',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  Future<List<HabitLogEntry>> getRecentLogs(String habitId, {int limit = 10}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(HabitLogEntry.fromMap).toList();
  }

  Future<HabitPeriodStats> getCurrentStats(Habit habit) async {
    final db = await AppDatabase.instance.database;
    return _getCurrentStats(db, habit);
  }

  Future<HabitLogResult> addLog({
    required Habit habit,
    required double value,
    String note = '',
  }) async {
    if (value <= 0) {
      throw ArgumentError('Informe um valor maior que zero.');
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final range = _rangeForHabitFrequency(habit.frequency, now);

    var xpGained = 0;
    var coinsGained = 0;
    var rewardApplied = false;
    var message = 'Registro salvo.';

    await db.transaction((txn) async {
      await txn.insert(
        'habit_logs',
        {
          'id': IdGenerator.create('habit_log'),
          'habit_id': habit.id,
          'value': value,
          'note': note.trim(),
          'logged_for': range.startIso,
          'created_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      final stats = await _statsForRange(txn, habit, range);
      final alreadyRewarded = await _hasRewardForPeriod(txn, habit.id, range.startIso);

      if (habit.isBuildStyle && !alreadyRewarded && stats.totalLogged >= habit.targetValue) {
        xpGained = habit.xpReward;
        coinsGained = habit.coinsReward;
        rewardApplied = true;
        await _applyPeriodReward(
          txn: txn,
          habit: habit,
          range: range,
          xp: xpGained,
          coins: coinsGained,
          nowIso: nowIso,
          reason: 'Meta alcançada: ${habit.title}',
        );
        message = 'Meta do hábito alcançada! +$xpGained XP${coinsGained > 0 ? ' e +$coinsGained coins' : ''}.';
      } else if (habit.isReduction && stats.totalLogged > habit.limitValue) {
        message = 'Registro salvo, mas o limite do período foi estourado.';
      }
    });

    if (rewardApplied) {
      await AchievementRepository().refreshAutomaticAchievements();
    }

    return HabitLogResult(
      message: message,
      xpGained: xpGained,
      coinsGained: coinsGained,
      rewardApplied: rewardApplied,
    );
  }

  Future<HabitLogResult> claimReductionPeriodSuccess(Habit habit) async {
    if (!habit.isReduction) {
      throw StateError('Essa ação é apenas para hábitos de redução ou evitação.');
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final range = _rangeForHabitFrequency(habit.frequency, now);
    var result = const HabitLogResult(
      message: 'Recompensa já recebida neste período.',
      xpGained: 0,
      coinsGained: 0,
      rewardApplied: false,
    );

    await db.transaction((txn) async {
      final stats = await _statsForRange(txn, habit, range);
      final alreadyRewarded = await _hasRewardForPeriod(txn, habit.id, range.startIso);

      if (alreadyRewarded) return;

      if (stats.totalLogged > habit.limitValue) {
        result = const HabitLogResult(
          message: 'Ainda não dá para receber recompensa: o limite do período foi estourado.',
          xpGained: 0,
          coinsGained: 0,
          rewardApplied: false,
        );
        return;
      }

      await _applyPeriodReward(
        txn: txn,
        habit: habit,
        range: range,
        xp: habit.xpReward,
        coins: habit.coinsReward,
        nowIso: nowIso,
        reason: 'Hábito dentro do limite: ${habit.title}',
      );

      result = HabitLogResult(
        message: 'Período vencido dentro do limite! +${habit.xpReward} XP${habit.coinsReward > 0 ? ' e +${habit.coinsReward} coins' : ''}.',
        xpGained: habit.xpReward,
        coinsGained: habit.coinsReward,
        rewardApplied: true,
      );
    });

    if (result.rewardApplied) {
      await AchievementRepository().refreshAutomaticAchievements();
    }

    return result;
  }

  Future<HabitPeriodStats> _getCurrentStats(Database db, Habit habit) async {
    final range = _rangeForHabitFrequency(habit.frequency, DateTime.now());
    return _statsForRange(db, habit, range);
  }

  Future<HabitPeriodStats> _statsForRange(
    DatabaseExecutor executor,
    Habit habit,
    _HabitPeriodRange range,
  ) async {
    final logRows = await executor.rawQuery('''
      SELECT
        COALESCE(SUM(value), 0) AS total_logged,
        COUNT(*) AS log_count
      FROM habit_logs
      WHERE habit_id = ? AND created_at >= ? AND created_at < ?;
    ''', [habit.id, range.startIso, range.endIso]);

    final rewardRows = await executor.query(
      'habit_period_rewards',
      where: 'habit_id = ? AND period_start = ?',
      whereArgs: [habit.id, range.startIso],
      limit: 1,
    );

    return HabitPeriodStats(
      habitId: habit.id,
      totalLogged: logRows.isEmpty ? 0 : readDouble(logRows.first, 'total_logged'),
      logCount: logRows.isEmpty ? 0 : readInt(logRows.first, 'log_count'),
      periodStart: range.startIso,
      periodEnd: range.endIso,
      rewarded: rewardRows.isNotEmpty,
      xpGained: rewardRows.isEmpty ? 0 : readInt(rewardRows.first, 'xp_gained'),
      coinsGained: rewardRows.isEmpty ? 0 : readInt(rewardRows.first, 'coins_gained'),
    );
  }

  Future<bool> _hasRewardForPeriod(
    DatabaseExecutor executor,
    String habitId,
    String periodStart,
  ) async {
    final rows = await executor.query(
      'habit_period_rewards',
      columns: ['id'],
      where: 'habit_id = ? AND period_start = ?',
      whereArgs: [habitId, periodStart],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> _applyPeriodReward({
    required Transaction txn,
    required Habit habit,
    required _HabitPeriodRange range,
    required int xp,
    required int coins,
    required String nowIso,
    required String reason,
  }) async {
    await txn.insert(
      'habit_period_rewards',
      {
        'id': IdGenerator.create('habit_reward'),
        'habit_id': habit.id,
        'period_start': range.startIso,
        'period_end': range.endIso,
        'xp_gained': xp,
        'coins_gained': coins,
        'created_at': nowIso,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    await _applyHeroReward(txn: txn, xp: xp, coins: coins, nowIso: nowIso);
    await _applyAttributeRewardsForItem(
      txn: txn,
      itemType: 'habit',
      itemId: habit.id,
      fallbackAttributeId: habit.attributeId,
      xp: xp,
      nowIso: nowIso,
    );
    await AreaProgressionService.applyAreaXp(
      executor: txn,
      areaId: habit.areaId,
      xp: xp,
      nowIso: nowIso,
    );
    await _insertHistory(
      txn,
      title: reason,
      description: '+$xp XP${coins > 0 ? ', +$coins coins' : ''} por hábito ${habit.frequencyLabel.toLowerCase()}.',
      type: 'habit_reward',
      xpDelta: xp,
      coinsDelta: coins,
      nowIso: nowIso,
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
    final newXp = (readInt(hero, 'xp') + xp).clamp(0, 1 << 31).toInt();
    final newCoins = (readInt(hero, 'coins') + coins).clamp(0, 1 << 31).toInt();

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

  Future<void> _insertHistory(
    Transaction txn, {
    required String title,
    required String description,
    required String type,
    required int xpDelta,
    required int coinsDelta,
    required String nowIso,
  }) async {
    await txn.insert(
      'history_events',
      {
        'id': IdGenerator.create('history'),
        'title': title,
        'description': description,
        'type': type,
        'xp_delta': xpDelta,
        'coins_delta': coinsDelta,
        'occurred_at': nowIso,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
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
        await _applyAttributeReward(txn: txn, attributeId: fallbackAttributeId, xp: xp, nowIso: nowIso);
      }
      return;
    }

    final totalWeight = rows.fold<int>(0, (sum, row) => sum + readInt(row, 'weight'));
    if (totalWeight <= 0) return;

    var remainingXp = xp.abs();
    final sign = xp < 0 ? -1 : 1;

    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final attributeId = row['attribute_id']?.toString() ?? '';
      if (attributeId.isEmpty) continue;

      final share = index == rows.length - 1
          ? remainingXp
          : ((xp.abs() * readInt(row, 'weight')) / totalWeight).round().clamp(0, remainingXp).toInt();
      remainingXp -= share;
      if (share <= 0) continue;

      await _applyAttributeReward(txn: txn, attributeId: attributeId, xp: share * sign, nowIso: nowIso);
    }
  }

  Future<void> _applyAttributeReward({
    required Transaction txn,
    required String attributeId,
    required int xp,
    required String nowIso,
  }) async {
    final rows = await txn.query(
      'hero_attributes',
      where: 'attribute_id = ?',
      whereArgs: [attributeId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final currentXp = readInt(rows.first, 'xp');
    final nextXp = (currentXp + xp).clamp(0, 1 << 31).toInt();
    await txn.update(
      'hero_attributes',
      {
        'xp': nextXp,
        'points': nextXp ~/ 100,
        'updated_at': nowIso,
      },
      where: 'attribute_id = ?',
      whereArgs: [attributeId],
    );
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

  void _validateInput(CreateHabitInput input) {
    if (input.title.trim().isEmpty) {
      throw ArgumentError('Informe o nome do hábito.');
    }
    if (!const ['build', 'maintain', 'reduce', 'avoid'].contains(input.type)) {
      throw ArgumentError('Tipo de hábito inválido.');
    }
    if (!const ['daily', 'weekly'].contains(input.frequency)) {
      throw ArgumentError('Frequência inválida.');
    }
    if (input.type == 'build' || input.type == 'maintain') {
      if (input.targetValue <= 0) throw ArgumentError('A meta deve ser maior que zero.');
    }
    if (input.type == 'reduce' && input.limitValue < 0) {
      throw ArgumentError('O limite não pode ser negativo.');
    }
  }

  double _safeTarget(CreateHabitInput input) {
    if (input.type == 'reduce' || input.type == 'avoid') return 1;
    return input.targetValue <= 0 ? 1 : input.targetValue;
  }

  double _safeLimit(CreateHabitInput input) {
    if (input.type == 'avoid') return 0;
    if (input.type == 'reduce') return input.limitValue < 0 ? 0 : input.limitValue;
    return 0;
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

  int _clampReward(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }


  String _typeLabel(String type) {
    return switch (type) {
      'build' => 'Construir',
      'maintain' => 'Manter',
      'reduce' => 'Reduzir',
      'avoid' => 'Evitar',
      _ => type,
    };
  }

  String _frequencyLabel(String frequency) {
    return switch (frequency) {
      'weekly' => 'Semanal',
      'daily' => 'Diário',
      _ => frequency,
    };
  }

  _HabitPeriodRange _rangeForHabitFrequency(String frequency, DateTime reference) {
    final day = DateTime(reference.year, reference.month, reference.day);
    if (frequency == 'weekly') {
      final start = day.subtract(Duration(days: day.weekday - 1));
      return _HabitPeriodRange(start: start, end: start.add(const Duration(days: 7)));
    }
    return _HabitPeriodRange(start: day, end: day.add(const Duration(days: 1)));
  }
}

class _HabitPeriodRange {
  const _HabitPeriodRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  String get startIso => start.toIso8601String();
  String get endIso => end.toIso8601String();
}
