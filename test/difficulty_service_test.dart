import 'package:flutter_test/flutter_test.dart';
import 'package:game_life_flutter_release/src/core/services/difficulty_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late DifficultyService service;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await _createSchema(database);
    service = DifficultyService(databaseProvider: () async => database);
  });

  tearDown(() async {
    await database.close();
  });

  test('six valid check-ins block Hardcore without side effects', () async {
    await _insertCheckIns(database, const [
      '2026-01-01',
      '2026-01-02',
      '2026-01-03',
      '2026-01-04',
      '2026-01-05',
      '2026-01-06',
    ]);

    await expectLater(
      service.setActiveMode('hardcore'),
      throwsA(
        isA<HardcoreLockedException>()
            .having(
              (error) => error.eligibility.validCheckIns,
              'validCheckIns',
              6,
            )
            .having(
              (error) => error.eligibility.requiredCheckIns,
              'requiredCheckIns',
              7,
            ),
      ),
    );

    expect(await _settingValue(database), 'normal');
    expect(await _campaignMode(database), 'normal');
    expect(await _historyCount(database), 0);

    final hero = (await database.query('hero_profiles')).single;
    expect(hero['level'], 99);
    expect(hero['updated_at'], 'original');
  });

  test(
    'seven distinct nonconsecutive valid dates unlock and activate Hardcore',
    () async {
      await _insertCheckIns(database, const [
        '2026-01-01',
        '2026-01-03',
        '2026-01-08',
        '2026-02-01',
        '2026-03-15',
        '2026-05-20',
        '2026-07-22',
        '2026-01-01',
        '',
        'not-a-date',
        '2026-02-30',
        '2026-7-22',
      ]);

      final eligibility = await service.getHardcoreEligibility();
      expect(eligibility.validCheckIns, 7);
      expect(eligibility.requiredCheckIns, 7);
      expect(eligibility.isUnlocked, isTrue);
      expect(eligibility.progress, 1);

      await service.setActiveMode('hardcore');

      expect(await _settingValue(database), 'hardcore');
      expect(await _campaignMode(database), 'hardcore');
      expect(await _historyCount(database), 1);
    },
  );

  test(
    'existing Hardcore is grandfathered until the user leaves the mode',
    () async {
      await database.update(
        'settings',
        {'value': 'hardcore'},
        where: 'key = ?',
        whereArgs: ['active_difficulty_mode'],
      );
      await database.update(
        'campaigns',
        {'difficulty_mode': null},
        where: 'id = ?',
        whereArgs: ['campaign_main'],
      );
      await _insertCheckIns(database, const ['2026-01-01', '2026-04-01']);

      await service.setActiveMode('hardcore');

      expect(await _settingValue(database), 'hardcore');
      expect(await _campaignMode(database), 'hardcore');
      expect(await _historyCount(database), 0);
      final unchangedHero = (await database.query('hero_profiles')).single;
      expect(unchangedHero['level'], 99);
      expect(unchangedHero['updated_at'], 'original');

      await service.setActiveMode('normal');
      expect(await _settingValue(database), 'normal');
      expect(await _historyCount(database), 1);

      await expectLater(
        service.setActiveMode('hardcore'),
        throwsA(isA<HardcoreLockedException>()),
      );
      expect(await _settingValue(database), 'normal');
      expect(await _campaignMode(database), 'normal');
      expect(await _historyCount(database), 1);
    },
  );

  test('idempotent Normal recreates a missing canonical setting', () async {
    await database.delete(
      'settings',
      where: 'key = ?',
      whereArgs: ['active_difficulty_mode'],
    );

    await service.setActiveMode('normal');

    expect(await _settingValue(database), 'normal');
    expect(await _campaignMode(database), 'normal');
    expect(await _historyCount(database), 0);
    final hero = (await database.query('hero_profiles')).single;
    expect(hero['level'], 99);
    expect(hero['updated_at'], 'original');
  });

  test('transaction-aware guard rolls back caller changes', () async {
    await _insertCheckIns(database, const [
      '2026-01-01',
      '2026-01-02',
      '2026-01-03',
      '2026-01-04',
      '2026-01-05',
      '2026-01-06',
    ]);

    await expectLater(
      database.transaction((transaction) async {
        await transaction.update(
          'hero_profiles',
          {'updated_at': 'tentative-onboarding-write'},
          where: 'id = ?',
          whereArgs: ['main_hero'],
        );
        await service.setActiveModeInTransaction(transaction, 'hardcore');
      }),
      throwsA(isA<HardcoreLockedException>()),
    );

    expect(await _settingValue(database), 'normal');
    expect(await _campaignMode(database), 'normal');
    expect(await _historyCount(database), 0);
    final hero = (await database.query('hero_profiles')).single;
    expect(hero['updated_at'], 'original');
  });
}

Future<void> _createSchema(Database database) async {
  await database.execute('''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      value_type TEXT NOT NULL,
      description TEXT,
      updated_at TEXT NOT NULL
    );
  ''');
  await database.execute('''
    CREATE TABLE campaigns (
      id TEXT PRIMARY KEY,
      difficulty_mode TEXT,
      is_active INTEGER NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''');
  await database.execute('''
    CREATE TABLE daily_checkins (
      id TEXT PRIMARY KEY,
      checkin_date TEXT NOT NULL
    );
  ''');
  await database.execute('''
    CREATE TABLE hero_profiles (
      id TEXT PRIMARY KEY,
      xp INTEGER NOT NULL,
      level INTEGER NOT NULL,
      updated_at TEXT NOT NULL
    );
  ''');
  await database.execute('''
    CREATE TABLE history_events (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      type TEXT NOT NULL,
      xp_delta INTEGER NOT NULL,
      coins_delta INTEGER NOT NULL,
      occurred_at TEXT NOT NULL
    );
  ''');

  await database.insert('settings', {
    'key': 'active_difficulty_mode',
    'value': 'normal',
    'value_type': 'string',
    'description': 'test',
    'updated_at': 'original',
  });
  await database.insert('campaigns', {
    'id': 'campaign_main',
    'difficulty_mode': 'normal',
    'is_active': 1,
    'updated_at': 'original',
  });
  await database.insert('hero_profiles', {
    'id': 'main_hero',
    'xp': 0,
    'level': 99,
    'updated_at': 'original',
  });
}

Future<void> _insertCheckIns(Database database, List<String> dates) async {
  for (var index = 0; index < dates.length; index++) {
    await database.insert('daily_checkins', {
      'id': 'checkin_$index',
      'checkin_date': dates[index],
    });
  }
}

Future<String> _settingValue(Database database) async {
  final row = (await database.query(
    'settings',
    columns: ['value'],
    where: 'key = ?',
    whereArgs: ['active_difficulty_mode'],
  )).single;
  return row['value']! as String;
}

Future<String> _campaignMode(Database database) async {
  final row = (await database.query(
    'campaigns',
    columns: ['difficulty_mode'],
    where: 'id = ?',
    whereArgs: ['campaign_main'],
  )).single;
  return row['difficulty_mode']! as String;
}

Future<int> _historyCount(Database database) async {
  final row = (await database.rawQuery(
    'SELECT COUNT(*) AS total FROM history_events;',
  )).single;
  return (row['total']! as num).toInt();
}
