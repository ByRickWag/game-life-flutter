import 'package:sqflite/sqflite.dart';

class DbSchema {
  static Future<void> create(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE app_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE areas (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE attributes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE area_attribute_links (
        area_id TEXT NOT NULL,
        attribute_id TEXT NOT NULL,
        weight INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (area_id, attribute_id),
        FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE CASCADE,
        FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE hero_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        xp INTEGER NOT NULL DEFAULT 0,
        coins INTEGER NOT NULL DEFAULT 0,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE hero_attributes (
        id TEXT PRIMARY KEY,
        attribute_id TEXT NOT NULL UNIQUE,
        points INTEGER NOT NULL DEFAULT 0,
        xp INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE campaigns (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE missions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        area_id TEXT,
        attribute_id TEXT,
        xp_reward INTEGER NOT NULL DEFAULT 0,
        coins_reward INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE SET NULL,
        FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE SET NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE mission_completions (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        completed_on TEXT NOT NULL,
        xp_gained INTEGER NOT NULL DEFAULT 0,
        coins_gained INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE objectives (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        area_id TEXT,
        attribute_id TEXT,
        target_value REAL NOT NULL,
        current_value REAL NOT NULL DEFAULT 0,
        unit TEXT NOT NULL,
        xp_reward INTEGER NOT NULL DEFAULT 0,
        coins_reward INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE SET NULL,
        FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE SET NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE objective_progress_entries (
        id TEXT PRIMARY KEY,
        objective_id TEXT NOT NULL,
        value_delta REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (objective_id) REFERENCES objectives(id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        session_type TEXT NOT NULL DEFAULT 'general',
        area_id TEXT,
        attribute_id TEXT,
        duration_minutes INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        xp_gained INTEGER NOT NULL DEFAULT 0,
        coins_gained INTEGER NOT NULL DEFAULT 0,
        started_at TEXT,
        ended_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE SET NULL,
        FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE SET NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        area_id TEXT,
        attribute_id TEXT,
        difficulty TEXT NOT NULL DEFAULT 'normal',
        status TEXT NOT NULL DEFAULT 'active',
        progress REAL NOT NULL DEFAULT 0,
        xp_reward INTEGER NOT NULL DEFAULT 0,
        coins_reward INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE SET NULL,
        FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE SET NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE project_tasks (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      );
    ''');

    batch.execute('''
      CREATE TABLE history_events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        xp_delta INTEGER NOT NULL DEFAULT 0,
        coins_delta INTEGER NOT NULL DEFAULT 0,
        occurred_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        value_type TEXT NOT NULL,
        description TEXT,
        updated_at TEXT NOT NULL
      );
    ''');

    await batch.commit(noResult: true);
    await _upgradeToV4(db);
    await _upgradeToV5(db);
    await _upgradeToV6(db);
    await _upgradeToV7(db);
    await _upgradeToV8(db);
    await _upgradeToV9(db);
    await _upgradeToV10(db);
    await _upgradeToV11(db);
    await _upgradeToV12(db);
    await _upgradeToV13(db);
    await _upgradeToV14(db);
    await _upgradeToV15(db);
    await _upgradeToV16(db);
  }

  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(
        db: db,
        tableName: 'sessions',
        columnName: 'session_type',
        sql:
            "ALTER TABLE sessions ADD COLUMN session_type TEXT NOT NULL DEFAULT 'general';",
      );
    }

    if (oldVersion < 3) {
      await _addColumnIfMissing(
        db: db,
        tableName: 'projects',
        columnName: 'attribute_id',
        sql: 'ALTER TABLE projects ADD COLUMN attribute_id TEXT;',
      );
      await _addColumnIfMissing(
        db: db,
        tableName: 'projects',
        columnName: 'difficulty',
        sql:
            "ALTER TABLE projects ADD COLUMN difficulty TEXT NOT NULL DEFAULT 'normal';",
      );
      await _addColumnIfMissing(
        db: db,
        tableName: 'projects',
        columnName: 'completed_at',
        sql: 'ALTER TABLE projects ADD COLUMN completed_at TEXT;',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS project_tasks (
          id TEXT PRIMARY KEY,
          project_id TEXT NOT NULL,
          title TEXT NOT NULL,
          is_done INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
        );
      ''');
    }

    if (oldVersion < 4) {
      await _upgradeToV4(db);
    }

    if (oldVersion < 5) {
      await _upgradeToV5(db);
    }

    if (oldVersion < 6) {
      await _upgradeToV6(db);
    }

    if (oldVersion < 7) {
      await _upgradeToV7(db);
    }

    if (oldVersion < 8) {
      await _upgradeToV8(db);
    }

    if (oldVersion < 9) {
      await _upgradeToV9(db);
    }

    if (oldVersion < 10) {
      await _upgradeToV10(db);
    }

    if (oldVersion < 11) {
      await _upgradeToV11(db);
    }

    if (oldVersion < 12) {
      await _upgradeToV12(db);
    }

    if (oldVersion < 13) {
      await _upgradeToV13(db);
    }

    if (oldVersion < 14) {
      await _upgradeToV14(db);
    }

    if (oldVersion < 15) {
      await _upgradeToV15(db);
    }

    if (oldVersion < 16) {
      await _upgradeToV16(db);
    }
  }

  static Future<void> _upgradeToV4(Database db) async {
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaigns',
      columnName: 'lore',
      sql: 'ALTER TABLE campaigns ADD COLUMN lore TEXT;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaigns',
      columnName: 'main_goal',
      sql: 'ALTER TABLE campaigns ADD COLUMN main_goal TEXT;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaigns',
      columnName: 'victory_minimum_percent',
      sql:
          'ALTER TABLE campaigns ADD COLUMN victory_minimum_percent INTEGER NOT NULL DEFAULT 60;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaigns',
      columnName: 'victory_good_percent',
      sql:
          'ALTER TABLE campaigns ADD COLUMN victory_good_percent INTEGER NOT NULL DEFAULT 75;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaigns',
      columnName: 'victory_excellent_percent',
      sql:
          'ALTER TABLE campaigns ADD COLUMN victory_excellent_percent INTEGER NOT NULL DEFAULT 90;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaigns',
      columnName: 'difficulty_mode',
      sql:
          "ALTER TABLE campaigns ADD COLUMN difficulty_mode TEXT NOT NULL DEFAULT 'normal';",
    );

    await _addColumnIfMissing(
      db: db,
      tableName: 'missions',
      columnName: 'status',
      sql:
          "ALTER TABLE missions ADD COLUMN status TEXT NOT NULL DEFAULT 'active';",
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'missions',
      columnName: 'is_compound',
      sql:
          'ALTER TABLE missions ADD COLUMN is_compound INTEGER NOT NULL DEFAULT 0;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'missions',
      columnName: 'planned_for',
      sql: 'ALTER TABLE missions ADD COLUMN planned_for TEXT;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'missions',
      columnName: 'due_at',
      sql: 'ALTER TABLE missions ADD COLUMN due_at TEXT;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'missions',
      columnName: 'failure_penalty_applied',
      sql:
          'ALTER TABLE missions ADD COLUMN failure_penalty_applied INTEGER NOT NULL DEFAULT 0;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'missions',
      columnName: 'notes',
      sql: 'ALTER TABLE missions ADD COLUMN notes TEXT;',
    );

    await _addColumnIfMissing(
      db: db,
      tableName: 'objectives',
      columnName: 'planned_for',
      sql: 'ALTER TABLE objectives ADD COLUMN planned_for TEXT;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'objectives',
      columnName: 'due_at',
      sql: 'ALTER TABLE objectives ADD COLUMN due_at TEXT;',
    );

    await _addColumnIfMissing(
      db: db,
      tableName: 'sessions',
      columnName: 'timer_status',
      sql:
          "ALTER TABLE sessions ADD COLUMN timer_status TEXT NOT NULL DEFAULT 'manual';",
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'sessions',
      columnName: 'elapsed_seconds',
      sql:
          'ALTER TABLE sessions ADD COLUMN elapsed_seconds INTEGER NOT NULL DEFAULT 0;',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS difficulty_profiles (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        penalty_percent INTEGER NOT NULL DEFAULT 0,
        allow_custom_rewards INTEGER NOT NULL DEFAULT 1,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS campaign_milestones (
        id TEXT PRIMARY KEY,
        campaign_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        lore TEXT,
        target_date TEXT,
        start_date TEXT DEFAULT '',
        end_date TEXT DEFAULT '',
        primary_area_id TEXT DEFAULT '',
        secondary_area_ids TEXT NOT NULL DEFAULT '',
        chapter_kind TEXT NOT NULL DEFAULT 'chapter',
        sort_order INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        progress REAL NOT NULL DEFAULT 0,
        xp_reward INTEGER NOT NULL DEFAULT 0,
        coins_reward INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_checkins (
        id TEXT PRIMARY KEY,
        checkin_date TEXT NOT NULL UNIQUE,
        streak_count INTEGER NOT NULL DEFAULT 1,
        coins_gained INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS achievements (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        description TEXT,
        icon TEXT NOT NULL DEFAULT 'emoji_events',
        category TEXT NOT NULL DEFAULT 'general',
        target_value INTEGER NOT NULL DEFAULT 1,
        xp_reward INTEGER NOT NULL DEFAULT 0,
        coins_reward INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS hero_achievements (
        id TEXT PRIMARY KEY,
        achievement_id TEXT NOT NULL UNIQUE,
        progress_value INTEGER NOT NULL DEFAULT 0,
        is_unlocked INTEGER NOT NULL DEFAULT 0,
        unlocked_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (achievement_id) REFERENCES achievements(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mission_tasks (
        id TEXT PRIMARY KEY,
        mission_id TEXT NOT NULL,
        title TEXT NOT NULL,
        notes TEXT,
        is_done INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS item_attribute_links (
        id TEXT PRIMARY KEY,
        item_type TEXT NOT NULL,
        item_id TEXT NOT NULL,
        attribute_id TEXT NOT NULL,
        weight INTEGER NOT NULL DEFAULT 100,
        is_primary INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        UNIQUE (item_type, item_id, attribute_id),
        FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminder_configs (
        id TEXT PRIMARY KEY,
        item_type TEXT NOT NULL,
        item_id TEXT,
        title TEXT NOT NULL,
        body TEXT,
        reminder_type TEXT NOT NULL DEFAULT 'general',
        time_of_day TEXT,
        scheduled_date TEXT,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS session_timers (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        session_type TEXT NOT NULL DEFAULT 'general',
        area_id TEXT,
        status TEXT NOT NULL DEFAULT 'idle',
        started_at TEXT,
        paused_at TEXT,
        finished_at TEXT,
        elapsed_seconds INTEGER NOT NULL DEFAULT 0,
        total_paused_seconds INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE SET NULL
      );
    ''');
  }

  static Future<void> _upgradeToV5(Database db) async {
    await db.execute("""
      CREATE TABLE IF NOT EXISTS project_milestones (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        sort_order INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      );
    """);

    await _addColumnIfMissing(
      db: db,
      tableName: 'project_tasks',
      columnName: 'milestone_id',
      sql: 'ALTER TABLE project_tasks ADD COLUMN milestone_id TEXT;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'project_tasks',
      columnName: 'xp_reward',
      sql:
          'ALTER TABLE project_tasks ADD COLUMN xp_reward INTEGER NOT NULL DEFAULT 5;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'project_tasks',
      columnName: 'xp_applied',
      sql:
          'ALTER TABLE project_tasks ADD COLUMN xp_applied INTEGER NOT NULL DEFAULT 0;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'project_tasks',
      columnName: 'completed_at',
      sql: 'ALTER TABLE project_tasks ADD COLUMN completed_at TEXT;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'project_tasks',
      columnName: 'notes',
      sql: 'ALTER TABLE project_tasks ADD COLUMN notes TEXT;',
    );

    await _seedProjectDefaults(db);
  }

  static Future<void> _upgradeToV6(Database db) async {
    await db.execute('''
      UPDATE missions
      SET is_compound = 1,
          updated_at = datetime('now')
      WHERE id IN (
        SELECT DISTINCT mission_id
        FROM mission_tasks
      )
      AND is_compound = 0;
    ''');
  }

  static Future<void> _upgradeToV7(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS habits (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL DEFAULT 'build',
        frequency TEXT NOT NULL DEFAULT 'daily',
        unit TEXT NOT NULL DEFAULT 'check',
        target_value REAL NOT NULL DEFAULT 1,
        limit_value REAL NOT NULL DEFAULT 0,
        area_id TEXT,
        attribute_id TEXT,
        xp_reward INTEGER NOT NULL DEFAULT 8,
        coins_reward INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE SET NULL,
        FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS habit_logs (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        value REAL NOT NULL DEFAULT 1,
        note TEXT,
        logged_for TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS habit_period_rewards (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        period_start TEXT NOT NULL,
        period_end TEXT NOT NULL,
        xp_gained INTEGER NOT NULL DEFAULT 0,
        coins_gained INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        UNIQUE (habit_id, period_start),
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_habit_logs_habit_created
      ON habit_logs(habit_id, created_at);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_habit_rewards_habit_period
      ON habit_period_rewards(habit_id, period_start);
    ''');
  }

  static Future<void> _upgradeToV8(Database db) async {
    await _addColumnIfMissing(
      db: db,
      tableName: 'habits',
      columnName: 'health_kind',
      sql:
          "ALTER TABLE habits ADD COLUMN health_kind TEXT NOT NULL DEFAULT '';",
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'habits',
      columnName: 'health_category',
      sql:
          "ALTER TABLE habits ADD COLUMN health_category TEXT NOT NULL DEFAULT '';",
    );

    await db.execute('''
      UPDATE habits
      SET health_kind = 'water',
          health_category = 'water'
      WHERE is_active = 1
        AND (
          id = 'habit_water_base'
          OR LOWER(title) LIKE '%água%'
          OR LOWER(title) LIKE '%agua%'
          OR unit = 'ml'
        );
    ''');

    await db.execute('''
      UPDATE habits
      SET health_kind = 'food_limit',
          health_category = 'soda'
      WHERE id = 'habit_soda_reduce_base'
         OR LOWER(title) LIKE '%refrigerante%';
    ''');

    await db.execute('''
      UPDATE habits
      SET health_kind = 'food_limit',
          health_category = 'ultra_processed'
      WHERE id = 'habit_ultra_processed_reduce_base'
         OR LOWER(title) LIKE '%ultraprocessado%'
         OR LOWER(title) LIKE '%doce%';
    ''');

    await db.execute('''
      UPDATE habits
      SET health_kind = 'food_limit',
          health_category = 'fast_food'
      WHERE id = 'habit_salty_fast_food_reduce_base'
         OR LOWER(title) LIKE '%fast-food%'
         OR LOWER(title) LIKE '%salgado%';
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_habits_health_kind
      ON habits(health_kind, health_category, is_active);
    ''');
  }

  static Future<void> _upgradeToV9(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.execute('''
      CREATE TABLE IF NOT EXISTS difficulty_penalties (
        id TEXT PRIMARY KEY,
        item_type TEXT NOT NULL,
        item_id TEXT NOT NULL,
        period_start TEXT NOT NULL,
        period_end TEXT NOT NULL,
        difficulty_mode TEXT NOT NULL,
        penalty_percent INTEGER NOT NULL DEFAULT 0,
        xp_penalty INTEGER NOT NULL DEFAULT 0,
        applied_at TEXT NOT NULL,
        UNIQUE (item_type, item_id, period_start)
      );
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_difficulty_penalties_item
      ON difficulty_penalties(item_type, item_id, period_start);
    ''');

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
    };

    for (final entry in settings.entries) {
      await db.insert('settings', {
        'key': entry.key,
        'value': entry.value[0],
        'value_type': entry.value[1],
        'description': entry.value[2],
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await db.update(
      'settings',
      {'value': 'true', 'updated_at': now},
      where: 'key = ?',
      whereArgs: ['mission_failure_penalty_enabled'],
    );
  }

  static Future<void> _upgradeToV10(Database db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_achievements_category_active
      ON achievements(category, is_active, target_value);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_hero_achievements_unlocked
      ON hero_achievements(is_unlocked, achievement_id);
    ''');
  }

  static Future<void> _upgradeToV11(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vaults (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        goal_amount REAL NOT NULL DEFAULT 0,
        icon TEXT NOT NULL DEFAULT 'savings',
        color TEXT NOT NULL DEFAULT 'amber',
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        archived_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vault_entries (
        id TEXT PRIMARY KEY,
        vault_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (vault_id) REFERENCES vaults(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_vaults_status
      ON vaults(status, created_at);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_vault_entries_vault_created
      ON vault_entries(vault_id, created_at);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_vault_entries_type
      ON vault_entries(type, created_at);
    ''');
  }

  static Future<void> _upgradeToV12(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shop_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL DEFAULT 'reward',
        coin_cost INTEGER NOT NULL DEFAULT 0,
        required_money_amount REAL NOT NULL DEFAULT 0,
        linked_vault_id TEXT,
        icon TEXT NOT NULL DEFAULT 'redeem',
        color TEXT NOT NULL DEFAULT 'purple',
        status TEXT NOT NULL DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        archived_at TEXT,
        FOREIGN KEY (linked_vault_id) REFERENCES vaults(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shop_purchases (
        id TEXT PRIMARY KEY,
        shop_item_id TEXT,
        title_snapshot TEXT NOT NULL,
        type_snapshot TEXT NOT NULL DEFAULT 'reward',
        coin_cost_paid INTEGER NOT NULL DEFAULT 0,
        required_money_snapshot REAL NOT NULL DEFAULT 0,
        linked_vault_id TEXT,
        note TEXT,
        purchased_at TEXT NOT NULL,
        FOREIGN KEY (shop_item_id) REFERENCES shop_items(id) ON DELETE SET NULL,
        FOREIGN KEY (linked_vault_id) REFERENCES vaults(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_shop_items_status_type
      ON shop_items(status, type, coin_cost);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_shop_purchases_type_date
      ON shop_purchases(type_snapshot, purchased_at);
    ''');
  }

  static Future<void> _upgradeToV13(Database db) async {
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaign_milestones',
      columnName: 'automation_key',
      sql: 'ALTER TABLE campaign_milestones ADD COLUMN automation_key TEXT;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaign_milestones',
      columnName: 'auto_progress_enabled',
      sql:
          'ALTER TABLE campaign_milestones ADD COLUMN auto_progress_enabled INTEGER NOT NULL DEFAULT 1;',
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaign_milestones',
      columnName: 'progress_note',
      sql: 'ALTER TABLE campaign_milestones ADD COLUMN progress_note TEXT;',
    );

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_campaign_milestones_auto
      ON campaign_milestones(campaign_id, auto_progress_enabled, automation_key);
    ''');
  }

  static Future<void> _upgradeToV14(Database db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_settings_onboarding
      ON settings(key, updated_at);
    ''');
  }

  static Future<void> _upgradeToV15(Database db) async {
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
      CREATE INDEX IF NOT EXISTS idx_hero_areas_area
      ON hero_areas(area_id, xp, points);
    """);

    await db.execute(
      """
      INSERT OR IGNORE INTO hero_areas (id, area_id, points, xp, created_at, updated_at)
      SELECT 'hero_area_' || areas.id, areas.id, 0, 0, ?, ?
      FROM areas;
    """,
      [now, now],
    );
  }

  static Future<void> _upgradeToV16(Database db) async {
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaign_milestones',
      columnName: 'start_date',
      sql:
          "ALTER TABLE campaign_milestones ADD COLUMN start_date TEXT DEFAULT '';",
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaign_milestones',
      columnName: 'end_date',
      sql:
          "ALTER TABLE campaign_milestones ADD COLUMN end_date TEXT DEFAULT '';",
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaign_milestones',
      columnName: 'primary_area_id',
      sql:
          "ALTER TABLE campaign_milestones ADD COLUMN primary_area_id TEXT DEFAULT '';",
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaign_milestones',
      columnName: 'secondary_area_ids',
      sql:
          "ALTER TABLE campaign_milestones ADD COLUMN secondary_area_ids TEXT NOT NULL DEFAULT '';",
    );
    await _addColumnIfMissing(
      db: db,
      tableName: 'campaign_milestones',
      columnName: 'chapter_kind',
      sql:
          "ALTER TABLE campaign_milestones ADD COLUMN chapter_kind TEXT NOT NULL DEFAULT 'chapter';",
    );

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_campaign_chapters_area
      ON campaign_milestones(campaign_id, primary_area_id, start_date, end_date);
    ''');
  }

  static Future<void> _seedProjectDefaults(Database db) async {
    final now = DateTime.now().toIso8601String();
    final projectRows = await db.query('projects');

    for (final project in projectRows) {
      final projectId = project['id']?.toString() ?? '';
      if (projectId.isEmpty) continue;

      final milestoneRows = await db.query(
        'project_milestones',
        where: 'project_id = ?',
        whereArgs: [projectId],
        limit: 1,
      );

      var milestoneId = '';
      if (milestoneRows.isEmpty) {
        milestoneId = 'milestone_${projectId}_base';
        await db.insert('project_milestones', {
          'id': milestoneId,
          'project_id': projectId,
          'title': 'Marco inicial',
          'description':
              'Marco criado automaticamente para tarefas antigas do projeto.',
          'status': 'active',
          'sort_order': 0,
          'completed_at': null,
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } else {
        milestoneId = milestoneRows.first['id']?.toString() ?? '';
      }

      if (milestoneId.isEmpty) continue;

      await db.update(
        'project_tasks',
        {'milestone_id': milestoneId, 'updated_at': now},
        where: 'project_id = ? AND (milestone_id IS NULL OR milestone_id = ?)',
        whereArgs: [projectId, ''],
      );
    }
  }

  static Future<void> _addColumnIfMissing({
    required Database db,
    required String tableName,
    required String columnName,
    required String sql,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName);');
    final exists = columns.any((column) => column['name'] == columnName);
    if (!exists) {
      await db.execute(sql);
    }
  }
}
