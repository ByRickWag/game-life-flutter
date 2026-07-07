import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/game_models.dart';
import '../services/progression_service.dart';
import '../utils/id_generator.dart';

class BalanceSetting {
  const BalanceSetting({
    required this.key,
    required this.value,
    required this.valueType,
    required this.description,
    required this.updatedAt,
  });

  final String key;
  final String value;
  final String valueType;
  final String description;
  final String updatedAt;

  factory BalanceSetting.fromMap(Map<String, Object?> map) {
    return BalanceSetting(
      key: readString(map, 'key'),
      value: readString(map, 'value'),
      valueType: readString(map, 'value_type', fallback: 'text'),
      description: readString(map, 'description'),
      updatedAt: readString(map, 'updated_at'),
    );
  }

  String get label {
    return switch (key) {
      'xp_cap_mission_easy' => 'Teto missão fácil',
      'xp_cap_mission_normal' => 'Teto missão normal',
      'xp_cap_mission_medium' => 'Teto missão média',
      'xp_cap_mission_hard' => 'Teto missão difícil',
      'xp_cap_mission_very_hard' => 'Teto missão muito difícil',
      'xp_cap_special_very_hard' => 'Teto especial muito difícil',
      'xp_cap_objective_easy' => 'Teto objetivo fácil',
      'xp_cap_objective_normal' => 'Teto objetivo normal',
      'xp_cap_objective_medium' => 'Teto objetivo médio',
      'xp_cap_objective_hard' => 'Teto objetivo difícil',
      'xp_cap_objective_very_hard' => 'Teto objetivo muito difícil',
      'xp_cap_session' => 'Teto por sessão',
      'project_task_xp_default' => 'Projeto: XP padrão por tarefa',
      'project_task_xp_cap' => 'Projeto: teto por tarefa',
      'project_completion_xp' => 'Projeto: XP de conclusão',
      'project_completion_coins' => 'Projeto: coins de conclusão',
      'xp_daily_easy' => 'Missão diária fácil',
      'xp_daily_normal' => 'Missão diária normal',
      'xp_daily_hard' => 'Missão diária difícil',
      'xp_weekly_base' => 'Missão semanal base',
      'xp_monthly_base' => 'Missão mensal / objetivo base',
      'xp_special_base' => 'Missão especial base',
      'coins_easy' => 'Coins fácil',
      'coins_normal' => 'Coins normal',
      'coins_medium' => 'Coins médio',
      'coins_hard' => 'Coins difícil',
      'coins_very_hard' => 'Coins muito difícil',
      'session_xp_per_15min' => 'Sessão: XP a cada 15 min',
      'objective_completion_multiplier' => 'Multiplicador de objetivo',
      'habit_xp_default' => 'Hábito: XP diário padrão',
      'habit_xp_weekly_default' => 'Hábito: XP semanal padrão',
      'habit_coin_default' => 'Hábito: coins padrão',
      'habit_max_attributes' => 'Hábito: máximo de atributos',
      'level_curve_multiplier_normal' => 'Curva Normal',
      'level_curve_multiplier_hard' => 'Curva Difícil',
      'level_curve_multiplier_hardcore' => 'Curva Hardcore',
      'hero_max_level' => 'Nível máximo do herói',
      'mission_failure_penalty_enabled' => 'Penalidade por falha',
      _ => key,
    };
  }

  String get shortValue {
    if (valueType == 'double') return value.replaceAll('.', ',');
    return value;
  }
}

class SystemStats {
  const SystemStats({
    required this.missions,
    required this.objectives,
    required this.habits,
    required this.sessions,
    required this.projects,
    required this.historyEvents,
    required this.totalXpHistory,
    required this.totalCoinsHistory,
  });

  final int missions;
  final int objectives;
  final int habits;
  final int sessions;
  final int projects;
  final int historyEvents;
  final int totalXpHistory;
  final int totalCoinsHistory;

  factory SystemStats.fromMap(Map<String, Object?> map) {
    return SystemStats(
      missions: readInt(map, 'missions'),
      objectives: readInt(map, 'objectives'),
      habits: readInt(map, 'habits'),
      sessions: readInt(map, 'sessions'),
      projects: readInt(map, 'projects'),
      historyEvents: readInt(map, 'history_events'),
      totalXpHistory: readInt(map, 'total_xp_history'),
      totalCoinsHistory: readInt(map, 'total_coins_history'),
    );
  }
}

