import 'package:sqflite/sqflite.dart';

class DbSeeds {
  static Future<void> run(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v1_done'],
      limit: 1,
    );

    if (seedCheck.isEmpty) {
      final now = DateTime.now().toIso8601String();
      final batch = db.batch();

    final areas = [
      {
        'id': 'body_health',
        'name': 'Corpo e Saúde',
        'description': 'Treino, mobilidade, alimentação, sono e energia física.',
        'color': 'green',
        'icon': 'fitness_center',
        'sort_order': 1,
      },
      {
        'id': 'mind_knowledge',
        'name': 'Mente e Conhecimento',
        'description': 'Estudo, leitura, inglês, programação e clareza mental.',
        'color': 'blue',
        'icon': 'menu_book',
        'sort_order': 2,
      },
      {
        'id': 'spirit_purpose',
        'name': 'Espírito e Propósito',
        'description': 'Vida espiritual, oração, propósito e valores.',
        'color': 'purple',
        'icon': 'auto_awesome',
        'sort_order': 3,
      },
      {
        'id': 'projects_career',
        'name': 'Projetos e Carreira',
        'description': 'Apps, programação, trabalho, portfólio e carreira.',
        'color': 'orange',
        'icon': 'work',
        'sort_order': 4,
      },
      {
        'id': 'creation_expression',
        'name': 'Criação e Expressão',
        'description': 'Arte, música, vídeo, fotografia, escrita e criatividade.',
        'color': 'pink',
        'icon': 'brush',
        'sort_order': 5,
      },
      {
        'id': 'finance_responsibility',
        'name': 'Finanças e Responsabilidade',
        'description': 'Economia, dívidas, reserva, compras e maturidade financeira.',
        'color': 'amber',
        'icon': 'savings',
        'sort_order': 6,
      },
      {
        'id': 'routine_order',
        'name': 'Rotina e Ordem',
        'description': 'Organização, disciplina diária, ambiente e consistência.',
        'color': 'cyan',
        'icon': 'checklist',
        'sort_order': 7,
      },
    ];

    for (final area in areas) {
      batch.insert(
        'areas',
        {
          ...area,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final attributes = [
      {
        'id': 'strength',
        'name': 'Força',
        'description': 'Capacidade física, resistência muscular e evolução corporal.',
        'icon': 'sports_martial_arts',
        'sort_order': 1,
      },
      {
        'id': 'vigor',
        'name': 'Vigor',
        'description': 'Energia, saúde, disposição e vitalidade.',
        'icon': 'bolt',
        'sort_order': 2,
      },
      {
        'id': 'clarity',
        'name': 'Clareza',
        'description': 'Entendimento, leitura, estudo e visão mental.',
        'icon': 'psychology',
        'sort_order': 3,
      },
      {
        'id': 'focus',
        'name': 'Foco',
        'description': 'Atenção, concentração e permanência em tarefas importantes.',
        'icon': 'center_focus_strong',
        'sort_order': 4,
      },
      {
        'id': 'creativity',
        'name': 'Criatividade',
        'description': 'Expressão, criação, arte, design, música e ideias.',
        'icon': 'palette',
        'sort_order': 5,
      },
      {
        'id': 'responsibility',
        'name': 'Responsabilidade',
        'description': 'Finanças, trabalho, compromissos e decisões maduras.',
        'icon': 'account_balance_wallet',
        'sort_order': 6,
      },
      {
        'id': 'discipline',
        'name': 'Disciplina',
        'description': 'Constância, rotina, ordem e execução mesmo sem vontade.',
        'icon': 'verified',
        'sort_order': 7,
      },
      {
        'id': 'faith',
        'name': 'Fé',
        'description': 'Vida espiritual, oração, propósito e firmeza interior.',
        'icon': 'church',
        'sort_order': 8,
      },
    ];

    for (final attribute in attributes) {
      batch.insert(
        'attributes',
        {
          ...attribute,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.insert(
        'hero_attributes',
        {
          'id': 'hero_${attribute['id']}',
          'attribute_id': attribute['id'],
          'points': 0,
          'xp': 0,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final links = [
      ['body_health', 'strength'],
      ['body_health', 'vigor'],
      ['body_health', 'discipline'],
      ['mind_knowledge', 'clarity'],
      ['mind_knowledge', 'focus'],
      ['spirit_purpose', 'faith'],
      ['spirit_purpose', 'discipline'],
      ['projects_career', 'focus'],
      ['projects_career', 'responsibility'],
      ['creation_expression', 'creativity'],
      ['finance_responsibility', 'responsibility'],
      ['routine_order', 'discipline'],
    ];

    for (final link in links) {
      batch.insert(
        'area_attribute_links',
        {
          'area_id': link[0],
          'attribute_id': link[1],
          'weight': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.insert(
      'hero_profiles',
      {
        'id': 'main_hero',
        'name': 'Herói da Jornada',
        'level': 1,
        'xp': 0,
        'coins': 0,
        'title': 'Iniciante da Transformação',
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'campaigns',
      {
        'id': 'transformation_20_25',
        'title': 'Transformação 20–25',
        'description':
            'Campanha principal de evolução pessoal com foco em corpo, mente, disciplina, espiritualidade, finanças e projetos.',
        'start_date': now,
        'end_date': null,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    final settings = {
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
      'coins_easy': ['3', 'int', 'Coins para missão fácil.'],
      'coins_normal': ['5', 'int', 'Coins para missão normal.'],
      'coins_medium': ['7', 'int', 'Coins para missão média.'],
      'coins_hard': ['10', 'int', 'Coins para missão difícil.'],
      'coins_very_hard': ['15', 'int', 'Coins para missão muito difícil.'],
      'session_xp_per_15min': [
        '5',
        'int',
        'XP por bloco de 15 minutos em sessões.',
      ],
      'objective_completion_multiplier': [
        '1.0',
        'double',
        'Multiplicador de recompensa ao concluir objetivo.',
      ],
    };

    for (final entry in settings.entries) {
      batch.insert(
        'settings',
        {
          'key': entry.key,
          'value': entry.value[0],
          'value_type': entry.value[1],
          'description': entry.value[2],
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.insert(
      'history_events',
      {
        'id': 'history_welcome',
        'title': 'Jornada iniciada',
        'description': 'A fundação do Game Life Flutter foi criada.',
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'app_meta',
      {
        'key': 'seed_v1_done',
        'value': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

      await batch.commit(noResult: true);
    }

    await _runV3Seeds(db);
    await _runV35Seeds(db);
    await _runV36Seeds(db);
    await _runV37Seeds(db);
    await _runV38Seeds(db);
    await _runV39Seeds(db);
    await _runV310Seeds(db);
    await _runV311Seeds(db);
    await _runV312Seeds(db);
    await _runV41Seeds(db);
    await _runV43Seeds(db);
    await _runV44Seeds(db);
  }

  static Future<void> _runV3Seeds(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v3_commitment_done'],
      limit: 1,
    );

    if (seedCheck.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    final difficulties = [
      {
        'id': 'difficulty_normal',
        'code': 'normal',
        'name': 'Normal',
        'description': 'Modo leve: falhar uma missão não gera penalidade de XP.',
        'penalty_percent': 0,
        'allow_custom_rewards': 1,
      },
      {
        'id': 'difficulty_hard',
        'code': 'hard',
        'name': 'Difícil',
        'description': 'Modo de compromisso: falhas podem gerar penalidade parcial de XP.',
        'penalty_percent': 50,
        'allow_custom_rewards': 1,
      },
      {
        'id': 'difficulty_hardcore',
        'code': 'hardcore',
        'name': 'Hardcore',
        'description': 'Modo de alta disciplina: falhas podem gerar penalidade total de XP.',
        'penalty_percent': 100,
        'allow_custom_rewards': 0,
      },
    ];

    for (final difficulty in difficulties) {
      batch.insert(
        'difficulty_profiles',
        {
          ...difficulty,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final settings = {
      'active_difficulty_mode': ['normal', 'string', 'Modo de dificuldade ativo da campanha atual.'],
      'checkin_daily_coins': ['3', 'int', 'Coins recebidos no check-in diário.'],
      'checkin_streak_bonus_7': ['10', 'int', 'Bônus de coins ao completar 7 dias de sequência.'],
      'checkin_streak_bonus_30': ['40', 'int', 'Bônus de coins ao completar 30 dias de sequência.'],
      'mission_failure_penalty_enabled': ['true', 'bool', 'Ativa penalidades por falha de missão nos modos Difícil e Hardcore.'],
      'mission_max_attributes': ['3', 'int', 'Quantidade máxima de atributos por missão, objetivo ou sessão.'],
      'reminder_checkin_enabled': ['true', 'bool', 'Ativa lembrete simples de check-in diário.'],
      'reminder_daily_missions_enabled': ['true', 'bool', 'Ativa lembrete simples de missões diárias.'],
      'session_timer_enabled': ['true', 'bool', 'Ativa a base do timer real de sessão.'],
    };

    for (final entry in settings.entries) {
      batch.insert(
        'settings',
        {
          'key': entry.key,
          'value': entry.value[0],
          'value_type': entry.value[1],
          'description': entry.value[2],
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final achievements = [
      {
        'id': 'achievement_first_checkin',
        'code': 'first_checkin',
        'title': 'Primeiro check-in',
        'description': 'Faça seu primeiro check-in diário.',
        'icon': 'today',
        'category': 'checkin',
        'target_value': 1,
        'xp_reward': 0,
        'coins_reward': 5,
      },
      {
        'id': 'achievement_streak_7',
        'code': 'streak_7',
        'title': '7 dias de sequência',
        'description': 'Mantenha uma sequência de 7 dias de check-in.',
        'icon': 'local_fire_department',
        'category': 'streak',
        'target_value': 7,
        'xp_reward': 25,
        'coins_reward': 10,
      },
      {
        'id': 'achievement_streak_30',
        'code': 'streak_30',
        'title': '30 dias de disciplina',
        'description': 'Mantenha uma sequência de 30 dias de check-in.',
        'icon': 'military_tech',
        'category': 'streak',
        'target_value': 30,
        'xp_reward': 100,
        'coins_reward': 40,
      },
      {
        'id': 'achievement_first_mission',
        'code': 'first_mission_completed',
        'title': 'Primeira missão',
        'description': 'Conclua sua primeira missão.',
        'icon': 'flag',
        'category': 'mission',
        'target_value': 1,
        'xp_reward': 10,
        'coins_reward': 5,
      },
      {
        'id': 'achievement_10_missions',
        'code': 'missions_10_completed',
        'title': '10 missões concluídas',
        'description': 'Conclua 10 missões.',
        'icon': 'verified',
        'category': 'mission',
        'target_value': 10,
        'xp_reward': 50,
        'coins_reward': 15,
      },
      {
        'id': 'achievement_first_objective',
        'code': 'first_objective_completed',
        'title': 'Primeiro objetivo',
        'description': 'Conclua seu primeiro objetivo mensurável.',
        'icon': 'track_changes',
        'category': 'objective',
        'target_value': 1,
        'xp_reward': 25,
        'coins_reward': 10,
      },
      {
        'id': 'achievement_first_project',
        'code': 'first_project_completed',
        'title': 'Primeiro projeto',
        'description': 'Conclua seu primeiro projeto.',
        'icon': 'folder_special',
        'category': 'project',
        'target_value': 1,
        'xp_reward': 50,
        'coins_reward': 20,
      },
      {
        'id': 'achievement_10_sessions',
        'code': 'sessions_10_registered',
        'title': '10 sessões registradas',
        'description': 'Registre 10 sessões de foco.',
        'icon': 'timer',
        'category': 'session',
        'target_value': 10,
        'xp_reward': 30,
        'coins_reward': 10,
      },
      {
        'id': 'achievement_10_focus_hours',
        'code': 'focus_hours_10',
        'title': '10 horas de foco',
        'description': 'Acumule 10 horas em sessões registradas.',
        'icon': 'hourglass_bottom',
        'category': 'session',
        'target_value': 600,
        'xp_reward': 80,
        'coins_reward': 25,
      },
      {
        'id': 'achievement_first_milestone',
        'code': 'first_campaign_milestone',
        'title': 'Primeiro marco',
        'description': 'Conclua o primeiro marco da campanha.',
        'icon': 'emoji_events',
        'category': 'campaign',
        'target_value': 1,
        'xp_reward': 100,
        'coins_reward': 30,
      },
    ];

    for (final achievement in achievements) {
      batch.insert(
        'achievements',
        {
          ...achievement,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.insert(
        'hero_achievements',
        {
          'id': 'hero_${achievement['code']}',
          'achievement_id': achievement['id'],
          'progress_value': 0,
          'is_unlocked': 0,
          'unlocked_at': null,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.update(
      'campaigns',
      {
        'lore': 'Uma jornada pessoal de disciplina, crescimento e transformação contínua.',
        'main_goal': 'Construir uma base forte de corpo, mente, fé, finanças e projetos.',
        'victory_minimum_percent': 60,
        'victory_good_percent': 75,
        'victory_excellent_percent': 90,
        'difficulty_mode': 'normal',
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: ['transformation_20_25'],
    );

    final milestones = [
      {
        'id': 'milestone_reset_foundation',
        'title': 'Fundação inicial',
        'description': 'Organizar a base da rotina e iniciar a transformação com consistência.',
        'sort_order': 1,
      },
      {
        'id': 'milestone_body_mind',
        'title': 'Corpo e mente em movimento',
        'description': 'Consolidar hábitos físicos, estudo, clareza e energia diária.',
        'sort_order': 2,
      },
      {
        'id': 'milestone_projects_finance',
        'title': 'Projetos e responsabilidade',
        'description': 'Avançar em projetos pessoais, carreira e organização financeira.',
        'sort_order': 3,
      },
    ];

    for (final milestone in milestones) {
      batch.insert(
        'campaign_milestones',
        {
          ...milestone,
          'campaign_id': 'transformation_20_25',
          'lore': null,
          'target_date': null,
          'status': 'active',
          'progress': 0.0,
          'xp_reward': 100,
          'coins_reward': 25,
          'completed_at': null,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.insert(
      'reminder_configs',
      {
        'id': 'reminder_checkin_daily',
        'item_type': 'system',
        'item_id': 'daily_checkin',
        'title': 'Check-in diário',
        'body': 'Entre no Game Life e mantenha sua sequência ativa.',
        'reminder_type': 'checkin',
        'time_of_day': '08:00',
        'scheduled_date': null,
        'is_enabled': 1,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'history_events',
      {
        'id': 'history_v3_foundation',
        'title': 'Fundação de compromisso preparada',
        'description': 'A estrutura técnica da V3 foi criada para campanha, check-in, conquistas, dificuldade e missões compostas.',
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'app_meta',
      {
        'key': 'seed_v3_commitment_done',
        'value': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await batch.commit(noResult: true);
  }

  static Future<void> _runV35Seeds(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v35_habits_done'],
      limit: 1,
    );

    if (seedCheck.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    final settings = {
      'habit_xp_default': ['8', 'int', 'XP padrão para hábitos simples.'],
      'habit_xp_weekly_default': ['12', 'int', 'XP padrão para hábitos semanais.'],
      'habit_coin_default': ['0', 'int', 'Coins padrão para hábitos.'],
      'habit_max_attributes': ['3', 'int', 'Quantidade máxima de atributos por hábito.'],
    };

    for (final entry in settings.entries) {
      batch.insert(
        'settings',
        {
          'key': entry.key,
          'value': entry.value[0],
          'value_type': entry.value[1],
          'description': entry.value[2],
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final habits = [
      {
        'id': 'habit_water_base',
        'title': 'Beber água',
        'description': 'Construir uma base mínima de hidratação sem exagero inicial.',
        'type': 'build',
        'frequency': 'daily',
        'unit': 'ml',
        'target_value': 1000.0,
        'limit_value': 0.0,
        'area_id': 'body_health',
        'attribute_id': 'vigor',
        'xp_reward': 8,
        'coins_reward': 0,
        'attributes': ['vigor', 'discipline'],
      },
      {
        'id': 'habit_bible_reading_base',
        'title': 'Leitura bíblica simples',
        'description': 'Registrar presença espiritual diária, mesmo que seja uma leitura curta.',
        'type': 'build',
        'frequency': 'daily',
        'unit': 'check',
        'target_value': 1.0,
        'limit_value': 0.0,
        'area_id': 'spirit_purpose',
        'attribute_id': 'faith',
        'xp_reward': 8,
        'coins_reward': 0,
        'attributes': ['faith', 'discipline'],
      },
      {
        'id': 'habit_body_movement_base',
        'title': 'Mover o corpo',
        'description': 'Caminhada, alongamento ou treino leve para sair do sedentarismo.',
        'type': 'build',
        'frequency': 'daily',
        'unit': 'minutes',
        'target_value': 10.0,
        'limit_value': 0.0,
        'area_id': 'body_health',
        'attribute_id': 'strength',
        'xp_reward': 8,
        'coins_reward': 0,
        'attributes': ['strength', 'vigor', 'discipline'],
      },
      {
        'id': 'habit_soda_reduce_base',
        'title': 'Reduzir refrigerante',
        'description': 'Começar reduzindo aos poucos em vez de cortar de uma vez.',
        'type': 'reduce',
        'frequency': 'weekly',
        'unit': 'times',
        'target_value': 1.0,
        'limit_value': 4.0,
        'area_id': 'body_health',
        'attribute_id': 'discipline',
        'xp_reward': 12,
        'coins_reward': 0,
        'attributes': ['discipline', 'vigor'],
      },
      {
        'id': 'habit_ultra_processed_reduce_base',
        'title': 'Controlar doces e ultraprocessados',
        'description': 'Mapear doces, salgados, bolachas recheadas e exageros da semana.',
        'type': 'reduce',
        'frequency': 'weekly',
        'unit': 'times',
        'target_value': 1.0,
        'limit_value': 5.0,
        'area_id': 'body_health',
        'attribute_id': 'discipline',
        'xp_reward': 12,
        'coins_reward': 0,
        'attributes': ['discipline', 'vigor'],
      },
    ];

    for (final habit in habits) {
      final attributes = List<String>.from(habit['attributes']! as List);
      final habitId = habit['id']! as String;

      batch.insert(
        'habits',
        {
          'id': habitId,
          'title': habit['title'],
          'description': habit['description'],
          'type': habit['type'],
          'frequency': habit['frequency'],
          'unit': habit['unit'],
          'target_value': habit['target_value'],
          'limit_value': habit['limit_value'],
          'area_id': habit['area_id'],
          'attribute_id': habit['attribute_id'],
          'xp_reward': habit['xp_reward'],
          'coins_reward': habit['coins_reward'],
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      final weights = attributes.length == 1
          ? [100]
          : attributes.length == 2
              ? [70, 30]
              : [50, 30, 20];

      for (var index = 0; index < attributes.length; index++) {
        batch.insert(
          'item_attribute_links',
          {
            'id': 'attr_link_${habitId}_${attributes[index]}',
            'item_type': 'habit',
            'item_id': habitId,
            'attribute_id': attributes[index],
            'weight': weights[index],
            'is_primary': index == 0 ? 1 : 0,
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    batch.insert(
      'history_events',
      {
        'id': 'history_v35_habits',
        'title': 'Sistema de hábitos preparado',
        'description': 'Hábitos de construção e redução gradual foram adicionados ao Game Life.',
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'app_meta',
      {
        'key': 'seed_v35_habits_done',
        'value': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await batch.commit(noResult: true);
  }


  static Future<void> _runV36Seeds(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v36_health_done'],
      limit: 1,
    );

    if (seedCheck.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    final settings = {
      'health_water_default_ml': ['1000', 'int', 'Meta inicial diária de água em ml.'],
      'health_water_quick_small_ml': ['250', 'int', 'Atalho pequeno de registro de água.'],
      'health_water_quick_medium_ml': ['500', 'int', 'Atalho médio de registro de água.'],
      'health_water_quick_large_ml': ['1000', 'int', 'Atalho grande de registro de água.'],
      'health_food_limit_default_weekly': ['5', 'int', 'Limite semanal padrão para rastreadores alimentares.'],
    };

    for (final entry in settings.entries) {
      batch.insert(
        'settings',
        {
          'key': entry.key,
          'value': entry.value[0],
          'value_type': entry.value[1],
          'description': entry.value[2],
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final healthHabits = [
      {
        'id': 'habit_water_base',
        'title': 'Beber água',
        'description': 'Construir uma base mínima de hidratação sem exagero inicial.',
        'type': 'build',
        'frequency': 'daily',
        'unit': 'ml',
        'target_value': 1000.0,
        'limit_value': 0.0,
        'area_id': 'body_health',
        'attribute_id': 'vigor',
        'xp_reward': 8,
        'coins_reward': 0,
        'health_kind': 'water',
        'health_category': 'water',
        'attributes': ['vigor', 'discipline'],
      },
      {
        'id': 'habit_soda_reduce_base',
        'title': 'Reduzir refrigerante',
        'description': 'Começar reduzindo aos poucos em vez de cortar de uma vez.',
        'type': 'reduce',
        'frequency': 'weekly',
        'unit': 'times',
        'target_value': 1.0,
        'limit_value': 4.0,
        'area_id': 'body_health',
        'attribute_id': 'discipline',
        'xp_reward': 12,
        'coins_reward': 0,
        'health_kind': 'food_limit',
        'health_category': 'soda',
        'attributes': ['discipline', 'vigor'],
      },
      {
        'id': 'habit_ultra_processed_reduce_base',
        'title': 'Controlar doces e ultraprocessados',
        'description': 'Mapear doces, salgados, bolachas recheadas e exageros da semana sem corte radical.',
        'type': 'reduce',
        'frequency': 'weekly',
        'unit': 'times',
        'target_value': 1.0,
        'limit_value': 5.0,
        'area_id': 'body_health',
        'attribute_id': 'discipline',
        'xp_reward': 12,
        'coins_reward': 0,
        'health_kind': 'food_limit',
        'health_category': 'ultra_processed',
        'attributes': ['discipline', 'vigor'],
      },
      {
        'id': 'habit_salty_fast_food_reduce_base',
        'title': 'Controlar salgados e fast-food',
        'description': 'Registrar lanches pesados, salgados e fast-food para reduzir com constância.',
        'type': 'reduce',
        'frequency': 'weekly',
        'unit': 'times',
        'target_value': 1.0,
        'limit_value': 3.0,
        'area_id': 'body_health',
        'attribute_id': 'discipline',
        'xp_reward': 12,
        'coins_reward': 0,
        'health_kind': 'food_limit',
        'health_category': 'fast_food',
        'attributes': ['discipline', 'vigor'],
      },
    ];

    for (final habit in healthHabits) {
      final habitId = habit['id']! as String;
      final attributes = List<String>.from(habit['attributes']! as List);

      batch.insert(
        'habits',
        {
          'id': habitId,
          'title': habit['title'],
          'description': habit['description'],
          'type': habit['type'],
          'frequency': habit['frequency'],
          'unit': habit['unit'],
          'target_value': habit['target_value'],
          'limit_value': habit['limit_value'],
          'area_id': habit['area_id'],
          'attribute_id': habit['attribute_id'],
          'xp_reward': habit['xp_reward'],
          'coins_reward': habit['coins_reward'],
          'health_kind': habit['health_kind'],
          'health_category': habit['health_category'],
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.update(
        'habits',
        {
          'health_kind': habit['health_kind'],
          'health_category': habit['health_category'],
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [habitId],
      );

      final weights = attributes.length == 1
          ? [100]
          : attributes.length == 2
              ? [70, 30]
              : [50, 30, 20];

      for (var index = 0; index < attributes.length; index++) {
        batch.insert(
          'item_attribute_links',
          {
            'id': 'attr_link_${habitId}_${attributes[index]}',
            'item_type': 'habit',
            'item_id': habitId,
            'attribute_id': attributes[index],
            'weight': weights[index],
            'is_primary': index == 0 ? 1 : 0,
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    batch.insert(
      'history_events',
      {
        'id': 'history_v36_health',
        'title': 'Saúde prática preparada',
        'description': 'Painel de água e alimentação gradual foi conectado aos hábitos de saúde.',
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'app_meta',
      {
        'key': 'seed_v36_health_done',
        'value': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await batch.commit(noResult: true);
  }


  static Future<void> _runV37Seeds(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v37_difficulty_progression_done'],
      limit: 1,
    );

    if (seedCheck.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    final settings = {
      'level_curve_multiplier_normal': [
        '1.0',
        'double',
        'Multiplicador da curva de XP no modo Normal.',
      ],
      'level_curve_multiplier_hard': [
        '1.25',
        'double',
        'Multiplicador da curva de XP no modo Difícil.',
      ],
      'level_curve_multiplier_hardcore': [
        '1.5',
        'double',
        'Multiplicador da curva de XP no modo Hardcore.',
      ],
      'hero_max_level': [
        '100',
        'int',
        'Nível máximo do herói nesta fase do app.',
      ],
      'mission_failure_penalty_enabled': [
        'true',
        'bool',
        'Ativa penalidades por falha de missão nos modos Difícil e Hardcore.',
      ],
    };

    for (final entry in settings.entries) {
      batch.insert(
        'settings',
        {
          'key': entry.key,
          'value': entry.value[0],
          'value_type': entry.value[1],
          'description': entry.value[2],
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.update(
      'settings',
      {
        'value': 'true',
        'description': 'Ativa penalidades por falha de missão nos modos Difícil e Hardcore.',
        'updated_at': now,
      },
      where: 'key = ?',
      whereArgs: ['mission_failure_penalty_enabled'],
    );

    batch.insert(
      'app_meta',
      {
        'key': 'seed_v37_difficulty_progression_done',
        'value': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await batch.commit(noResult: true);
  }


  static Future<void> _runV38Seeds(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v38_achievements_done'],
      limit: 1,
    );

    if (seedCheck.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    final achievements = [
      {
        'id': 'achievement_first_checkin',
        'code': 'first_checkin',
        'title': 'Primeiro check-in',
        'description': 'Faça seu primeiro check-in diário.',
        'icon': 'today',
        'category': 'checkin',
        'target_value': 1,
        'xp_reward': 5,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_streak_7',
        'code': 'streak_7',
        'title': 'Chama de 7 dias',
        'description': 'Mantenha uma sequência de 7 dias de check-in.',
        'icon': 'local_fire_department',
        'category': 'checkin',
        'target_value': 7,
        'xp_reward': 10,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_streak_30',
        'code': 'streak_30',
        'title': '30 dias de disciplina',
        'description': 'Mantenha uma sequência de 30 dias de check-in.',
        'icon': 'military_tech',
        'category': 'checkin',
        'target_value': 30,
        'xp_reward': 20,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_first_mission',
        'code': 'first_mission_completed',
        'title': 'Primeira missão',
        'description': 'Conclua sua primeira missão.',
        'icon': 'flag',
        'category': 'mission',
        'target_value': 1,
        'xp_reward': 5,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_first_compound_mission',
        'code': 'first_compound_mission_completed',
        'title': 'Checklist vencido',
        'description': 'Conclua sua primeira missão composta com subtarefas.',
        'icon': 'checklist',
        'category': 'mission',
        'target_value': 1,
        'xp_reward': 8,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_10_missions',
        'code': 'missions_10_completed',
        'title': '10 missões concluídas',
        'description': 'Conclua 10 missões.',
        'icon': 'verified',
        'category': 'mission',
        'target_value': 10,
        'xp_reward': 10,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_50_missions',
        'code': 'missions_50_completed',
        'title': 'Executor consistente',
        'description': 'Conclua 50 missões ao longo da jornada.',
        'icon': 'workspace_premium',
        'category': 'mission',
        'target_value': 50,
        'xp_reward': 20,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_first_objective',
        'code': 'first_objective_completed',
        'title': 'Primeiro objetivo',
        'description': 'Conclua seu primeiro objetivo mensurável.',
        'icon': 'track_changes',
        'category': 'objective',
        'target_value': 1,
        'xp_reward': 8,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_5_objectives',
        'code': 'objectives_5_completed',
        'title': 'Meta atrás de meta',
        'description': 'Conclua 5 objetivos mensuráveis.',
        'icon': 'add_chart',
        'category': 'objective',
        'target_value': 5,
        'xp_reward': 15,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_first_session',
        'code': 'sessions_first_registered',
        'title': 'Primeira sessão de foco',
        'description': 'Registre sua primeira sessão manual ou cronometrada.',
        'icon': 'timer',
        'category': 'session',
        'target_value': 1,
        'xp_reward': 5,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_10_sessions',
        'code': 'sessions_10_registered',
        'title': '10 sessões registradas',
        'description': 'Registre 10 sessões de foco.',
        'icon': 'timer',
        'category': 'session',
        'target_value': 10,
        'xp_reward': 10,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_10_focus_hours',
        'code': 'focus_hours_10',
        'title': '10 horas de foco',
        'description': 'Acumule 10 horas em sessões registradas.',
        'icon': 'hourglass_bottom',
        'category': 'session',
        'target_value': 600,
        'xp_reward': 20,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_habit_first_reward',
        'code': 'habit_first_reward',
        'title': 'Primeiro hábito consolidado',
        'description': 'Receba a primeira recompensa de período por um hábito.',
        'icon': 'repeat',
        'category': 'habit',
        'target_value': 1,
        'xp_reward': 5,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_habits_7_rewards',
        'code': 'habits_7_rewards',
        'title': 'Ritmo semanal vivo',
        'description': 'Receba 7 recompensas de hábitos.',
        'icon': 'task_alt',
        'category': 'habit',
        'target_value': 7,
        'xp_reward': 15,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_water_7_days',
        'code': 'water_7_days',
        'title': 'Fonte do Reino',
        'description': 'Registre água em 7 dias diferentes.',
        'icon': 'water_drop',
        'category': 'health',
        'target_value': 7,
        'xp_reward': 10,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_food_limit_7_periods',
        'code': 'food_limit_7_periods',
        'title': 'Domínio do apetite',
        'description': 'Finalize 7 períodos de alimentação dentro do limite.',
        'icon': 'restaurant',
        'category': 'health',
        'target_value': 7,
        'xp_reward': 15,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_10_project_tasks',
        'code': 'project_tasks_10_completed',
        'title': '10 tarefas de projeto',
        'description': 'Conclua 10 tarefas em projetos.',
        'icon': 'checklist',
        'category': 'project',
        'target_value': 10,
        'xp_reward': 10,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_25_project_tasks',
        'code': 'project_tasks_25_completed',
        'title': 'Obreiro de projetos',
        'description': 'Conclua 25 tarefas em projetos.',
        'icon': 'construction',
        'category': 'project',
        'target_value': 25,
        'xp_reward': 18,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_first_project',
        'code': 'first_project_completed',
        'title': 'Primeiro projeto',
        'description': 'Conclua seu primeiro projeto.',
        'icon': 'folder_special',
        'category': 'project',
        'target_value': 1,
        'xp_reward': 15,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_first_milestone',
        'code': 'first_campaign_milestone',
        'title': 'Primeiro marco da campanha',
        'description': 'Conclua o primeiro marco da campanha.',
        'icon': 'emoji_events',
        'category': 'campaign',
        'target_value': 1,
        'xp_reward': 20,
        'coins_reward': 0,
      },
    ];

    for (final achievement in achievements) {
      batch.insert(
        'achievements',
        {
          ...achievement,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.update(
        'achievements',
        {
          'title': achievement['title'],
          'description': achievement['description'],
          'icon': achievement['icon'],
          'category': achievement['category'],
          'target_value': achievement['target_value'],
          'xp_reward': achievement['xp_reward'],
          'coins_reward': achievement['coins_reward'],
          'is_active': 1,
          'updated_at': now,
        },
        where: 'code = ?',
        whereArgs: [achievement['code']],
      );

      batch.insert(
        'hero_achievements',
        {
          'id': 'hero_${achievement['code']}',
          'achievement_id': achievement['id'],
          'progress_value': 0,
          'is_unlocked': 0,
          'unlocked_at': null,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.insert(
      'history_events',
      {
        'id': 'history_v38_achievements',
        'title': 'Conquistas base preparadas',
        'description': 'O Game Life agora acompanha conquistas automáticas de check-in, missões, hábitos, saúde, foco, objetivos e projetos.',
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'app_meta',
      {
        'key': 'seed_v38_achievements_done',
        'value': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await batch.commit(noResult: true);
  }


  static Future<void> _runV39Seeds(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v39_vaults_done'],
      limit: 1,
    );

    if (seedCheck.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    final achievements = [
      {
        'id': 'achievement_first_vault_created',
        'code': 'first_vault_created',
        'title': 'Cofre aberto',
        'description': 'Crie seu primeiro cofre financeiro.',
        'icon': 'savings',
        'category': 'finance',
        'target_value': 1,
        'xp_reward': 5,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_first_vault_deposit',
        'code': 'first_vault_deposit',
        'title': 'Primeiro depósito',
        'description': 'Registre seu primeiro dinheiro guardado no Cofre do Reino.',
        'icon': 'account_balance_wallet',
        'category': 'finance',
        'target_value': 1,
        'xp_reward': 8,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_vault_saved_100',
        'code': 'vault_saved_100',
        'title': 'Primeiros R\$ 100 guardados',
        'description': 'Acumule R\$ 100,00 guardados nos cofres ativos.',
        'icon': 'payments',
        'category': 'finance',
        'target_value': 100,
        'xp_reward': 15,
        'coins_reward': 0,
      },
    ];

    for (final achievement in achievements) {
      batch.insert(
        'achievements',
        {
          ...achievement,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.insert(
        'hero_achievements',
        {
          'id': 'hero_${achievement['code']}',
          'achievement_id': achievement['id'],
          'progress_value': 0,
          'is_unlocked': 0,
          'unlocked_at': null,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.insert(
      'history_events',
      {
        'id': 'history_v39_vaults',
        'title': 'Cofre do Reino preparado',
        'description': 'Sistema financeiro básico adicionado para registrar dinheiro real guardado fora do app.',
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'app_meta',
      {
        'key': 'seed_v39_vaults_done',
        'value': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await batch.commit(noResult: true);
  }


  static Future<void> _runV310Seeds(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v310_shop_done'],
      limit: 1,
    );

    if (seedCheck.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    final items = [
      {
        'id': 'shop_reward_2h_games',
        'title': 'Voucher: 2h de jogatina',
        'description': 'Recompensa planejada para jogar sem culpa, com começo e fim definidos.',
        'type': 'reward',
        'coin_cost': 80,
        'required_money_amount': 0,
        'linked_vault_id': null,
        'icon': 'sports_esports',
        'color': 'purple',
      },
      {
        'id': 'shop_reward_movie_night',
        'title': 'Noite de filme ou anime',
        'description': 'Uma sessão de descanso planejado depois de batalhar de verdade.',
        'type': 'reward',
        'coin_cost': 60,
        'required_money_amount': 0,
        'linked_vault_id': null,
        'icon': 'movie',
        'color': 'blue',
      },
      {
        'id': 'shop_reward_free_time',
        'title': '1h de tempo livre premium',
        'description': 'Uma hora livre para lazer leve, sem virar fuga da rotina.',
        'type': 'reward',
        'coin_cost': 40,
        'required_money_amount': 0,
        'linked_vault_id': null,
        'icon': 'self_improvement',
        'color': 'green',
      },
      {
        'id': 'shop_real_gamepad',
        'title': 'Comprar GamePad',
        'description': 'Compra real planejada. Vincule um cofre com o valor necessário antes de liberar.',
        'type': 'real_purchase',
        'coin_cost': 500,
        'required_money_amount': 150,
        'linked_vault_id': null,
        'icon': 'shopping_bag',
        'color': 'amber',
      },
    ];

    for (final item in items) {
      batch.insert(
        'shop_items',
        {
          ...item,
          'status': 'active',
          'created_at': now,
          'updated_at': now,
          'archived_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final achievements = [
      {
        'id': 'achievement_first_shop_purchase',
        'code': 'first_shop_purchase',
        'title': 'Primeira compra na loja',
        'description': 'Compre sua primeira recompensa usando coins.',
        'icon': 'storefront',
        'category': 'shop',
        'target_value': 1,
        'xp_reward': 8,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_first_real_purchase',
        'code': 'first_real_purchase',
        'title': 'Compra real responsável',
        'description': 'Libere sua primeira compra real com coins e requisito do cofre cumprido.',
        'icon': 'shopping_bag',
        'category': 'finance',
        'target_value': 1,
        'xp_reward': 15,
        'coins_reward': 0,
      },
    ];

    for (final achievement in achievements) {
      batch.insert(
        'achievements',
        {
          ...achievement,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.insert(
        'hero_achievements',
        {
          'id': 'hero_${achievement['code']}',
          'achievement_id': achievement['id'],
          'progress_value': 0,
          'is_unlocked': 0,
          'unlocked_at': null,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.insert(
      'history_events',
      {
        'id': 'history_v310_shop',
        'title': 'Loja do Reino preparada',
        'description': 'Sistema de recompensas e compras planejadas adicionado ao Game Life.',
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'app_meta',
      {
        'key': 'seed_v310_shop_done',
        'value': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await batch.commit(noResult: true);
  }


  static Future<void> _runV311Seeds(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v311_campaign_main_done'],
      limit: 1,
    );

    if (seedCheck.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    batch.update(
      'campaigns',
      {
        'title': 'Transformação dos 20 aos 25',
        'description': 'Campanha principal de evolução pessoal com foco em saúde, fé, programação, finanças, projetos e disciplina real.',
        'lore': 'Uma jornada de cinco anos para sair do automático e construir uma vida mais forte, lúcida e responsável.',
        'main_goal': 'Chegar aos 25 anos com saúde melhor, disciplina real, carreira/projetos encaminhados, fé fortalecida e vida financeira mais madura.',
        'start_date': '2026-07-13',
        'end_date': '2031-07-13',
        'victory_minimum_percent': 60,
        'victory_good_percent': 75,
        'victory_excellent_percent': 90,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: ['transformation_20_25'],
    );

    final milestones = [
      {
        'id': 'milestone_reset_foundation',
        'title': 'Fundação inicial',
        'description': 'Construir presença diária, primeiras missões e hábitos básicos sem radicalismo.',
        'lore': 'O herói sai do modo automático e começa a erguer o acampamento da campanha.',
        'sort_order': 1,
        'automation_key': 'foundation',
        'xp_reward': 100,
        'coins_reward': 20,
      },
      {
        'id': 'milestone_body_mind',
        'title': 'Corpo em movimento',
        'description': 'Evoluir água, alimentação, sessões e atributos ligados à saúde física.',
        'lore': 'A armadura começa a pesar menos quando o corpo volta a acordar.',
        'sort_order': 2,
        'automation_key': 'body_health',
        'xp_reward': 120,
        'coins_reward': 25,
      },
      {
        'id': 'milestone_mind_programming',
        'title': 'Mente e programação',
        'description': 'Transformar sessões, objetivos e tarefas em avanço real nos estudos e no código.',
        'lore': 'O grimório abre: foco, clareza e prática viram poder acumulado.',
        'sort_order': 3,
        'automation_key': 'mind_programming',
        'xp_reward': 140,
        'coins_reward': 30,
      },
      {
        'id': 'milestone_faith_purpose',
        'title': 'Fé e propósito',
        'description': 'Fortalecer presença, constância e o atributo Fé como base interna da jornada.',
        'lore': 'Sem direção, força vira barulho. Com propósito, até passo pequeno vira marcha.',
        'sort_order': 4,
        'automation_key': 'faith_purpose',
        'xp_reward': 120,
        'coins_reward': 20,
      },
      {
        'id': 'milestone_projects_finance',
        'title': 'Projetos e responsabilidade',
        'description': 'Unir tarefas de projeto, cofre, compras planejadas e responsabilidade financeira.',
        'lore': 'O reino começa a ter obra, cofre e decisões menos impulsivas.',
        'sort_order': 5,
        'automation_key': 'projects_finance',
        'xp_reward': 160,
        'coins_reward': 35,
      },
      {
        'id': 'milestone_campaign_consolidation',
        'title': 'Consolidação da campanha',
        'description': 'Amarrar conquistas, atributos, foco, missões e hábitos em consistência visível.',
        'lore': 'A jornada deixa de ser empolgação inicial e vira identidade praticada.',
        'sort_order': 6,
        'automation_key': 'campaign_consolidation',
        'xp_reward': 200,
        'coins_reward': 50,
      },
    ];

    for (final milestone in milestones) {
      batch.insert(
        'campaign_milestones',
        {
          ...milestone,
          'campaign_id': 'transformation_20_25',
          'target_date': null,
          'status': 'active',
          'progress': 0.0,
          'auto_progress_enabled': 1,
          'progress_note': null,
          'completed_at': null,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.update(
        'campaign_milestones',
        {
          'title': milestone['title'],
          'description': milestone['description'],
          'lore': milestone['lore'],
          'sort_order': milestone['sort_order'],
          'automation_key': milestone['automation_key'],
          'auto_progress_enabled': 1,
          'xp_reward': milestone['xp_reward'],
          'coins_reward': milestone['coins_reward'],
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [milestone['id']],
      );
    }

    final achievements = [
      {
        'id': 'achievement_campaign_progress_25',
        'code': 'campaign_progress_25',
        'title': 'Campanha em marcha',
        'description': 'Alcance 25% de progresso médio nos marcos da campanha principal.',
        'icon': 'route',
        'category': 'campaign',
        'target_value': 25,
        'xp_reward': 15,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_campaign_progress_50',
        'code': 'campaign_progress_50',
        'title': 'Meia jornada vencida',
        'description': 'Alcance 50% de progresso médio nos marcos da campanha principal.',
        'icon': 'flag_circle',
        'category': 'campaign',
        'target_value': 50,
        'xp_reward': 20,
        'coins_reward': 0,
      },
      {
        'id': 'achievement_campaign_progress_90',
        'code': 'campaign_progress_90',
        'title': 'Vitória excelente à vista',
        'description': 'Alcance 90% de progresso médio nos marcos da campanha principal.',
        'icon': 'auto_awesome',
        'category': 'campaign',
        'target_value': 90,
        'xp_reward': 25,
        'coins_reward': 0,
      },
    ];

    for (final achievement in achievements) {
      batch.insert(
        'achievements',
        {
          ...achievement,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.insert(
        'hero_achievements',
        {
          'id': 'hero_${achievement['code']}',
          'achievement_id': achievement['id'],
          'progress_value': 0,
          'is_unlocked': 0,
          'unlocked_at': null,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.insert(
      'history_events',
      {
        'id': 'history_v311_campaign',
        'title': 'Campanha principal aprimorada',
        'description': 'A Transformação dos 20 aos 25 agora possui marcos automáticos baseados nas ações reais do app.',
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'app_meta',
      {
        'key': 'seed_v311_campaign_main_done',
        'value': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await batch.commit(noResult: true);
  }


  static Future<void> _runV312Seeds(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v312_onboarding_done'],
      limit: 1,
    );

    if (seedCheck.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    final settings = {
      'onboarding_completed': [
        'false',
        'bool',
        'Indica se a configuração inicial já foi concluída.',
      ],
      'onboarding_completed_at': [
        '',
        'text',
        'Data em que o onboarding foi concluído pela última vez.',
      ],
      'onboarding_focus_areas': [
        'health,discipline',
        'text',
        'Focos iniciais escolhidos no onboarding.',
      ],
      'onboarding_use_starter_presets': [
        'true',
        'bool',
        'Controla se presets iniciais devem ser sugeridos.',
      ],
      'onboarding_water_target_ml': [
        '1000',
        'int',
        'Meta inicial de água escolhida no onboarding.',
      ],
    };

    for (final entry in settings.entries) {
      batch.insert(
        'settings',
        {
          'key': entry.key,
          'value': entry.value[0],
          'value_type': entry.value[1],
          'description': entry.value[2],
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    batch.insert(
      'history_events',
      {
        'id': 'history_v312_onboarding',
        'title': 'Configuração inicial preparada',
        'description': 'Onboarding V1 adicionado para preparar herói, dificuldade, foco, água e presets da campanha.',
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'app_meta',
      {
        'key': 'seed_v312_onboarding_done',
        'value': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await batch.commit(noResult: true);
  }


  static Future<void> _runV41Seeds(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v41_onboarding_expanded_done'],
      limit: 1,
    );

    if (seedCheck.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    final settings = {
      'onboarding_use_recommended_setup': [
        'true',
        'bool',
        'Controla se o onboarding usa a configuração recomendada.',
      ],
      'onboarding_active_area_ids': [
        'body_health,mind_knowledge,spirit_purpose,projects_career,finance_responsibility,routine_order',
        'text',
        'Áreas de vida ativas escolhidas no onboarding expandido.',
      ],
      'onboarding_area_attributes_body_health': [
        'vigor,strength,discipline',
        'text',
        'Atributos sugeridos para Corpo e Saúde.',
      ],
      'onboarding_area_attributes_mind_knowledge': [
        'clarity,focus,discipline',
        'text',
        'Atributos sugeridos para Mente e Conhecimento.',
      ],
      'onboarding_area_attributes_spirit_purpose': [
        'faith,clarity,discipline',
        'text',
        'Atributos sugeridos para Fé e Propósito.',
      ],
      'onboarding_area_attributes_projects_career': [
        'focus,responsibility,clarity',
        'text',
        'Atributos sugeridos para Carreira e Projetos.',
      ],
      'onboarding_area_attributes_creation_expression': [
        'creativity,focus,clarity',
        'text',
        'Atributos sugeridos para Criação e Expressão.',
      ],
      'onboarding_area_attributes_finance_responsibility': [
        'responsibility,discipline,clarity',
        'text',
        'Atributos sugeridos para Finanças e Reino.',
      ],
      'onboarding_area_attributes_routine_order': [
        'discipline,responsibility,clarity',
        'text',
        'Atributos sugeridos para Rotina e Ordem.',
      ],
      'economy_coins_auto_half_xp': [
        'true',
        'bool',
        'Preferência para futuras telas calcularem coins como metade do XP.',
      ],
    };

    for (final entry in settings.entries) {
      batch.insert(
        'settings',
        {
          'key': entry.key,
          'value': entry.value[0],
          'value_type': entry.value[1],
          'description': entry.value[2],
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final links = {
      'body_health': ['vigor', 'strength', 'discipline'],
      'mind_knowledge': ['clarity', 'focus', 'discipline'],
      'spirit_purpose': ['faith', 'clarity', 'discipline'],
      'projects_career': ['focus', 'responsibility', 'clarity'],
      'creation_expression': ['creativity', 'focus', 'clarity'],
      'finance_responsibility': ['responsibility', 'discipline', 'clarity'],
      'routine_order': ['discipline', 'responsibility', 'clarity'],
    };

    for (final entry in links.entries) {
      final weights = [50, 30, 20];
      for (var index = 0; index < entry.value.length; index++) {
        batch.insert(
          'area_attribute_links',
          {
            'area_id': entry.key,
            'attribute_id': entry.value[index],
            'weight': weights[index],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    batch.insert(
      'history_events',
      {
        'id': 'history_v41_onboarding_expanded',
        'title': 'Onboarding expandido preparado',
        'description': 'Configuração inicial agora inclui campanha, áreas de vida, atributos sugeridos e Hardcore bloqueado até 7 check-ins.',
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'app_meta',
      {
        'key': 'seed_v41_onboarding_expanded_done',
        'value': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await batch.commit(noResult: true);
  }


  static Future<void> _runV43Seeds(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v43_area_evolution_done'],
      limit: 1,
    );

    if (seedCheck.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();

    await db.execute("""
      CREATE TABLE IF NOT EXISTS hero_areas (
        id TEXT PRIMARY KEY,
        area_id TEXT NOT NULL UNIQUE,
        points INTEGER NOT NULL DEFAULT 0,
        xp INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE CASCADE
      );
    """);

    await db.execute("""
      INSERT OR IGNORE INTO hero_areas (id, area_id, points, xp, created_at, updated_at)
      SELECT 'hero_area_' || areas.id, areas.id, 0, 0, ?, ?
      FROM areas;
    """, [now, now]);

    await db.insert(
      'history_events',
      {
        'id': 'history_v43_area_evolution',
        'title': 'Evolução de áreas ativada',
        'description': 'As áreas da vida agora acumulam XP próprio conforme missões, hábitos, objetivos, sessões e projetos são concluídos.',
        'type': 'system',
        'xp_delta': 0,
        'coins_delta': 0,
        'occurred_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await db.insert(
      'app_meta',
      {
        'key': 'seed_v43_area_evolution_done',
        'value': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }


  static Future<void> _runV44Seeds(Database db) async {
    final seedCheck = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v44_campaign_chapters_done'],
      limit: 1,
    );

    if (seedCheck.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    final chapters = [
      {
        'id': 'milestone_reset_foundation',
        'title': 'Prólogo — Fundação inicial',
        'description': 'Criar presença diária, configurar a campanha e manter os primeiros hábitos sem radicalismo.',
        'lore': 'Antes da grande jornada, o herói monta acampamento, afia as ferramentas e escolhe o caminho.',
        'start_date': '2026-07-13',
        'end_date': '2026-08-13',
        'target_date': '2026-08-13',
        'primary_area_id': 'routine_order',
        'secondary_area_ids': 'body_health,mind_knowledge',
        'automation_key': 'foundation',
        'sort_order': 1,
      },
      {
        'id': 'milestone_body_mind',
        'title': 'Capítulo 1 — Corpo em movimento',
        'description': 'Sair do sedentarismo, beber mais água, mover o corpo e reduzir excessos aos poucos.',
        'lore': 'A armadura começa a pesar menos quando o corpo volta a acordar.',
        'start_date': '2026-07-13',
        'end_date': '2027-01-13',
        'target_date': '2027-01-13',
        'primary_area_id': 'body_health',
        'secondary_area_ids': 'spirit_purpose,routine_order',
        'automation_key': 'body_health',
        'sort_order': 2,
      },
      {
        'id': 'milestone_mind_programming',
        'title': 'Capítulo 2 — Mente e programação',
        'description': 'Transformar foco, estudo, leitura e prática de código em avanço real de carreira.',
        'lore': 'O grimório abre: foco, clareza e prática viram poder acumulado.',
        'start_date': '2027-01-13',
        'end_date': '2027-07-13',
        'target_date': '2027-07-13',
        'primary_area_id': 'projects_career',
        'secondary_area_ids': 'mind_knowledge,routine_order',
        'automation_key': 'mind_programming',
        'sort_order': 3,
      },
      {
        'id': 'milestone_faith_purpose',
        'title': 'Capítulo 3 — Fé e propósito',
        'description': 'Fortalecer constância espiritual, clareza de direção e responsabilidade interna.',
        'lore': 'Sem direção, força vira barulho. Com propósito, até passo pequeno vira marcha.',
        'start_date': '2027-07-13',
        'end_date': '2028-01-13',
        'target_date': '2028-01-13',
        'primary_area_id': 'spirit_purpose',
        'secondary_area_ids': 'routine_order,mind_knowledge',
        'automation_key': 'faith_purpose',
        'sort_order': 4,
      },
      {
        'id': 'milestone_projects_finance',
        'title': 'Capítulo 4 — Projetos e responsabilidade',
        'description': 'Unir projetos, entregas, cofre, compras planejadas e decisões financeiras mais maduras.',
        'lore': 'O reino começa a ter obra, cofre e decisões menos impulsivas.',
        'start_date': '2028-01-13',
        'end_date': '2029-07-13',
        'target_date': '2029-07-13',
        'primary_area_id': 'projects_career',
        'secondary_area_ids': 'finance_responsibility,creation_expression',
        'automation_key': 'projects_finance',
        'sort_order': 5,
      },
      {
        'id': 'milestone_campaign_consolidation',
        'title': 'Capítulo 5 — Consolidação da campanha',
        'description': 'Amarrar conquistas, áreas, atributos, foco, finanças e hábitos em uma identidade mais sólida.',
        'lore': 'A jornada deixa de ser empolgação inicial e vira identidade praticada.',
        'start_date': '2029-07-13',
        'end_date': '2031-07-13',
        'target_date': '2031-07-13',
        'primary_area_id': 'routine_order',
        'secondary_area_ids': 'body_health,mind_knowledge,finance_responsibility',
        'automation_key': 'campaign_consolidation',
        'sort_order': 6,
      },
    ];

    for (final chapter in chapters) {
      batch.update(
        'campaign_milestones',
        {
          'title': chapter['title'],
          'description': chapter['description'],
          'lore': chapter['lore'],
          'target_date': chapter['target_date'],
          'start_date': chapter['start_date'],
          'end_date': chapter['end_date'],
          'primary_area_id': chapter['primary_area_id'],
          'secondary_area_ids': chapter['secondary_area_ids'],
          'chapter_kind': 'chapter',
          'automation_key': chapter['automation_key'],
          'auto_progress_enabled': 1,
          'sort_order': chapter['sort_order'],
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [chapter['id']],
      );
    }

    batch.insert(
      'settings',
      {
        'key': 'campaign_visual_unit',
        'value': 'chapters',
        'value_type': 'text',
        'description': 'Define que a campanha usa linguagem narrativa de capítulos em vez de marcos.',
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    batch.insert(
      'history_events',
      {
        'id': 'history_v44_campaign_chapters',
        'event_type': 'system',
        'title': 'Campanha organizada em capítulos',
        'description': 'Os marcos da campanha passaram a ser tratados como capítulos com período, área principal e áreas secundárias.',
        'xp_delta': 0,
        'coins_delta': 0,
        'ref_table': 'campaign_milestones',
        'ref_id': 'transformation_20_25',
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'app_meta',
      {'key': 'seed_v44_campaign_chapters_done', 'value': 'true', 'updated_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await batch.commit(noResult: true);
  }

}
