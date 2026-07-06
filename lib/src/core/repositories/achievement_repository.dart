import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/game_models.dart';
import '../models/v3_commitment_models.dart';
import '../services/progression_service.dart';
import '../utils/id_generator.dart';

class AchievementSummary {
  const AchievementSummary({
    required this.total,
    required this.unlocked,
    required this.totalXpAvailable,
    required this.totalXpUnlocked,
  });

  final int total;
  final int unlocked;
  final int totalXpAvailable;
  final int totalXpUnlocked;

  int get locked => (total - unlocked).clamp(0, total).toInt();
  double get progress => total <= 0 ? 0 : (unlocked / total).clamp(0, 1).toDouble();
}

class AchievementSyncResult {
  const AchievementSyncResult({
    required this.updated,
    required this.unlocked,
    required this.xpGained,
    required this.coinsGained,
    required this.unlockedTitles,
  });

  final int updated;
  final int unlocked;
  final int xpGained;
  final int coinsGained;
  final List<String> unlockedTitles;

  bool get hasUnlocks => unlocked > 0;

  String get message {
    if (!hasUnlocks) return 'Conquistas sincronizadas. Nenhum novo desbloqueio agora.';
    final reward = xpGained > 0 ? ' +$xpGained XP' : '';
    return '$unlocked conquista(s) desbloqueada(s)!$reward';
  }
}

class AchievementRepository {
  Future<List<HeroAchievementProgress>> getAchievements() async {
    final db = await AppDatabase.instance.database;
    await refreshAutomaticAchievements();

    final rows = await _queryAchievements(db);
    return rows.map(HeroAchievementProgress.fromMap).toList();
  }

