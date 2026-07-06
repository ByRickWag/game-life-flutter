import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../services/difficulty_service.dart';

class OnboardingSetup {
  const OnboardingSetup({
    required this.heroName,
    required this.heroTitle,
    required this.difficultyMode,
    required this.focusAreas,
    required this.waterTargetMl,
    required this.useStarterPresets,
    required this.useRecommendedSetup,
    required this.campaignTitle,
    required this.campaignDescription,
    required this.campaignMainGoal,
    required this.campaignLore,
    required this.campaignStartDate,
    required this.campaignEndDate,
    required this.victoryMinimumPercent,
    required this.victoryGoodPercent,
    required this.victoryExcellentPercent,
    required this.activeAreaIds,
    required this.areaAttributeIds,
  });

  final String heroName;
  final String heroTitle;
  final String difficultyMode;
  final List<String> focusAreas;
  final int waterTargetMl;
  final bool useStarterPresets;
  final bool useRecommendedSetup;
  final String campaignTitle;
  final String campaignDescription;
  final String campaignMainGoal;
  final String campaignLore;
  final String campaignStartDate;
  final String campaignEndDate;
  final int victoryMinimumPercent;
  final int victoryGoodPercent;
  final int victoryExcellentPercent;
  final List<String> activeAreaIds;
  final Map<String, List<String>> areaAttributeIds;
}

class OnboardingStatus {
  const OnboardingStatus({
    required this.completed,
    required this.heroName,
    required this.heroTitle,
    required this.difficultyMode,
    required this.focusAreas,
    required this.waterTargetMl,
    required this.useStarterPresets,
    required this.useRecommendedSetup,
    required this.campaignTitle,
    required this.campaignDescription,
    required this.campaignMainGoal,
    required this.campaignLore,
    required this.campaignStartDate,
    required this.campaignEndDate,
    required this.victoryMinimumPercent,
    required this.victoryGoodPercent,
    required this.victoryExcellentPercent,
    required this.activeAreaIds,
    required this.areaAttributeIds,
    required this.currentCheckInStreak,
    required this.hardcoreUnlocked,
  });

  final bool completed;
  final String heroName;
  final String heroTitle;
  final String difficultyMode;
  final List<String> focusAreas;
  final int waterTargetMl;
  final bool useStarterPresets;
  final bool useRecommendedSetup;
  final String campaignTitle;
  final String campaignDescription;
  final String campaignMainGoal;
  final String campaignLore;
  final String campaignStartDate;
  final String campaignEndDate;
  final int victoryMinimumPercent;
  final int victoryGoodPercent;
  final int victoryExcellentPercent;
  final List<String> activeAreaIds;
  final Map<String, List<String>> areaAttributeIds;
  final int currentCheckInStreak;
  final bool hardcoreUnlocked;
}

class OnboardingRepository {
  const OnboardingRepository();

  static const String completedKey = 'onboarding_completed';
  static const String completedAtKey = 'onboarding_completed_at';
  static const String focusAreasKey = 'onboarding_focus_areas';
  static const String useStarterPresetsKey = 'onboarding_use_starter_presets';
  static const String waterTargetKey = 'onboarding_water_target_ml';
  static const String recommendedSetupKey = 'onboarding_use_recommended_setup';
  static const String activeAreasKey = 'onboarding_active_area_ids';
  static const String areaAttributesPrefix = 'onboarding_area_attributes_';

  Future<bool> isCompleted() async {
    final status = await getStatus();
    return status.completed;
  }