class SystemRepository {
  const SystemRepository();

  static const Map<String, List<String>> defaultSettings = {
    'xp_cap_mission_easy': ['20', 'int', 'XP máximo para missão fácil.'],
    'xp_cap_mission_normal': ['30', 'int', 'XP máximo para missão normal.'],
    'xp_cap_mission_medium': ['40', 'int', 'XP máximo para missão média.'],
    'xp_cap_mission_hard': ['60', 'int', 'XP máximo para missão difícil.'],
    'xp_cap_mission_very_hard': ['100', 'int', 'XP máximo para missão muito difícil.'],
    'xp_cap_special_very_hard': ['300', 'int', 'XP máximo para missão especial muito difícil.'],
    'xp_cap_objective_easy': ['20', 'int', 'XP máximo para objetivo fácil.'],
    'xp_cap_objective_normal': ['30', 'int', 'XP máximo para objetivo normal.'],
    'xp_cap_objective_medium': ['40', 'int', 'XP máximo para objetivo médio.'],
    'xp_cap_objective_hard': ['60', 'int', 'XP máximo para objetivo difícil.'],
    'xp_cap_objective_very_hard': ['300', 'int', 'XP máximo para objetivo muito difícil.'],
    'xp_cap_session': ['150', 'int', 'XP máximo por sessão finalizada.'],
    'project_task_xp_default': ['5', 'int', 'XP padrão por tarefa de projeto.'],
    'project_task_xp_cap': ['10', 'int', 'XP máximo por tarefa de projeto.'],
    'project_completion_xp': ['150', 'int', 'XP padrão ao concluir projeto.'],
    'project_completion_coins': ['50', 'int', 'Coins padrão ao concluir projeto.'],
    'xp_daily_easy': ['8', 'int', 'Configuração antiga mantida por compatibilidade.'],
    'xp_daily_normal': ['12', 'int', 'Configuração antiga mantida por compatibilidade.'],
    'xp_daily_hard': ['20', 'int', 'Configuração antiga mantida por compatibilidade.'],
    'xp_weekly_base': ['45', 'int', 'Configuração antiga mantida por compatibilidade.'],
    'xp_monthly_base': ['140', 'int', 'Configuração antiga mantida por compatibilidade.'],
    'xp_special_base': ['70', 'int', 'Configuração antiga mantida por compatibilidade.'],
    'coins_easy': ['3', 'int', 'Coins para ação fácil.'],
    'coins_normal': ['5', 'int', 'Coins para ação normal.'],
    'coins_medium': ['7', 'int', 'Coins para ação média.'],
    'coins_hard': ['10', 'int', 'Coins para ação difícil.'],
    'coins_very_hard': ['15', 'int', 'Coins para ação muito difícil.'],
    'session_xp_per_15min': ['5', 'int', 'XP por bloco de 15 minutos em sessões.'],
    'objective_completion_multiplier': ['1.0', 'double', 'Multiplicador de recompensa ao concluir objetivo.'],
    'habit_xp_default': ['8', 'int', 'XP padrão para hábitos simples.'],
    'habit_xp_weekly_default': ['12', 'int', 'XP padrão para hábitos semanais.'],
    'habit_coin_default': ['0', 'int', 'Coins padrão para hábitos.'],
    'habit_max_attributes': ['3', 'int', 'Quantidade máxima de atributos por hábito.'],
    'level_curve_multiplier_normal': ['1.0', 'double', 'Multiplicador da curva de XP no modo Normal.'],
    'level_curve_multiplier_hard': ['1.25', 'double', 'Multiplicador da curva de XP no modo Difícil.'],
    'level_curve_multiplier_hardcore': ['1.5', 'double', 'Multiplicador da curva de XP no modo Hardcore.'],
    'hero_max_level': ['100', 'int', 'Nível máximo do herói nesta fase do app.'],
    'mission_failure_penalty_enabled': ['true', 'bool', 'Ativa penalidades por falha de missão nos modos Difícil e Hardcore.'],
  };

