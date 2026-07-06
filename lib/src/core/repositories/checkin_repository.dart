import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/v3_commitment_models.dart';
import '../utils/id_generator.dart';
import 'achievement_repository.dart';

class CheckInResult {
  const CheckInResult({
    required this.success,
    required this.message,
    required this.streak,
    required this.coinsGained,
  });

  final bool success;
  final String message;
  final int streak;
  final int coinsGained;
}

class CheckInRepository {
  Future<List<DailyCheckIn>> getRecentCheckIns({int limit = 14}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'daily_checkins',
      orderBy: 'checkin_date DESC',
      limit: limit,
    );
    return rows.map(DailyCheckIn.fromMap).toList();
  }

  Future<int> previewTodayCoins() async {
    final db = await AppDatabase.instance.database;
    final summary = await getSummary();
    if (!summary.canCheckInToday) return 0;

    final now = DateTime.now();
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    final nextStreak = summary.lastCheckInDate == yesterday ? summary.currentStreak + 1 : 1;
    return _dailyCoins(db, nextStreak);
  }

  Future<CheckInSummary> getSummary() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('daily_checkins', orderBy: 'checkin_date DESC');
    if (rows.isEmpty) return CheckInSummary.empty();

    final last = DailyCheckIn.fromMap(rows.first);
    final today = _dateKey(DateTime.now());
    final best = rows.fold<int>(0, (value, row) {
      final streak = _readInt(row, 'streak_count');
      return streak > value ? streak : value;
    });

    return CheckInSummary(
      currentStreak: last.streakCount,
      bestStreak: best,
      totalCheckIns: rows.length,
      lastCheckInDate: last.checkInDate,
      canCheckInToday: last.checkInDate != today,
    );
  }

  Future<CheckInResult> checkInToday({String notes = ''}) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final today = _dateKey(now);
    final existing = await db.query(
      'daily_checkins',
      where: 'checkin_date = ?',
      whereArgs: [today],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final summary = await getSummary();
      return CheckInResult(
        success: false,
        message: 'Check-in de hoje já foi feito.',
        streak: summary.currentStreak,
        coinsGained: 0,
      );
    }

    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    final previousRows = await db.query(
      'daily_checkins',
      orderBy: 'checkin_date DESC',
      limit: 1,
    );

    final previous = previousRows.isEmpty ? null : DailyCheckIn.fromMap(previousRows.first);
    final streak = previous?.checkInDate == yesterday ? previous!.streakCount + 1 : 1;
    final coins = await _dailyCoins(db, streak);
    final nowIso = now.toIso8601String();

    await db.transaction((txn) async {
      await txn.insert(
        'daily_checkins',
        {
          'id': IdGenerator.create('checkin'),
          'checkin_date': today,
          'streak_count': streak,
          'coins_gained': coins,
          'notes': notes.trim(),
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

      if (heroRows.isNotEmpty && coins > 0) {
        final currentCoins = _readInt(heroRows.first, 'coins');
        await txn.update(
          'hero_profiles',
          {
            'coins': currentCoins + coins,
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: ['main_hero'],
        );
      }

      await txn.insert(
        'history_events',
        {
          'id': IdGenerator.create('history'),
          'title': 'Check-in diário',
          'description': 'Sequência atual: $streak dia(s).',
          'type': 'daily_checkin',
          'xp_delta': 0,
          'coins_delta': coins,
          'occurred_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });

    await AchievementRepository().refreshAutomaticAchievements();

    return CheckInResult(
      success: true,
      message: 'Check-in feito! Sequência atual: $streak dia(s).',
      streak: streak,
      coinsGained: coins,
    );
  }

  Future<int> _dailyCoins(Database db, int streak) async {
    final base = await _settingInt(db, 'checkin_daily_coins', fallback: 3);
    if (streak > 0 && streak % 30 == 0) {
      return base + await _settingInt(db, 'checkin_streak_bonus_30', fallback: 40);
    }
    if (streak > 0 && streak % 7 == 0) {
      return base + await _settingInt(db, 'checkin_streak_bonus_7', fallback: 10);
    }
    return base;
  }

  Future<int> _settingInt(Database db, String key, {required int fallback}) async {
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return fallback;
    return int.tryParse(rows.first['value']?.toString() ?? '') ?? fallback;
  }

  String _dateKey(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  int _readInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
