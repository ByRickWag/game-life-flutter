@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:game_life_flutter_release/src/core/database/db_schema.dart';
import 'package:game_life_flutter_release/src/core/database/db_seeds.dart';
import 'package:game_life_flutter_release/src/core/models/v3_commitment_models.dart';
import 'package:game_life_flutter_release/src/core/repositories/campaign_commitment_repository.dart';

const _chapterIds = [
  'milestone_reset_foundation',
  'milestone_body_mind',
  'milestone_mind_programming',
  'milestone_faith_purpose',
  'milestone_projects_finance',
  'milestone_campaign_consolidation',
];

const _expectedChapterMetadata = [
  {
    'id': 'milestone_reset_foundation',
    'title': 'Prólogo — Fundação inicial',
    'start_date': '2026-07-13',
    'end_date': '2026-08-13',
    'target_date': '2026-08-13',
    'primary_area_id': 'routine_order',
    'secondary_area_ids': 'body_health,mind_knowledge',
    'chapter_kind': 'chapter',
    'automation_key': 'foundation',
    'auto_progress_enabled': 1,
    'sort_order': 1,
  },
  {
    'id': 'milestone_body_mind',
    'title': 'Capítulo 1 — Corpo em movimento',
    'start_date': '2026-07-13',
    'end_date': '2027-01-13',
    'target_date': '2027-01-13',
    'primary_area_id': 'body_health',
    'secondary_area_ids': 'spirit_purpose,routine_order',
    'chapter_kind': 'chapter',
    'automation_key': 'body_health',
    'auto_progress_enabled': 1,
    'sort_order': 2,
  },
  {
    'id': 'milestone_mind_programming',
    'title': 'Capítulo 2 — Mente e programação',
    'start_date': '2027-01-13',
    'end_date': '2027-07-13',
    'target_date': '2027-07-13',
    'primary_area_id': 'projects_career',
    'secondary_area_ids': 'mind_knowledge,routine_order',
    'chapter_kind': 'chapter',
    'automation_key': 'mind_programming',
    'auto_progress_enabled': 1,
    'sort_order': 3,
  },
  {
    'id': 'milestone_faith_purpose',
    'title': 'Capítulo 3 — Fé e propósito',
    'start_date': '2027-07-13',
    'end_date': '2028-01-13',
    'target_date': '2028-01-13',
    'primary_area_id': 'spirit_purpose',
    'secondary_area_ids': 'routine_order,mind_knowledge',
    'chapter_kind': 'chapter',
    'automation_key': 'faith_purpose',
    'auto_progress_enabled': 1,
    'sort_order': 4,
  },
  {
    'id': 'milestone_projects_finance',
    'title': 'Capítulo 4 — Projetos e responsabilidade',
    'start_date': '2028-01-13',
    'end_date': '2029-07-13',
    'target_date': '2029-07-13',
    'primary_area_id': 'projects_career',
    'secondary_area_ids': 'finance_responsibility,creation_expression',
    'chapter_kind': 'chapter',
    'automation_key': 'projects_finance',
    'auto_progress_enabled': 1,
    'sort_order': 5,
  },
  {
    'id': 'milestone_campaign_consolidation',
    'title': 'Capítulo 5 — Consolidação da campanha',
    'start_date': '2029-07-13',
    'end_date': '2031-07-13',
    'target_date': '2031-07-13',
    'primary_area_id': 'routine_order',
    'secondary_area_ids': 'body_health,mind_knowledge,finance_responsibility',
    'chapter_kind': 'chapter',
    'automation_key': 'campaign_consolidation',
    'auto_progress_enabled': 1,
    'sort_order': 6,
  },
];

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'fresh install creates schema v16 and the six canonical chapters',
    () async {
      final db = await _openFreshDatabase();
      addTearDown(db.close);

      expect(await db.getVersion(), 16);

      final columns = await db.rawQuery(
        'PRAGMA table_info(campaign_milestones)',
      );
      final columnNames = columns.map((row) => row['name']).toSet();
      expect(
        columnNames,
        containsAll([
          'start_date',
          'end_date',
          'primary_area_id',
          'secondary_area_ids',
          'chapter_kind',
        ]),
      );

      final indexes = await db.rawQuery(
        'PRAGMA index_list(campaign_milestones)',
      );
      expect(
        indexes.map((row) => row['name']),
        contains('idx_campaign_chapters_area'),
      );

      final chapters = await _loadChapterMetadata(db);
      expect(chapters, _expectedChapterMetadata);

      final firstChapter = CampaignMilestone.fromMap(chapters.first);
      expect(firstChapter.startDate, '2026-07-13');
      expect(firstChapter.endDate, '2026-08-13');
      expect(firstChapter.primaryAreaId, 'routine_order');
      expect(firstChapter.secondaryAreaIdList, [
        'body_health',
        'mind_knowledge',
      ]);
      expect(firstChapter.chapterKind, 'chapter');

      final setting = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['campaign_visual_unit'],
        limit: 1,
      );
      expect(setting.single['value'], 'chapters');

      final marker = await db.query(
        'app_meta',
        where: 'key = ?',
        whereArgs: ['seed_v451_campaign_chapters_done'],
        limit: 1,
      );
      expect(marker, hasLength(1));
    },
  );

  test(
    'upgrade partial v15 to v16 preserves progress, completion and custom rows',
    () async {
      final fixture = await _openUpgradedV15Fixture();
      final db = fixture.db;
      addTearDown(() async {
        await db.close();
        await fixture.directory.delete(recursive: true);
      });

      expect(await db.getVersion(), 16);

      final defaultRow = (await db.query(
        'campaign_milestones',
        where: 'id = ?',
        whereArgs: ['milestone_reset_foundation'],
        limit: 1,
      )).single;
      expect(defaultRow['title'], 'Minha fundação personalizada');
      expect(defaultRow['description'], 'Descrição que pertence ao usuário');
      expect(defaultRow['lore'], 'Lore que pertence ao usuário');
      expect(defaultRow['progress'], 1.0);
      expect(defaultRow['status'], 'completed');
      expect(defaultRow['completed_at'], '2026-07-20T10:00:00.000');
      expect(defaultRow['target_date'], '2030-12-31');
      expect(defaultRow['end_date'], '2030-12-31');
      expect(defaultRow['start_date'], '2026-07-13');
      expect(defaultRow['primary_area_id'], 'routine_order');
      expect(defaultRow['sort_order'], 1);
      expect(defaultRow['automation_key'], 'foundation');
      expect(defaultRow['auto_progress_enabled'], 1);
      expect(defaultRow['chapter_kind'], 'chapter');

      final customRow = (await db.query(
        'campaign_milestones',
        where: 'id = ?',
        whereArgs: ['custom_legacy_chapter'],
        limit: 1,
      )).single;
      expect(customRow['title'], 'Capítulo legado do usuário');
      expect(customRow['progress'], 0.42);
      expect(customRow['status'], 'active');
      expect(customRow['auto_progress_enabled'], 0);
      expect(customRow['start_date'], '');
      expect(customRow['primary_area_id'], '');

      final allRows = await db.query('campaign_milestones');
      expect(allRows, hasLength(7));
      expect(
        allRows.map((row) => row['id']),
        containsAll([..._chapterIds, 'custom_legacy_chapter']),
      );

      final setting = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['campaign_visual_unit'],
        limit: 1,
      );
      expect(setting.single['value'], 'custom-unit');
    },
  );

  test(
    'chapter seed is idempotent and only backfills missing metadata',
    () async {
      final db = await _openFreshDatabase();
      addTearDown(db.close);

      await db.update(
        'campaign_milestones',
        {
          'title': 'Prólogo personalizado',
          'description': 'Descrição personalizada',
          'lore': 'Lore personalizada',
          'start_date': '2030-01-01',
          'end_date': '',
          'target_date': null,
          'primary_area_id': 'creation_expression',
          'secondary_area_ids': '',
          'chapter_kind': 'legacy',
          'sort_order': 99,
          'automation_key': 'custom',
          'auto_progress_enabled': 0,
          'progress': 1.0,
          'status': 'completed',
          'progress_note': 'Nota preservada',
          'completed_at': '2026-07-21T08:00:00.000',
          'xp_reward': 777,
          'coins_reward': 333,
        },
        where: 'id = ?',
        whereArgs: ['milestone_reset_foundation'],
      );
      await db.update(
        'settings',
        {'value': 'custom-unit'},
        where: 'key = ?',
        whereArgs: ['campaign_visual_unit'],
      );
      await db.delete(
        'app_meta',
        where: 'key = ?',
        whereArgs: ['seed_v451_campaign_chapters_done'],
      );

      await DbSeeds.run(db);
      await DbSeeds.run(db);

      final row = (await db.query(
        'campaign_milestones',
        where: 'id = ?',
        whereArgs: ['milestone_reset_foundation'],
        limit: 1,
      )).single;
      expect(row['title'], 'Prólogo personalizado');
      expect(row['description'], 'Descrição personalizada');
      expect(row['lore'], 'Lore personalizada');
      expect(row['start_date'], '2030-01-01');
      expect(row['primary_area_id'], 'creation_expression');
      expect(row['end_date'], '2026-08-13');
      expect(row['target_date'], '2026-08-13');
      expect(row['secondary_area_ids'], 'body_health,mind_knowledge');
      expect(row['chapter_kind'], 'chapter');
      expect(row['sort_order'], 1);
      expect(row['automation_key'], 'foundation');
      expect(row['auto_progress_enabled'], 1);
      expect(row['progress'], 1.0);
      expect(row['status'], 'completed');
      expect(row['progress_note'], 'Nota preservada');
      expect(row['completed_at'], '2026-07-21T08:00:00.000');
      expect(row['xp_reward'], 777);
      expect(row['coins_reward'], 333);

      final setting = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['campaign_visual_unit'],
        limit: 1,
      );
      expect(setting.single['value'], 'custom-unit');

      final history = await db.query(
        'history_events',
        where: 'id = ?',
        whereArgs: ['history_v451_campaign_chapters'],
      );
      expect(history, hasLength(1));

      final markers = await db.query(
        'app_meta',
        where: 'key = ?',
        whereArgs: ['seed_v451_campaign_chapters_done'],
      );
      expect(markers, hasLength(1));
    },
  );

  test('same-version v16 reopen repairs chapters through onOpen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'game_life_campaign_v16_reopen_test_',
    );
    final path = p.join(directory.path, 'campaign_v16.db');
    addTearDown(() async {
      await databaseFactoryFfi.deleteDatabase(path);
      await directory.delete(recursive: true);
    });

    final initialDb = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 16,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await DbSchema.create(db);
          await DbSeeds.run(db);
        },
      ),
    );
    await initialDb.update(
      'campaign_milestones',
      {'end_date': '', 'progress': 0.66},
      where: 'id = ?',
      whereArgs: ['milestone_reset_foundation'],
    );
    await initialDb.delete(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v451_campaign_chapters_done'],
    );
    await initialDb.close();

    final reopenedDb = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 16,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onOpen: DbSeeds.run,
      ),
    );
    await reopenedDb.close();

    final verifiedDb = await databaseFactoryFfi.openDatabase(path);
    final repaired = (await verifiedDb.query(
      'campaign_milestones',
      where: 'id = ?',
      whereArgs: ['milestone_reset_foundation'],
      limit: 1,
    )).single;
    expect(repaired['end_date'], '2026-08-13');
    expect(repaired['progress'], 0.66);
    expect(
      await verifiedDb.query(
        'app_meta',
        where: 'key = ?',
        whereArgs: ['seed_v451_campaign_chapters_done'],
      ),
      hasLength(1),
    );
    await verifiedDb.close();
  });

  test('chapter seed recovers a missing default campaign safely', () async {
    final db = await _openFreshDatabase();
    addTearDown(db.close);
    final now = DateTime.now().toIso8601String();

    await db.update(
      'campaigns',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: ['transformation_20_25'],
    );
    await db.insert('campaigns', {
      'id': 'custom_active_campaign',
      'title': 'Campanha personalizada',
      'description': 'Mantida durante a recuperação',
      'start_date': '2026-01-01',
      'end_date': null,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
    await db.delete(
      'campaigns',
      where: 'id = ?',
      whereArgs: ['transformation_20_25'],
    );
    await db.delete(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['seed_v451_campaign_chapters_done'],
    );

    await DbSeeds.run(db);

    final defaultCampaign = (await db.query(
      'campaigns',
      where: 'id = ?',
      whereArgs: ['transformation_20_25'],
      limit: 1,
    )).single;
    expect(defaultCampaign['is_active'], 0);
    expect(
      (await db.query(
        'campaigns',
        columns: ['is_active'],
        where: 'id = ?',
        whereArgs: ['custom_active_campaign'],
        limit: 1,
      )).single['is_active'],
      1,
    );
    expect(await _loadChapterMetadata(db), _expectedChapterMetadata);
  });

  test('automatic campaign progress never regresses', () {
    expect(
      CampaignCommitmentRepository.preserveAutomaticProgress(
        current: 0.8,
        computed: 0.3,
      ),
      0.8,
    );
    expect(
      CampaignCommitmentRepository.preserveAutomaticProgress(
        current: 0.3,
        computed: 0.8,
      ),
      0.8,
    );
    expect(
      CampaignCommitmentRepository.preserveAutomaticProgress(
        current: 1.4,
        computed: -0.2,
      ),
      1.0,
    );
  });
}

Future<Database> _openFreshDatabase() {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 16,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await DbSchema.create(db);
        await DbSeeds.run(db);
      },
    ),
  );
}