  Future<List<BalanceSetting>> getSettings() async {
    final db = await AppDatabase.instance.database;
    await ensureDefaultSettings(db);

    final rows = await db.query('settings', orderBy: 'key ASC');
    return rows.map(BalanceSetting.fromMap).toList();
  }

  Future<String> getDatabasePath() {
    return AppDatabase.instance.databasePath;
  }

  Future<SystemStats> getStats() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM missions) AS missions,
        (SELECT COUNT(*) FROM objectives) AS objectives,
        (SELECT COUNT(*) FROM habits) AS habits,
        (SELECT COUNT(*) FROM sessions) AS sessions,
        (SELECT COUNT(*) FROM projects) AS projects,
        (SELECT COUNT(*) FROM history_events) AS history_events,
        (SELECT COALESCE(SUM(xp_delta), 0) FROM history_events) AS total_xp_history,
        (SELECT COALESCE(SUM(coins_delta), 0) FROM history_events) AS total_coins_history;
    ''');

    if (rows.isEmpty) {
      return const SystemStats(
        missions: 0,
        objectives: 0,
        habits: 0,
        sessions: 0,
        projects: 0,
        historyEvents: 0,
        totalXpHistory: 0,
        totalCoinsHistory: 0,
      );
    }

    return SystemStats.fromMap(rows.first);
  }

  Future<void> updateSetting({
    required BalanceSetting setting,
    required String rawValue,
  }) async {
    final value = _normalizeValue(rawValue, setting.valueType);
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'settings',
      {
        'value': value,
        'updated_at': now,
      },
      where: 'key = ?',
      whereArgs: [setting.key],
    );

    if (setting.key.startsWith('level_curve_multiplier_') || setting.key == 'hero_max_level') {
      await ProgressionService.refreshHeroLevel(db, nowIso: now);
    }
  }

  Future<void> restoreDefaultSettings() async {
    final db = await AppDatabase.instance.database;
    await ensureDefaultSettings(db, forceDefaults: true);
    await ProgressionService.refreshHeroLevel(db);
    await _insertSystemHistory(
      db,
      title: 'Balanceamento restaurado',
      description: 'As configurações Lite voltaram para os valores padrão.',
    );
  }

  Future<void> resetProgressData() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete('mission_completions');
      await txn.delete('objective_progress_entries');
      await txn.delete('project_tasks');
      await txn.delete('project_milestones');
      await txn.delete('habit_period_rewards');
      await txn.delete('habit_logs');
      await txn.delete('shop_purchases');
      await txn.delete('shop_items');
      await txn.delete('app_meta', where: 'key = ?', whereArgs: ['seed_v310_shop_done']);
      await txn.delete('vault_entries');
      await txn.delete('vaults');
      await txn.delete('item_attribute_links', where: 'item_type = ?', whereArgs: ['habit']);
      await txn.delete('habits');
      await txn.delete('sessions');
      await txn.delete('projects');
      await txn.delete('objectives');
      await txn.delete('missions');
      await txn.delete('history_events');

      await txn.update(
        'campaign_milestones',
        {
          'progress': 0.0,
          'status': 'active',
          'progress_note': null,
          'completed_at': null,
          'updated_at': now,
        },
        where: 'auto_progress_enabled = ?',
        whereArgs: [1],
      );

      await txn.update(
        'hero_achievements',
        {
          'progress_value': 0,
          'is_unlocked': 0,
          'unlocked_at': null,
          'updated_at': now,
        },
      );

      await txn.update(
        'hero_profiles',
        {
          'level': 1,
          'xp': 0,
          'coins': 0,
          'title': 'Iniciante da Transformação',
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: ['main_hero'],
      );

      await txn.update(
        'hero_attributes',
        {
          'points': 0,
          'xp': 0,
          'updated_at': now,
        },
      );

      await txn.update(
        'hero_areas',
        {
          'points': 0,
          'xp': 0,
          'updated_at': now,
        },
      );

      await txn.insert(
        'history_events',
        {
          'id': IdGenerator.create('history'),
          'title': 'Dados de teste resetados',
          'description': 'Missões, hábitos, cofres, loja, objetivos, sessões, projetos e recompensas foram zerados.',
          'type': 'system',
          'xp_delta': 0,
          'coins_delta': 0,
          'occurred_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<String> buildTextReport() async {
    final db = await AppDatabase.instance.database;
    final stats = await getStats();
    final path = await getDatabasePath();
    final settings = await getSettings();

    final heroRows = await db.query('hero_profiles', limit: 1);
    final campaignRows = await db.query(
      'campaigns',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    final attributeRows = await db.rawQuery('''
      SELECT attributes.name, hero_attributes.points, hero_attributes.xp
      FROM hero_attributes
      INNER JOIN attributes ON attributes.id = hero_attributes.attribute_id
      ORDER BY attributes.sort_order;
    ''');
    final areaRows = await db.rawQuery('''
      SELECT areas.name, COALESCE(hero_areas.points, 0) AS points, COALESCE(hero_areas.xp, 0) AS xp
      FROM areas
      LEFT JOIN hero_areas ON hero_areas.area_id = areas.id
      ORDER BY areas.sort_order;
    ''');
    final recentHistoryRows = await db.query(
      'history_events',
      orderBy: 'occurred_at DESC',
      limit: 10,
    );
    final vaultRows = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM vaults WHERE status = 'active') AS active_vaults,
        COALESCE(SUM(CASE WHEN vault_entries.type = 'deposit' THEN vault_entries.amount WHEN vault_entries.type = 'withdraw' THEN -vault_entries.amount ELSE 0 END), 0) AS total_balance,
        (SELECT COALESCE(SUM(goal_amount), 0) FROM vaults WHERE status = 'active') AS total_goals
      FROM vaults
      LEFT JOIN vault_entries ON vault_entries.vault_id = vaults.id
      WHERE vaults.status = 'active';
    ''');
    final shopRows = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM shop_items WHERE status = 'active') AS active_items,
        (SELECT COUNT(*) FROM shop_purchases) AS purchases,
        (SELECT COALESCE(SUM(coin_cost_paid), 0) FROM shop_purchases) AS coins_spent,
        (SELECT COUNT(*) FROM shop_purchases WHERE type_snapshot = 'real_purchase') AS real_purchases;
    ''');

    final vaultSummary = vaultRows.isEmpty ? <String, Object?>{} : vaultRows.first;
    final campaignProgressRows = await db.rawQuery('''
      SELECT
        COUNT(*) AS total_milestones,
        COALESCE(SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END), 0) AS completed_milestones,
        CAST(COALESCE(AVG(progress), 0) * 100 AS INTEGER) AS progress_percent
      FROM campaign_milestones
      WHERE campaign_id = 'transformation_20_25';
    ''');

    final shopSummary = shopRows.isEmpty ? <String, Object?>{} : shopRows.first;
    final campaignProgress = campaignProgressRows.isEmpty ? <String, Object?>{} : campaignProgressRows.first;
    final hero = heroRows.isEmpty ? <String, Object?>{} : heroRows.first;
    final campaign = campaignRows.isEmpty ? <String, Object?>{} : campaignRows.first;
    final buffer = StringBuffer();

    buffer.writeln('GAME LIFE — RELATÓRIO SIMPLES');
    buffer.writeln('Gerado em: ${DateTime.now().toLocal()}');
    buffer.writeln('');
    buffer.writeln('CAMPANHA');
    buffer.writeln('- ${readString(campaign, 'title', fallback: 'Sem campanha ativa')}');
    buffer.writeln('- Progresso médio: ${readInt(campaignProgress, 'progress_percent')}%');
    buffer.writeln('- Marcos concluídos: ${readInt(campaignProgress, 'completed_milestones')}/${readInt(campaignProgress, 'total_milestones')}');
    buffer.writeln('');
    buffer.writeln('HERÓI');
    buffer.writeln('- Nome: ${readString(hero, 'name', fallback: 'Herói')}');
    buffer.writeln('- Título: ${readString(hero, 'title', fallback: '-')}');
    buffer.writeln('- Nível: ${readInt(hero, 'level')}');
    buffer.writeln('- XP: ${readInt(hero, 'xp')}');
    buffer.writeln('- Coins: ${readInt(hero, 'coins')}');
    buffer.writeln('');
    buffer.writeln('CONTADORES');
    buffer.writeln('- Missões: ${stats.missions}');
    buffer.writeln('- Objetivos: ${stats.objectives}');
    buffer.writeln('- Hábitos: ${stats.habits}');
    buffer.writeln('- Sessões: ${stats.sessions}');
    buffer.writeln('- Projetos: ${stats.projects}');
    buffer.writeln('- Eventos no histórico: ${stats.historyEvents}');
    buffer.writeln('- XP no histórico: ${stats.totalXpHistory}');
    buffer.writeln('- Coins no histórico: ${stats.totalCoinsHistory}');
    buffer.writeln('');
    buffer.writeln('COFRE DO REINO');
    buffer.writeln('- Cofres ativos: ${readInt(vaultSummary, 'active_vaults')}');
    buffer.writeln('- Saldo guardado: ${formatCurrency(readDouble(vaultSummary, 'total_balance'))}');
    buffer.writeln('- Metas declaradas: ${formatCurrency(readDouble(vaultSummary, 'total_goals'))}');
    buffer.writeln('');
    buffer.writeln('LOJA DO REINO');
    buffer.writeln('- Itens ativos: ${readInt(shopSummary, 'active_items')}');
    buffer.writeln('- Compras realizadas: ${readInt(shopSummary, 'purchases')}');
    buffer.writeln('- Coins gastos: ${readInt(shopSummary, 'coins_spent')}');
    buffer.writeln('- Compras reais liberadas: ${readInt(shopSummary, 'real_purchases')}');
    buffer.writeln('');
    buffer.writeln('ATRIBUTOS');
    for (final row in attributeRows) {
      buffer.writeln('- ${readString(row, 'name')}: ${readInt(row, 'points')} pts / ${readInt(row, 'xp')} XP');
    }
    buffer.writeln('');
    buffer.writeln('ÁREAS DA VIDA');
    for (final row in areaRows) {
      buffer.writeln('- ${readString(row, 'name')}: ${readInt(row, 'points')} pts / ${readInt(row, 'xp')} XP');
    }
    buffer.writeln('');
    buffer.writeln('BALANCEAMENTO LITE');
    for (final setting in settings) {
      buffer.writeln('- ${setting.key}: ${setting.value}');
    }
    buffer.writeln('');
    buffer.writeln('HISTÓRICO RECENTE');
    for (final row in recentHistoryRows) {
      buffer.writeln('- ${readString(row, 'title')} | XP ${readInt(row, 'xp_delta')} | Coins ${readInt(row, 'coins_delta')}');
    }
    buffer.writeln('');
    buffer.writeln('BANCO LOCAL');
    buffer.writeln(path);

    return buffer.toString();
  }

  Future<void> ensureDefaultSettings(
    Database db, {
    bool forceDefaults = false,
  }) async {
    final now = DateTime.now().toIso8601String();

    for (final entry in defaultSettings.entries) {
      final values = entry.value;
      await db.insert(
        'settings',
        {
          'key': entry.key,
          'value': values[0],
          'value_type': values[1],
          'description': values[2],
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      if (forceDefaults) {
        await db.update(
          'settings',
          {
            'value': values[0],
            'value_type': values[1],
            'description': values[2],
            'updated_at': now,
          },
          where: 'key = ?',
          whereArgs: [entry.key],
        );
      }
    }
  }

  String _normalizeValue(String rawValue, String valueType) {
    final clean = rawValue.trim().replaceAll(',', '.');

    if (valueType == 'int') {
      final parsed = int.tryParse(clean);
      if (parsed == null) {
        throw ArgumentError('Digite um número inteiro válido.');
      }
      if (parsed < 0) {
        throw ArgumentError('O valor não pode ser negativo.');
      }
      return parsed.toString();
    }

    if (valueType == 'double') {
      final parsed = double.tryParse(clean);
      if (parsed == null) {
        throw ArgumentError('Digite um número decimal válido.');
      }
      if (parsed < 0) {
        throw ArgumentError('O valor não pode ser negativo.');
      }
      return parsed.toString();
    }

    if (clean.isEmpty) {
      throw ArgumentError('O valor não pode ficar vazio.');
    }
    return clean;
  }

  Future<void> _insertSystemHistory(
    Database db, {
    required String title,
    required String description,
  }) async {
    await db.insert(
      'history_events',
      {
        'id': IdGenerator.create('history'),
        'title': title,
        'description': description,
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