  Future<OnboardingStatus> getStatus() async {
    final db = await AppDatabase.instance.database;
    await _ensureSettings(db);

    final settings = await _loadSettings(db);
    final heroRows = await db.query('hero_profiles', limit: 1);
    final hero = heroRows.isEmpty ? const <String, Object?>{} : heroRows.first;
    final campaignRow = await _loadActiveCampaign(db);
    final currentStreak = await _currentCheckInStreak(db);

    final activeAreaIds = _normalizeAreaIds(_decodeList(settings[activeAreasKey] ?? ''));
    final areaAttributeIds = <String, List<String>>{};
    for (final areaId in activeAreaIds) {
      final settingKey = '$areaAttributesPrefix$areaId';
      final saved = _normalizeAttributes(_decodeList(settings[settingKey] ?? ''));
      final fromDb = saved.isEmpty ? await _loadAreaAttributes(db, areaId) : saved;
      areaAttributeIds[areaId] = _normalizeAttributes(
        fromDb.isEmpty ? _defaultAttributesForArea(areaId) : fromDb,
      ).take(3).toList();
    }

    return OnboardingStatus(
      completed: _readBool(settings, completedKey, false),
      heroName: _readString(hero, 'name', 'Herói da Jornada'),
      heroTitle: _readString(hero, 'title', 'Iniciante da Transformação'),
      difficultyMode: _readStringValue(settings, 'active_difficulty_mode', 'normal'),
      focusAreas: _decodeFocusAreas(settings[focusAreasKey] ?? ''),
      waterTargetMl: _readIntValue(settings, waterTargetKey, 1000),
      useStarterPresets: _readBool(settings, useStarterPresetsKey, true),
      useRecommendedSetup: _readBool(settings, recommendedSetupKey, true),
      campaignTitle: _readString(campaignRow, 'title', 'Transformação dos 20 aos 25'),
      campaignDescription: _readString(
        campaignRow,
        'description',
        'Campanha principal de evolução pessoal com foco em corpo, mente, fé, finanças, programação e projetos.',
      ),
      campaignMainGoal: _readString(
        campaignRow,
        'main_goal',
        'Chegar aos 25 anos com saúde melhor, disciplina real, carreira/projetos encaminhados, fé fortalecida e vida financeira mais madura.',
      ),
      campaignLore: _readString(
        campaignRow,
        'lore',
        'Uma jornada de cinco anos para sair do automático e construir uma vida mais forte, lúcida e responsável.',
      ),
      campaignStartDate: _dateOnly(_readString(campaignRow, 'start_date', DateTime.now().toIso8601String())),
      campaignEndDate: _dateOnly(_readString(campaignRow, 'end_date', '2031-07-13')),
      victoryMinimumPercent: _readInt(campaignRow, 'victory_minimum_percent', fallback: 60),
      victoryGoodPercent: _readInt(campaignRow, 'victory_good_percent', fallback: 75),
      victoryExcellentPercent: _readInt(campaignRow, 'victory_excellent_percent', fallback: 90),
      activeAreaIds: activeAreaIds,
      areaAttributeIds: areaAttributeIds,
      currentCheckInStreak: currentStreak,
      hardcoreUnlocked: currentStreak >= 7,
    );
  }