  Future<AchievementSummary> getSummary() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        COALESCE(SUM(CASE WHEN hero_achievements.is_unlocked = 1 THEN 1 ELSE 0 END), 0) AS unlocked,
        COALESCE(SUM(achievements.xp_reward), 0) AS total_xp_available,
        COALESCE(SUM(CASE WHEN hero_achievements.is_unlocked = 1 THEN achievements.xp_reward ELSE 0 END), 0) AS total_xp_unlocked
      FROM achievements
      INNER JOIN hero_achievements ON hero_achievements.achievement_id = achievements.id
      WHERE achievements.is_active = 1;
    ''');

    if (rows.isEmpty) {
      return const AchievementSummary(
        total: 0,
        unlocked: 0,
        totalXpAvailable: 0,
        totalXpUnlocked: 0,
      );
    }

    final row = rows.first;
    return AchievementSummary(
      total: readInt(row, 'total'),
      unlocked: readInt(row, 'unlocked'),
      totalXpAvailable: readInt(row, 'total_xp_available'),
      totalXpUnlocked: readInt(row, 'total_xp_unlocked'),
    );
  }

  Future<AchievementSyncResult> refreshAutomaticAchievements() async {
    final db = await AppDatabase.instance.database;
    final achievements = await _loadActiveAchievements(db);
    if (achievements.isEmpty) {
      return const AchievementSyncResult(
        updated: 0,
        unlocked: 0,
        xpGained: 0,
        coinsGained: 0,
        unlockedTitles: [],
      );
    }

    final stats = await _calculateStats(db);
    final now = DateTime.now().toIso8601String();
    var updated = 0;
    var unlocked = 0;
    var xpGained = 0;
    var coinsGained = 0;
    final unlockedTitles = <String>[];

    await db.transaction((txn) async {
      for (final achievement in achievements) {
        final rawProgress = _progressFor(achievement.code, stats);
        final progress = rawProgress.clamp(0, achievement.targetValue).toInt();
        final shouldUnlock = progress >= achievement.targetValue;

        final heroRows = await txn.query(
          'hero_achievements',
          where: 'achievement_id = ?',
          whereArgs: [achievement.id],
          limit: 1,
        );

        if (heroRows.isEmpty) {
          await txn.insert(
            'hero_achievements',
            {
              'id': 'hero_${achievement.code}',
              'achievement_id': achievement.id,
              'progress_value': progress,
              'is_unlocked': shouldUnlock ? 1 : 0,
              'unlocked_at': shouldUnlock ? now : null,
              'created_at': now,
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          updated++;
          if (shouldUnlock) {
            unlocked++;
            xpGained += achievement.xpReward;
            coinsGained += achievement.coinsReward;
            unlockedTitles.add(achievement.title);
            await _insertUnlockHistory(txn, achievement, now);
          }
          continue;
        }

        final heroRow = heroRows.first;
        final wasUnlocked = readInt(heroRow, 'is_unlocked') == 1;
        final nextUnlocked = wasUnlocked || shouldUnlock;
        final nextProgress = wasUnlocked
            ? readInt(heroRow, 'progress_value').clamp(progress, achievement.targetValue).toInt()
            : progress;

        await txn.update(
          'hero_achievements',
          {
            'progress_value': nextUnlocked ? achievement.targetValue : nextProgress,
            'is_unlocked': nextUnlocked ? 1 : 0,
            'unlocked_at': !wasUnlocked && nextUnlocked ? now : heroRow['unlocked_at'],
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [heroRow['id']],
        );
        updated++;

        if (!wasUnlocked && nextUnlocked) {
          unlocked++;
          xpGained += achievement.xpReward;
          coinsGained += achievement.coinsReward;
          unlockedTitles.add(achievement.title);
          await _insertUnlockHistory(txn, achievement, now);
        }
      }

      if (xpGained > 0 || coinsGained > 0) {
        await _applyHeroReward(txn, xp: xpGained, coins: coinsGained, nowIso: now);
      }
    });

    return AchievementSyncResult(
      updated: updated,
      unlocked: unlocked,
      xpGained: xpGained,
      coinsGained: coinsGained,
      unlockedTitles: unlockedTitles,
    );
  }

  Future<void> updateProgress({
    required String achievementCode,
    required int progressValue,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'achievements',
      where: 'code = ?',
      whereArgs: [achievementCode],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final achievement = GameAchievement.fromMap(rows.first);
    final progress = progressValue.clamp(0, achievement.targetValue).toInt();
    final shouldUnlock = progress >= achievement.targetValue;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final heroRows = await txn.query(
        'hero_achievements',
        where: 'achievement_id = ?',
        whereArgs: [achievement.id],
        limit: 1,
      );
      if (heroRows.isEmpty) return;

      final wasUnlocked = readInt(heroRows.first, 'is_unlocked') == 1;
      await txn.update(
        'hero_achievements',
        {
          'progress_value': shouldUnlock ? achievement.targetValue : progress,
          'is_unlocked': wasUnlocked || shouldUnlock ? 1 : 0,
          'unlocked_at': !wasUnlocked && shouldUnlock ? now : heroRows.first['unlocked_at'],
          'updated_at': now,
        },
        where: 'achievement_id = ? AND is_unlocked = 0',
        whereArgs: [achievement.id],
      );

      if (!wasUnlocked && shouldUnlock) {
        await _insertUnlockHistory(txn, achievement, now);
        await _applyHeroReward(
          txn,
          xp: achievement.xpReward,
          coins: achievement.coinsReward,
          nowIso: now,
        );
      }
    });
  }

  Future<bool> unlockByCode(String achievementCode) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'achievements',
      where: 'code = ?',
      whereArgs: [achievementCode],
      limit: 1,
    );
    if (rows.isEmpty) return false;

    final achievement = GameAchievement.fromMap(rows.first);
    final now = DateTime.now().toIso8601String();
    var unlockedNow = false;

    await db.transaction((txn) async {
      final progressRows = await txn.query(
        'hero_achievements',
        where: 'achievement_id = ?',
        whereArgs: [achievement.id],
        limit: 1,
      );
      if (progressRows.isEmpty || progressRows.first['is_unlocked'] == 1) {
        return;
      }

      unlockedNow = true;
      await txn.update(
        'hero_achievements',
        {
          'progress_value': achievement.targetValue,
          'is_unlocked': 1,
          'unlocked_at': now,
          'updated_at': now,
        },
        where: 'achievement_id = ?',
        whereArgs: [achievement.id],
      );

      await _insertUnlockHistory(txn, achievement, now);
      await _applyHeroReward(
        txn,
        xp: achievement.xpReward,
        coins: achievement.coinsReward,
        nowIso: now,
      );
    });

    return unlockedNow;
  }

  Future<List<Map<String, Object?>>> _queryAchievements(Database db) {
    return db.rawQuery('''
      SELECT
        hero_achievements.id AS hero_achievement_id,
        hero_achievements.achievement_id,
        hero_achievements.progress_value,
        hero_achievements.is_unlocked,
        hero_achievements.unlocked_at,
        achievements.*
      FROM hero_achievements
      INNER JOIN achievements ON achievements.id = hero_achievements.achievement_id
      WHERE achievements.is_active = 1
      ORDER BY hero_achievements.is_unlocked DESC, achievements.category ASC, achievements.target_value ASC;
    ''');
  }

  Future<List<GameAchievement>> _loadActiveAchievements(Database db) async {
    final rows = await db.query(
      'achievements',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'category ASC, target_value ASC, created_at ASC',
    );
    return rows.map(GameAchievement.fromMap).toList();
  }

  Future<_AchievementStats> _calculateStats(Database db) async {
    final countRows = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM daily_checkins) AS checkins,
        (SELECT COALESCE(MAX(streak_count), 0) FROM daily_checkins) AS best_streak,
        (SELECT COUNT(*) FROM mission_completions) AS missions_completed,
        (SELECT COUNT(*) FROM mission_completions INNER JOIN missions ON missions.id = mission_completions.mission_id WHERE missions.is_compound = 1) AS compound_missions_completed,
        (SELECT COUNT(*) FROM objectives WHERE status = 'completed') AS objectives_completed,
        (SELECT COUNT(*) FROM sessions) AS sessions_registered,
        (SELECT COALESCE(SUM(duration_minutes), 0) FROM sessions) AS focus_minutes,
        (SELECT COUNT(*) FROM projects WHERE status = 'completed') AS projects_completed,
        (SELECT COUNT(*) FROM project_tasks WHERE is_done = 1) AS project_tasks_completed,
        (SELECT COUNT(*) FROM campaign_milestones WHERE status = 'completed') AS campaign_milestones_completed,
        (SELECT COUNT(*) FROM habit_period_rewards) AS habit_rewards,
        (SELECT COUNT(DISTINCT substr(habit_logs.logged_for, 1, 10)) FROM habit_logs INNER JOIN habits ON habits.id = habit_logs.habit_id WHERE habits.health_kind = 'water') AS water_days,
        (SELECT COUNT(*) FROM habit_period_rewards INNER JOIN habits ON habits.id = habit_period_rewards.habit_id WHERE habits.health_kind = 'food_limit') AS food_limit_rewards,
        (SELECT COUNT(*) FROM vaults WHERE status = 'active') AS vaults_created,
        (SELECT COUNT(*) FROM vault_entries WHERE type = 'deposit') AS vault_deposits,
        (SELECT CAST(COALESCE(SUM(CASE WHEN vault_entries.type = 'deposit' THEN vault_entries.amount WHEN vault_entries.type = 'withdraw' THEN -vault_entries.amount ELSE 0 END), 0) AS INTEGER) FROM vaults LEFT JOIN vault_entries ON vault_entries.vault_id = vaults.id WHERE vaults.status = 'active') AS vault_saved,
        (SELECT COUNT(*) FROM shop_purchases) AS shop_purchases,
        (SELECT COUNT(*) FROM shop_purchases WHERE type_snapshot = 'real_purchase') AS real_shop_purchases,
        (SELECT CAST(COALESCE(AVG(progress), 0) * 100 AS INTEGER) FROM campaign_milestones WHERE campaign_id = 'transformation_20_25') AS campaign_progress_percent;
    ''');

    final row = countRows.isEmpty ? <String, Object?>{} : countRows.first;
    return _AchievementStats(
      checkIns: readInt(row, 'checkins'),
      bestStreak: readInt(row, 'best_streak'),
      missionsCompleted: readInt(row, 'missions_completed'),
      compoundMissionsCompleted: readInt(row, 'compound_missions_completed'),
      objectivesCompleted: readInt(row, 'objectives_completed'),
      sessionsRegistered: readInt(row, 'sessions_registered'),
      focusMinutes: readInt(row, 'focus_minutes'),
      projectsCompleted: readInt(row, 'projects_completed'),
      projectTasksCompleted: readInt(row, 'project_tasks_completed'),
      campaignMilestonesCompleted: readInt(row, 'campaign_milestones_completed'),
      habitRewards: readInt(row, 'habit_rewards'),
      waterDays: readInt(row, 'water_days'),
      foodLimitRewards: readInt(row, 'food_limit_rewards'),
      vaultsCreated: readInt(row, 'vaults_created'),
      vaultDeposits: readInt(row, 'vault_deposits'),
      vaultSaved: readInt(row, 'vault_saved'),
      shopPurchases: readInt(row, 'shop_purchases'),
      realShopPurchases: readInt(row, 'real_shop_purchases'),
      campaignProgressPercent: readInt(row, 'campaign_progress_percent'),
    );
  }

  int _progressFor(String code, _AchievementStats stats) {
    return switch (code) {
      'first_checkin' => stats.checkIns,
      'streak_7' => stats.bestStreak,
      'streak_30' => stats.bestStreak,
      'first_mission_completed' => stats.missionsCompleted,
      'missions_10_completed' => stats.missionsCompleted,
      'missions_50_completed' => stats.missionsCompleted,
      'first_compound_mission_completed' => stats.compoundMissionsCompleted,
      'first_objective_completed' => stats.objectivesCompleted,
      'objectives_5_completed' => stats.objectivesCompleted,
      'first_project_completed' => stats.projectsCompleted,
      'project_tasks_10_completed' => stats.projectTasksCompleted,
      'project_tasks_25_completed' => stats.projectTasksCompleted,
      'sessions_first_registered' => stats.sessionsRegistered,
      'sessions_10_registered' => stats.sessionsRegistered,
      'focus_hours_10' => stats.focusMinutes,
      'habit_first_reward' => stats.habitRewards,
      'habits_7_rewards' => stats.habitRewards,
      'water_7_days' => stats.waterDays,
      'food_limit_7_periods' => stats.foodLimitRewards,
      'first_vault_created' => stats.vaultsCreated,
      'first_vault_deposit' => stats.vaultDeposits,
      'vault_saved_100' => stats.vaultSaved,
      'first_shop_purchase' => stats.shopPurchases,
      'first_real_purchase' => stats.realShopPurchases,
      'first_campaign_milestone' => stats.campaignMilestonesCompleted,
      'campaign_progress_25' => stats.campaignProgressPercent,
      'campaign_progress_50' => stats.campaignProgressPercent,
      'campaign_progress_90' => stats.campaignProgressPercent,
      _ => 0,
    };
  }

  Future<void> _insertUnlockHistory(
    DatabaseExecutor executor,
    GameAchievement achievement,
    String nowIso,
  ) async {
    await executor.insert(
      'history_events',
      {
        'id': IdGenerator.create('history'),
        'title': 'Conquista desbloqueada: ${achievement.title}',
        'description': achievement.description,
        'type': 'achievement_unlocked',
        'xp_delta': achievement.xpReward,
        'coins_delta': achievement.coinsReward,
        'occurred_at': nowIso,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> _applyHeroReward(
    DatabaseExecutor executor, {
    required int xp,
    required int coins,
    required String nowIso,
  }) async {
    final heroRows = await executor.query(
      'hero_profiles',
      where: 'id = ?',
      whereArgs: ['main_hero'],
      limit: 1,
    );

    if (heroRows.isEmpty) return;

    final hero = heroRows.first;
    final nextXp = (readInt(hero, 'xp') + xp).clamp(0, 1 << 31).toInt();
    final nextCoins = (readInt(hero, 'coins') + coins).clamp(0, 1 << 31).toInt();

    await executor.update(
      'hero_profiles',
      {
        'xp': nextXp,
        'coins': nextCoins,
        'level': await ProgressionService.levelFromXp(executor, nextXp),
        'updated_at': nowIso,
      },
      where: 'id = ?',
      whereArgs: ['main_hero'],
    );
  }
}

class _AchievementStats {
  const _AchievementStats({
    required this.checkIns,
    required this.bestStreak,
    required this.missionsCompleted,
    required this.compoundMissionsCompleted,
    required this.objectivesCompleted,
    required this.sessionsRegistered,
    required this.focusMinutes,
    required this.projectsCompleted,
    required this.projectTasksCompleted,
    required this.campaignMilestonesCompleted,
    required this.habitRewards,
    required this.waterDays,
    required this.foodLimitRewards,
    required this.vaultsCreated,
    required this.vaultDeposits,
    required this.vaultSaved,
    required this.shopPurchases,
    required this.realShopPurchases,
    required this.campaignProgressPercent,
  });

  final int checkIns;
  final int bestStreak;
  final int missionsCompleted;
  final int compoundMissionsCompleted;
  final int objectivesCompleted;
  final int sessionsRegistered;
  final int focusMinutes;
  final int projectsCompleted;
  final int projectTasksCompleted;
  final int campaignMilestonesCompleted;
  final int habitRewards;
  final int waterDays;
  final int foodLimitRewards;
  final int vaultsCreated;
  final int vaultDeposits;
  final int vaultSaved;
  final int shopPurchases;
  final int realShopPurchases;
  final int campaignProgressPercent;
}