Future<List<Map<String, Object?>>> _loadChapterMetadata(Database db) {
  return db.query(
    'campaign_milestones',
    columns: const [
      'id',
      'title',
      'start_date',
      'end_date',
      'target_date',
      'primary_area_id',
      'secondary_area_ids',
      'chapter_kind',
      'automation_key',
      'auto_progress_enabled',
      'sort_order',
    ],
    where: 'id IN (?, ?, ?, ?, ?, ?)',
    whereArgs: _chapterIds,
    orderBy: 'sort_order ASC',
  );
}

Future<({Database db, Directory directory})> _openUpgradedV15Fixture() async {
  final directory = await Directory.systemTemp.createTemp(
    'game_life_campaign_test_',
  );
  final path = p.join(directory.path, 'campaign_v15.db');

  final oldDb = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 15,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => _createV15Fixture(db),
    ),
  );
  await oldDb.close();

  final upgradedDb = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 16,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: (db, oldVersion, newVersion) async {
        await DbSchema.upgrade(db, oldVersion, newVersion);
        await DbSeeds.run(db);
      },
    ),
  );

  return (db: upgradedDb, directory: directory);
}

Future<void> _createV15Fixture(Database db) async {
  await db.execute('''
    CREATE TABLE app_meta (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  ''');
  await db.execute('''
    CREATE TABLE campaigns (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      start_date TEXT NOT NULL,
      end_date TEXT,
      is_active INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      lore TEXT,
      main_goal TEXT,
      victory_minimum_percent INTEGER NOT NULL DEFAULT 60,
      victory_good_percent INTEGER NOT NULL DEFAULT 75,
      victory_excellent_percent INTEGER NOT NULL DEFAULT 90,
      difficulty_mode TEXT NOT NULL DEFAULT 'normal'
    );
  ''');
  await db.execute('''
    CREATE TABLE campaign_milestones (
      id TEXT PRIMARY KEY,
      campaign_id TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      lore TEXT,
      target_date TEXT,
      start_date TEXT DEFAULT '',
      sort_order INTEGER NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'active',
      progress REAL NOT NULL DEFAULT 0,
      xp_reward INTEGER NOT NULL DEFAULT 0,
      coins_reward INTEGER NOT NULL DEFAULT 0,
      completed_at TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      automation_key TEXT,
      auto_progress_enabled INTEGER NOT NULL DEFAULT 1,
      progress_note TEXT,
      FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE
    );
  ''');
  await db.execute('''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      value_type TEXT NOT NULL,
      description TEXT,
      updated_at TEXT NOT NULL
    );
  ''');
  await db.execute('''
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

  await db.insert('campaigns', {
    'id': 'transformation_20_25',
    'title': 'Transformação dos 20 aos 25',
    'description': 'Campanha existente',
    'start_date': '2026-07-13',
    'end_date': '2031-07-13',
    'is_active': 1,
    'created_at': '2026-07-13T00:00:00.000',
    'updated_at': '2026-07-13T00:00:00.000',
  });
  const completedAt = '2026-07-20T10:00:00.000';
  await db.insert('campaign_milestones', {
    'id': 'milestone_reset_foundation',
    'campaign_id': 'transformation_20_25',
    'title': 'Minha fundação personalizada',
    'description': 'Descrição que pertence ao usuário',
    'lore': 'Lore que pertence ao usuário',
    'target_date': '2030-12-31',
    'sort_order': 88,
    'status': 'completed',
    'progress': 1.0,
    'xp_reward': 444,
    'coins_reward': 222,
    'completed_at': completedAt,
    'created_at': '2026-07-13T00:00:00.000',
    'updated_at': completedAt,
    'automation_key': 'custom',
    'auto_progress_enabled': 0,
    'progress_note': 'Conclusão preservada',
  });
  await db.insert('campaign_milestones', {
    'id': 'custom_legacy_chapter',
    'campaign_id': 'transformation_20_25',
    'title': 'Capítulo legado do usuário',
    'description': 'Não pertence aos seis padrões',
    'sort_order': 77,
    'status': 'active',
    'progress': 0.42,
    'xp_reward': 55,
    'coins_reward': 11,
    'created_at': '2026-07-14T00:00:00.000',
    'updated_at': '2026-07-14T00:00:00.000',
    'auto_progress_enabled': 0,
  });

  await db.insert('settings', {
    'key': 'campaign_visual_unit',
    'value': 'custom-unit',
    'value_type': 'text',
    'description': 'Preferência existente',
    'updated_at': '2026-07-13T00:00:00.000',
  });

  const completedSeedKeys = [
    'seed_v1_done',
    'seed_v3_commitment_done',
    'seed_v35_habits_done',
    'seed_v36_health_done',
    'seed_v37_difficulty_progression_done',
    'seed_v38_achievements_done',
    'seed_v39_vaults_done',
    'seed_v310_shop_done',
    'seed_v311_campaign_main_done',
    'seed_v312_onboarding_done',
    'seed_v41_onboarding_expanded_done',
    'seed_v43_area_evolution_done',
  ];
  final batch = db.batch();
  for (final key in completedSeedKeys) {
    batch.insert('app_meta', {'key': key, 'value': 'done'});
  }
  await batch.commit(noResult: true);
}