  Future<void> complete(OnboardingSetup setup) async {
    final db = await AppDatabase.instance.database;
    final currentStreak = await _currentCheckInStreak(db);
    final normalizedDifficulty = _normalizeDifficulty(setup.difficultyMode);
    if (normalizedDifficulty == 'hardcore' && currentStreak < 7) {
      throw StateError('Modo Hardcore só desbloqueia após 7 dias seguidos de check-in.');
    }

    final now = DateTime.now().toIso8601String();
    final heroName = setup.heroName.trim().isEmpty ? 'Herói da Jornada' : setup.heroName.trim();
    final heroTitle = setup.heroTitle.trim().isEmpty
        ? 'Iniciante da Transformação'
        : setup.heroTitle.trim();
    final activeAreaIds = _normalizeAreaIds(setup.activeAreaIds);
    final focusAreas = _normalizeFocusAreas(
      setup.focusAreas.isEmpty ? _focusAreasFromAreaIds(activeAreaIds) : setup.focusAreas,
    );
    final waterTarget = setup.waterTargetMl.clamp(500, 4000).toInt();
    final victoryMinimum = setup.victoryMinimumPercent.clamp(1, 100).toInt();
    final victoryGood = setup.victoryGoodPercent.clamp(victoryMinimum, 100).toInt();
    final victoryExcellent = setup.victoryExcellentPercent.clamp(victoryGood, 100).toInt();

    await db.transaction((txn) async {
      await _ensureSettings(txn);

      await txn.update(
        'hero_profiles',
        {
          'name': heroName,
          'title': heroTitle,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: ['main_hero'],
      );

      await txn.update(
        'campaigns',
        {'is_active': 0, 'updated_at': now},
        where: 'id != ?',
        whereArgs: ['transformation_20_25'],
      );

      await txn.insert(
        'campaigns',
        {
          'id': 'transformation_20_25',
          'title': _withFallback(setup.campaignTitle, 'Transformação dos 20 aos 25'),
          'description': _withFallback(
            setup.campaignDescription,
            'Campanha principal de evolução pessoal com foco em corpo, mente, fé, finanças, programação e projetos.',
          ),
          'lore': _withFallback(
            setup.campaignLore,
            'Uma jornada de cinco anos para sair do automático e construir uma vida mais forte, lúcida e responsável.',
          ),
          'main_goal': _withFallback(
            setup.campaignMainGoal,
            'Chegar aos 25 anos com saúde melhor, disciplina real, carreira/projetos encaminhados, fé fortalecida e vida financeira mais madura.',
          ),
          'start_date': _withFallback(setup.campaignStartDate, _todayKey()),
          'end_date': _nullable(setup.campaignEndDate),
          'difficulty_mode': normalizedDifficulty,
          'victory_minimum_percent': victoryMinimum,
          'victory_good_percent': victoryGood,
          'victory_excellent_percent': victoryExcellent,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await txn.update(
        'campaigns',
        {
          'title': _withFallback(setup.campaignTitle, 'Transformação dos 20 aos 25'),
          'description': _withFallback(
            setup.campaignDescription,
            'Campanha principal de evolução pessoal com foco em corpo, mente, fé, finanças, programação e projetos.',
          ),
          'lore': _withFallback(
            setup.campaignLore,
            'Uma jornada de cinco anos para sair do automático e construir uma vida mais forte, lúcida e responsável.',
          ),
          'main_goal': _withFallback(
            setup.campaignMainGoal,
            'Chegar aos 25 anos com saúde melhor, disciplina real, carreira/projetos encaminhados, fé fortalecida e vida financeira mais madura.',
          ),
          'start_date': _withFallback(setup.campaignStartDate, _todayKey()),
          'end_date': _nullable(setup.campaignEndDate),
          'difficulty_mode': normalizedDifficulty,
          'victory_minimum_percent': victoryMinimum,
          'victory_good_percent': victoryGood,
          'victory_excellent_percent': victoryExcellent,
          'is_active': 1,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: ['transformation_20_25'],
      );

      await _upsertSetting(
        txn,
        key: completedKey,
        value: 'true',
        valueType: 'bool',
        description: 'Indica se a configuração inicial já foi concluída.',
        nowIso: now,
      );
      await _upsertSetting(
        txn,
        key: completedAtKey,
        value: now,
        valueType: 'text',
        description: 'Data em que o onboarding foi concluído pela última vez.',
        nowIso: now,
      );
      await _upsertSetting(
        txn,
        key: focusAreasKey,
        value: focusAreas.join(','),
        valueType: 'text',
        description: 'Focos iniciais escolhidos no onboarding.',
        nowIso: now,
      );
      await _upsertSetting(
        txn,
        key: useStarterPresetsKey,
        value: setup.useStarterPresets ? 'true' : 'false',
        valueType: 'bool',
        description: 'Controla se os presets iniciais foram aceitos no onboarding.',
        nowIso: now,
      );
      await _upsertSetting(
        txn,
        key: recommendedSetupKey,
        value: setup.useRecommendedSetup ? 'true' : 'false',
        valueType: 'bool',
        description: 'Controla se o onboarding está usando a configuração recomendada.',
        nowIso: now,
      );
      await _upsertSetting(
        txn,
        key: activeAreasKey,
        value: activeAreaIds.join(','),
        valueType: 'text',
        description: 'Áreas de vida ativas escolhidas no onboarding.',
        nowIso: now,
      );
      await _upsertSetting(
        txn,
        key: waterTargetKey,
        value: '$waterTarget',
        valueType: 'int',
        description: 'Meta inicial de água escolhida no onboarding.',
        nowIso: now,
      );
      await _upsertSetting(
        txn,
        key: 'health_water_default_ml',
        value: '$waterTarget',
        valueType: 'int',
        description: 'Meta inicial diária de água em ml.',
        nowIso: now,
      );
      await _upsertSetting(
        txn,
        key: 'economy_coins_auto_half_xp',
        value: 'true',
        valueType: 'bool',
        description: 'Preferência para futuras telas calcularem coins como metade do XP.',
        nowIso: now,
      );

      for (final areaId in activeAreaIds) {
        final attributes = _normalizeAttributes(
          setup.areaAttributeIds[areaId] ?? _defaultAttributesForArea(areaId),
        ).take(3).toList();
        await _upsertSetting(
          txn,
          key: '$areaAttributesPrefix$areaId',
          value: attributes.join(','),
          valueType: 'text',
          description: 'Atributos sugeridos automaticamente para a área $areaId.',
          nowIso: now,
        );
        await _replaceAreaAttributeLinks(txn, areaId: areaId, attributes: attributes);
      }

      await txn.update(
        'habits',
        {
          'target_value': waterTarget.toDouble(),
          'updated_at': now,
        },
        where: "health_kind = ? AND health_category = ?",
        whereArgs: ['water', 'water'],
      );

      if (setup.useStarterPresets) {
        await _applyStarterPresets(txn, focusAreas: focusAreas, waterTargetMl: waterTarget, nowIso: now);
      }

      await txn.insert(
        'history_events',
        {
          'id': 'history_onboarding_$now',
          'title': 'Configuração inicial concluída',
          'description': 'Herói, dificuldade, campanha, áreas e presets foram preparados.',
          'type': 'system',
          'xp_delta': 0,
          'coins_delta': 0,
          'occurred_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });

    await DifficultyService().setActiveMode(normalizedDifficulty);
  }

  Future<void> reset() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await _upsertSetting(
      db,
      key: completedKey,
      value: 'false',
      valueType: 'bool',
      description: 'Indica se a configuração inicial já foi concluída.',
      nowIso: now,
    );
  }

  Future<Map<String, Object?>> _loadActiveCampaign(DatabaseExecutor db) async {
    final rows = await db.query(
      'campaigns',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first;
    final fallback = await db.query('campaigns', where: 'id = ?', whereArgs: ['transformation_20_25'], limit: 1);
    return fallback.isEmpty ? const <String, Object?>{} : fallback.first;
  }

  Future<List<String>> _loadAreaAttributes(DatabaseExecutor db, String areaId) async {
    final rows = await db.query(
      'area_attribute_links',
      where: 'area_id = ?',
      whereArgs: [areaId],
      orderBy: 'weight DESC, attribute_id ASC',
    );
    return rows.map((row) => row['attribute_id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
  }

  Future<int> _currentCheckInStreak(DatabaseExecutor db) async {
    final rows = await db.query('daily_checkins', orderBy: 'checkin_date DESC', limit: 1);
    if (rows.isEmpty) return 0;
    return _readInt(rows.first, 'streak_count');
  }

  Future<Map<String, String>> _loadSettings(DatabaseExecutor db) async {
    final rows = await db.query('settings');
    return {
      for (final row in rows) _readString(row, 'key', ''): _readString(row, 'value', ''),
    }..remove('');
  }

  Future<void> _ensureSettings(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();
    final defaults = <String, List<String>>{
      completedKey: ['false', 'bool', 'Indica se a configuração inicial já foi concluída.'],
      completedAtKey: ['', 'text', 'Data em que o onboarding foi concluído pela última vez.'],
      focusAreasKey: ['health,discipline', 'text', 'Focos iniciais escolhidos no onboarding.'],
      useStarterPresetsKey: ['true', 'bool', 'Controla se presets iniciais devem ser sugeridos.'],
      waterTargetKey: ['1000', 'int', 'Meta inicial de água escolhida no onboarding.'],
      recommendedSetupKey: ['true', 'bool', 'Controla se o onboarding usa a configuração recomendada.'],
      activeAreasKey: [_defaultAreaIds.join(','), 'text', 'Áreas de vida ativas escolhidas no onboarding.'],
      'economy_coins_auto_half_xp': ['true', 'bool', 'Sugere coins como metade do XP nas próximas telas.'],
    };

    for (final areaId in _defaultAreaIds) {
      defaults['$areaAttributesPrefix$areaId'] = [
        _defaultAttributesForArea(areaId).join(','),
        'text',
        'Atributos sugeridos automaticamente para a área $areaId.',
      ];
    }

    for (final entry in defaults.entries) {
      await _upsertSetting(
        db,
        key: entry.key,
        value: entry.value[0],
        valueType: entry.value[1],
        description: entry.value[2],
        nowIso: now,
        overwrite: false,
      );
    }
  }

  Future<void> _replaceAreaAttributeLinks(
    DatabaseExecutor txn, {
    required String areaId,
    required List<String> attributes,
  }) async {
    final safeAttributes = _normalizeAttributes(attributes).take(3).toList();
    if (safeAttributes.isEmpty) return;

    await txn.delete('area_attribute_links', where: 'area_id = ?', whereArgs: [areaId]);
    final weights = safeAttributes.length == 1
        ? [100]
        : safeAttributes.length == 2
            ? [70, 30]
            : [50, 30, 20];

    for (var index = 0; index < safeAttributes.length; index++) {
      await txn.insert(
        'area_attribute_links',
        {
          'area_id': areaId,
          'attribute_id': safeAttributes[index],
          'weight': weights[index],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyStarterPresets(
    DatabaseExecutor txn, {
    required List<String> focusAreas,
    required int waterTargetMl,
    required String nowIso,
  }) async {
    final selected = focusAreas.toSet();

    final requiredHabitIds = <String>{'habit_water_base'};
    if (selected.contains('health')) {
      requiredHabitIds.addAll(const [
        'habit_body_movement_base',
        'habit_soda_reduce_base',
        'habit_ultra_processed_reduce_base',
        'habit_salty_fast_food_reduce_base',
      ]);
    }
    if (selected.contains('faith')) {
      requiredHabitIds.add('habit_bible_reading_base');
    }
    if (selected.contains('discipline')) {
      requiredHabitIds.addAll(const ['habit_body_movement_base', 'habit_bible_reading_base']);
    }

    for (final habitId in requiredHabitIds) {
      await txn.update(
        'habits',
        {
          'is_active': 1,
          if (habitId == 'habit_water_base') 'target_value': waterTargetMl.toDouble(),
          'updated_at': nowIso,
        },
        where: 'id = ?',
        whereArgs: [habitId],
      );
    }

    if (selected.contains('study')) {
      await _ensureHabit(
        txn,
        id: 'habit_programming_study_base',
        title: 'Estudar programação',
        description: 'Sessão mínima de estudo ou prática de código para manter a chama acesa.',
        type: 'build',
        frequency: 'daily',
        unit: 'minutes',
        targetValue: 25,
        limitValue: 0,
        areaId: 'mind_knowledge',
        attributeId: 'focus',
        attributes: const ['focus', 'clarity', 'discipline'],
        xpReward: 10,
        nowIso: nowIso,
      );
    }

    if (selected.contains('finance')) {
      await _ensureStarterVault(txn, nowIso: nowIso);
    }
  }

  Future<void> _ensureHabit(
    DatabaseExecutor txn, {
    required String id,
    required String title,
    required String description,
    required String type,
    required String frequency,
    required String unit,
    required double targetValue,
    required double limitValue,
    required String areaId,
    required String attributeId,
    required List<String> attributes,
    required int xpReward,
    required String nowIso,
  }) async {
    await txn.insert(
      'habits',
      {
        'id': id,
        'title': title,
        'description': description,
        'type': type,
        'frequency': frequency,
        'unit': unit,
        'target_value': targetValue,
        'limit_value': limitValue,
        'area_id': areaId,
        'attribute_id': attributeId,
        'xp_reward': xpReward,
        'coins_reward': 0,
        'health_kind': '',
        'health_category': '',
        'is_active': 1,
        'created_at': nowIso,
        'updated_at': nowIso,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await txn.update(
      'habits',
      {
        'is_active': 1,
        'updated_at': nowIso,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final weights = attributes.length == 1
        ? [100]
        : attributes.length == 2
            ? [70, 30]
            : [50, 30, 20];

    for (var index = 0; index < attributes.length; index++) {
      await txn.insert(
        'item_attribute_links',
        {
          'id': 'attr_link_${id}_${attributes[index]}',
          'item_type': 'habit',
          'item_id': id,
          'attribute_id': attributes[index],
          'weight': weights[index],
          'is_primary': index == 0 ? 1 : 0,
          'created_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _ensureStarterVault(DatabaseExecutor txn, {required String nowIso}) async {
    await txn.insert(
      'vaults',
      {
        'id': 'vault_starter_reserve',
        'name': 'Reserva inicial',
        'description': 'Cofre base para começar a guardar dinheiro real fora do app com intenção clara.',
        'goal_amount': 100.0,
        'icon': 'savings',
        'color': 'amber',
        'status': 'active',
        'created_at': nowIso,
        'updated_at': nowIso,
        'archived_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _upsertSetting(
    DatabaseExecutor db, {
    required String key,
    required String value,
    required String valueType,
    required String description,
    required String nowIso,
    bool overwrite = true,
  }) async {
    final existing = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert(
        'settings',
        {
          'key': key,
          'value': value,
          'value_type': valueType,
          'description': description,
          'updated_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return;
    }

    if (!overwrite) return;

    await db.update(
      'settings',
      {
        'value': value,
        'value_type': valueType,
        'description': description,
        'updated_at': nowIso,
      },
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  static const List<String> _defaultAreaIds = [
    'body_health',
    'mind_knowledge',
    'spirit_purpose',
    'projects_career',
    'creation_expression',
    'finance_responsibility',
    'routine_order',
  ];

  static const Set<String> _allowedAttributes = {
    'strength',
    'vigor',
    'clarity',
    'focus',
    'creativity',
    'responsibility',
    'discipline',
    'faith',
  };

  List<String> _defaultAttributesForArea(String areaId) {
    return switch (areaId) {
      'body_health' => const ['vigor', 'strength', 'discipline'],
      'mind_knowledge' => const ['clarity', 'focus', 'discipline'],
      'spirit_purpose' => const ['faith', 'clarity', 'discipline'],
      'projects_career' => const ['focus', 'responsibility', 'clarity'],
      'creation_expression' => const ['creativity', 'focus', 'clarity'],
      'finance_responsibility' => const ['responsibility', 'discipline', 'clarity'],
      'routine_order' => const ['discipline', 'responsibility', 'clarity'],
      _ => const ['discipline', 'focus', 'clarity'],
    };
  }

  List<String> _decodeFocusAreas(String raw) => _normalizeFocusAreas(_decodeList(raw));

  List<String> _decodeList(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _normalizeFocusAreas(List<String> values) {
    const allowed = {'health', 'study', 'faith', 'finance', 'discipline'};
    final normalized = values
        .map((item) => item.trim())
        .where(allowed.contains)
        .toSet()
        .toList();
    if (normalized.isEmpty) return const ['health', 'discipline'];
    return normalized;
  }

  List<String> _normalizeAreaIds(List<String> values) {
    final normalized = values.where(_defaultAreaIds.contains).toSet().toList();
    if (normalized.isEmpty) return _defaultAreaIds;
    normalized.sort((a, b) => _defaultAreaIds.indexOf(a).compareTo(_defaultAreaIds.indexOf(b)));
    return normalized;
  }

  List<String> _normalizeAttributes(List<String> values) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final value in values) {
      final attributeId = value.trim();
      if (!_allowedAttributes.contains(attributeId) || seen.contains(attributeId)) continue;
      seen.add(attributeId);
      normalized.add(attributeId);
    }
    return normalized;
  }

  List<String> _focusAreasFromAreaIds(List<String> areaIds) {
    final focus = <String>{};
    if (areaIds.contains('body_health')) focus.add('health');
    if (areaIds.contains('mind_knowledge') || areaIds.contains('projects_career')) focus.add('study');
    if (areaIds.contains('spirit_purpose')) focus.add('faith');
    if (areaIds.contains('finance_responsibility')) focus.add('finance');
    if (areaIds.contains('routine_order')) focus.add('discipline');
    if (focus.isEmpty) focus.addAll(const ['health', 'discipline']);
    return focus.toList();
  }

  String _normalizeDifficulty(String mode) {
    return switch (mode) {
      'hard' => 'hard',
      'hardcore' => 'hardcore',
      _ => 'normal',
    };
  }

  String _readString(Map<String, Object?> map, String key, String fallback) {
    final value = map[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String _readStringValue(Map<String, String> settings, String key, String fallback) {
    final value = settings[key]?.trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  int _readIntValue(Map<String, String> settings, String key, int fallback) {
    final parsed = int.tryParse(settings[key] ?? '');
    if (parsed == null || parsed <= 0) return fallback;
    return parsed;
  }

  int _readInt(Map<String, Object?> map, String key, {int fallback = 0}) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool _readBool(Map<String, String> settings, String key, bool fallback) {
    final value = settings[key]?.trim().toLowerCase();
    if (value == null || value.isEmpty) return fallback;
    return value == 'true' || value == '1' || value == 'yes' || value == 'sim';
  }

  String _dateOnly(String raw) {
    final value = raw.trim();
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  String _todayKey() => DateTime.now().toIso8601String().substring(0, 10);

  String _withFallback(String value, String fallback) {
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String? _nullable(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
