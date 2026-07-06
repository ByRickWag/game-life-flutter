import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/game_models.dart';
import '../models/v3_commitment_models.dart';
import '../utils/id_generator.dart';
import 'achievement_repository.dart';

class CampaignCommitmentSummary {
  const CampaignCommitmentSummary({
    required this.campaign,
    required this.lore,
    required this.mainGoal,
    required this.startDate,
    required this.endDate,
    required this.difficultyMode,
    required this.victoryMinimumPercent,
    required this.victoryGoodPercent,
    required this.victoryExcellentPercent,
    required this.milestones,
    required this.signals,
  });

  final Campaign? campaign;
  final String lore;
  final String mainGoal;
  final String startDate;
  final String endDate;
  final String difficultyMode;
  final int victoryMinimumPercent;
  final int victoryGoodPercent;
  final int victoryExcellentPercent;
  final List<CampaignMilestone> milestones;
  final CampaignProgressSignals signals;

  double get progressPercent {
    if (milestones.isEmpty) return signals.overallProgress;
    final total = milestones.fold<double>(0, (sum, item) => sum + item.progress);
    final value = total / milestones.length;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  int get completedMilestones => milestones.where((item) => item.isCompleted).length;

  int get totalMilestones => milestones.length;

  String get victoryStatusLabel {
    final percent = (progressPercent * 100).round();
    if (percent >= victoryExcellentPercent) return 'Vitória excelente';
    if (percent >= victoryGoodPercent) return 'Vitória boa';
    if (percent >= victoryMinimumPercent) return 'Vitória mínima';
    return 'Em campanha';
  }
}

class CampaignProgressSignals {
  const CampaignProgressSignals({
    required this.checkIns,
    required this.bestStreak,
    required this.missionsCompleted,
    required this.objectivesCompleted,
    required this.sessionsRegistered,
    required this.focusMinutes,
    required this.habitRewards,
    required this.waterDays,
    required this.foodLimitRewards,
    required this.projectsCompleted,
    required this.projectTasksCompleted,
    required this.achievementsUnlocked,
    required this.vaultSaved,
    required this.vaultDeposits,
    required this.shopPurchases,
    required this.totalAttributeXp,
    required this.strengthXp,
    required this.vigorXp,
    required this.clarityXp,
    required this.focusXp,
    required this.responsibilityXp,
    required this.disciplineXp,
    required this.faithXp,
    required this.bodyHealthAreaXp,
    required this.mindKnowledgeAreaXp,
    required this.spiritPurposeAreaXp,
    required this.projectsCareerAreaXp,
    required this.creationExpressionAreaXp,
    required this.financeResponsibilityAreaXp,
    required this.routineOrderAreaXp,
  });

  final int checkIns;
  final int bestStreak;
  final int missionsCompleted;
  final int objectivesCompleted;
  final int sessionsRegistered;
  final int focusMinutes;
  final int habitRewards;
  final int waterDays;
  final int foodLimitRewards;
  final int projectsCompleted;
  final int projectTasksCompleted;
  final int achievementsUnlocked;
  final int vaultSaved;
  final int vaultDeposits;
  final int shopPurchases;
  final int totalAttributeXp;
  final int strengthXp;
  final int vigorXp;
  final int clarityXp;
  final int focusXp;
  final int responsibilityXp;
  final int disciplineXp;
  final int faithXp;
  final int bodyHealthAreaXp;
  final int mindKnowledgeAreaXp;
  final int spiritPurposeAreaXp;
  final int projectsCareerAreaXp;
  final int creationExpressionAreaXp;
  final int financeResponsibilityAreaXp;
  final int routineOrderAreaXp;

  int areaXp(String areaId) {
    return switch (areaId) {
      'body_health' => bodyHealthAreaXp,
      'mind_knowledge' => mindKnowledgeAreaXp,
      'spirit_purpose' => spiritPurposeAreaXp,
      'projects_career' => projectsCareerAreaXp,
      'creation_expression' => creationExpressionAreaXp,
      'finance_responsibility' => financeResponsibilityAreaXp,
      'routine_order' => routineOrderAreaXp,
      _ => 0,
    };
  }

  int get totalAreaXp => bodyHealthAreaXp + mindKnowledgeAreaXp + spiritPurposeAreaXp + projectsCareerAreaXp + creationExpressionAreaXp + financeResponsibilityAreaXp + routineOrderAreaXp;

  double get overallProgress {
    return _average([
      _ratio(bestStreak, 7),
      _ratio(missionsCompleted, 25),
      _ratio(habitRewards, 14),
      _ratio(focusMinutes, 600),
      _ratio(projectTasksCompleted, 15),
      _ratio(achievementsUnlocked, 8),
      _ratio(totalAttributeXp, 500),
      _ratio(totalAreaXp, 600),
      _ratio(vaultSaved, 100),
    ]);
  }

  int get focusHours => focusMinutes ~/ 60;
}

class UpdateCampaignCommitmentInput {
  const UpdateCampaignCommitmentInput({
    required this.campaignId,
    required this.title,
    required this.description,
    required this.lore,
    required this.mainGoal,
    required this.startDate,
    required this.endDate,
    required this.difficultyMode,
    required this.victoryMinimumPercent,
    required this.victoryGoodPercent,
    required this.victoryExcellentPercent,
  });

  final String campaignId;
  final String title;
  final String description;
  final String lore;
  final String mainGoal;
  final String startDate;
  final String? endDate;
  final String difficultyMode;
  final int victoryMinimumPercent;
  final int victoryGoodPercent;
  final int victoryExcellentPercent;
}

class CreateCampaignMilestoneInput {
  const CreateCampaignMilestoneInput({
    required this.campaignId,
    required this.title,
    required this.description,
    required this.lore,
    required this.targetDate,
    required this.startDate,
    required this.endDate,
    required this.primaryAreaId,
    required this.secondaryAreaIds,
    required this.sortOrder,
    required this.xpReward,
    required this.coinsReward,
  });

  final String campaignId;
  final String title;
  final String description;
  final String lore;
  final String? targetDate;
  final String? startDate;
  final String? endDate;
  final String? primaryAreaId;
  final String secondaryAreaIds;
  final int sortOrder;
  final int xpReward;
  final int coinsReward;
}

class UpdateCampaignMilestoneInput {
  const UpdateCampaignMilestoneInput({
    required this.milestoneId,
    required this.title,
    required this.description,
    required this.lore,
    required this.targetDate,
    required this.startDate,
    required this.endDate,
    required this.primaryAreaId,
    required this.secondaryAreaIds,
    required this.sortOrder,
    required this.progress,
    required this.xpReward,
    required this.coinsReward,
  });

  final String milestoneId;
  final String title;
  final String description;
  final String lore;
  final String? targetDate;
  final String? startDate;
  final String? endDate;
  final String? primaryAreaId;
  final String secondaryAreaIds;
  final int sortOrder;
  final double progress;
  final int xpReward;
  final int coinsReward;
}

class CampaignCommitmentRepository {
  Future<CampaignCommitmentSummary> getActiveCampaignSummary() async {
    final db = await AppDatabase.instance.database;
    var rows = await db.query(
      'campaigns',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      await _ensureDefaultCampaign(db);
      rows = await db.query(
        'campaigns',
        where: 'is_active = ?',
        whereArgs: [1],
        limit: 1,
      );
    }

    final campaignRow = rows.isEmpty ? null : rows.first;
    final campaign = campaignRow == null ? null : Campaign.fromMap(campaignRow);
    final campaignId = campaign?.id ?? 'transformation_20_25';
    final signals = await _calculateSignals(db);

    var milestones = await getMilestones(campaignId);
    final changed = await _syncAutomaticMilestones(db, milestones, signals);
    if (changed) {
      milestones = await getMilestones(campaignId);
    }

    return CampaignCommitmentSummary(
      campaign: campaign,
      lore: _readString(campaignRow, 'lore'),
      mainGoal: _readString(campaignRow, 'main_goal'),
      startDate: _readString(campaignRow, 'start_date'),
      endDate: _readString(campaignRow, 'end_date'),
      difficultyMode: _readString(campaignRow, 'difficulty_mode', fallback: 'normal'),
      victoryMinimumPercent: _readInt(campaignRow, 'victory_minimum_percent', fallback: 60),
      victoryGoodPercent: _readInt(campaignRow, 'victory_good_percent', fallback: 75),
      victoryExcellentPercent: _readInt(campaignRow, 'victory_excellent_percent', fallback: 90),
      milestones: milestones,
      signals: signals,
    );
  }

  Future<List<CampaignMilestone>> getMilestones(String campaignId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'campaign_milestones',
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(CampaignMilestone.fromMap).toList();
  }

  Future<void> syncAutomaticProgress() async {
    final db = await AppDatabase.instance.database;
    final summary = await getActiveCampaignSummary();
    await _syncAutomaticMilestones(db, summary.milestones, summary.signals);
    await AchievementRepository().refreshAutomaticAchievements();
  }

  Future<void> updateCampaign(UpdateCampaignCommitmentInput input) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'campaigns',
      {
        'title': input.title.trim(),
        'description': input.description.trim(),
        'lore': input.lore.trim(),
        'main_goal': input.mainGoal.trim(),
        'start_date': input.startDate.trim().isEmpty ? DateTime.now().toIso8601String().substring(0, 10) : input.startDate.trim(),
        'end_date': _nullable(input.endDate),
        'difficulty_mode': input.difficultyMode,
        'victory_minimum_percent': input.victoryMinimumPercent,
        'victory_good_percent': input.victoryGoodPercent,
        'victory_excellent_percent': input.victoryExcellentPercent,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [input.campaignId],
    );
  }

  Future<void> createMilestone(CreateCampaignMilestoneInput input) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'campaign_milestones',
      {
        'id': IdGenerator.create('milestone'),
        'campaign_id': input.campaignId,
        'title': input.title.trim(),
        'description': input.description.trim(),
        'lore': input.lore.trim(),
        'target_date': _nullable(input.targetDate),
        'start_date': _nullable(input.startDate),
        'end_date': _nullable(input.endDate),
        'primary_area_id': _nullable(input.primaryAreaId),
        'secondary_area_ids': input.secondaryAreaIds.trim(),
        'chapter_kind': 'chapter',
        'sort_order': input.sortOrder,
        'status': 'active',
        'progress': 0.0,
        'xp_reward': input.xpReward,
        'coins_reward': input.coinsReward,
        'automation_key': null,
        'auto_progress_enabled': 0,
        'progress_note': null,
        'completed_at': null,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateMilestone(UpdateCampaignMilestoneInput input) async {
    final db = await AppDatabase.instance.database;
    final safeProgress = input.progress.clamp(0.0, 1.0).toDouble();
    final now = DateTime.now().toIso8601String();
    await db.update(
      'campaign_milestones',
      {
        'title': input.title.trim(),
        'description': input.description.trim(),
        'lore': input.lore.trim(),
        'target_date': _nullable(input.targetDate),
        'start_date': _nullable(input.startDate),
        'end_date': _nullable(input.endDate),
        'primary_area_id': _nullable(input.primaryAreaId),
        'secondary_area_ids': input.secondaryAreaIds.trim(),
        'chapter_kind': 'chapter',
        'sort_order': input.sortOrder,
        'progress': safeProgress,
        'status': safeProgress >= 1 ? 'completed' : 'active',
        'xp_reward': input.xpReward,
        'coins_reward': input.coinsReward,
        'completed_at': safeProgress >= 1 ? now : null,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [input.milestoneId],
    );

    if (safeProgress >= 1) {
      await AchievementRepository().refreshAutomaticAchievements();
    }
  }

  Future<void> updateMilestoneProgress({
    required String milestoneId,
    required double progress,
  }) async {
    final db = await AppDatabase.instance.database;
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final now = DateTime.now().toIso8601String();
    await db.update(
      'campaign_milestones',
      {
        'progress': safeProgress,
        'status': safeProgress >= 1 ? 'completed' : 'active',
        'completed_at': safeProgress >= 1 ? now : null,
        'updated_at': now,
      },
      where: 'id = ? AND auto_progress_enabled = 0',
      whereArgs: [milestoneId],
    );

    if (safeProgress >= 1) {
      await AchievementRepository().refreshAutomaticAchievements();
    }
  }

  Future<void> completeMilestone(String milestoneId) {
    return updateMilestoneProgress(milestoneId: milestoneId, progress: 1);
  }

  Future<void> reopenMilestone(String milestoneId) {
    return updateMilestoneProgress(milestoneId: milestoneId, progress: 0.75);
  }

  Future<void> deleteMilestone(String milestoneId) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'campaign_milestones',
      where: 'id = ? AND auto_progress_enabled = 0',
      whereArgs: [milestoneId],
    );
  }

  Future<bool> _syncAutomaticMilestones(
    Database db,
    List<CampaignMilestone> milestones,
    CampaignProgressSignals signals,
  ) async {
    var changed = false;
    final now = DateTime.now().toIso8601String();

    for (final milestone in milestones) {
      if (!milestone.autoProgressEnabled || milestone.automationKey.trim().isEmpty) continue;
      final computed = _computeMilestoneProgress(milestone, signals);
      final nextProgress = computed.progress.clamp(0.0, 1.0).toDouble();
      final currentProgress = milestone.progress.clamp(0.0, 1.0).toDouble();
      final nextStatus = nextProgress >= 1 ? 'completed' : 'active';
      final nextCompletedAt = nextProgress >= 1 ? (milestone.completedAt.isEmpty ? now : milestone.completedAt) : null;

      if ((nextProgress - currentProgress).abs() < 0.001 && milestone.status == nextStatus && milestone.progressNote == computed.note) {
        continue;
      }

      await db.update(
        'campaign_milestones',
        {
          'progress': nextProgress,
          'status': nextStatus,
          'progress_note': computed.note,
          'completed_at': nextCompletedAt,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [milestone.id],
      );
      changed = true;
    }

    if (changed) {
      await AchievementRepository().refreshAutomaticAchievements();
    }
    return changed;
  }

  Future<CampaignProgressSignals> _calculateSignals(Database db) async {
    final rows = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM daily_checkins) AS checkins,
        (SELECT COALESCE(MAX(streak_count), 0) FROM daily_checkins) AS best_streak,
        (SELECT COUNT(*) FROM mission_completions) AS missions_completed,
        (SELECT COUNT(*) FROM objectives WHERE status = 'completed') AS objectives_completed,
        (SELECT COUNT(*) FROM sessions) AS sessions_registered,
        (SELECT COALESCE(SUM(duration_minutes), 0) FROM sessions) AS focus_minutes,
        (SELECT COUNT(*) FROM habit_period_rewards) AS habit_rewards,
        (SELECT COUNT(DISTINCT substr(habit_logs.logged_for, 1, 10)) FROM habit_logs INNER JOIN habits ON habits.id = habit_logs.habit_id WHERE habits.health_kind = 'water') AS water_days,
        (SELECT COUNT(*) FROM habit_period_rewards INNER JOIN habits ON habits.id = habit_period_rewards.habit_id WHERE habits.health_kind = 'food_limit') AS food_limit_rewards,
        (SELECT COUNT(*) FROM projects WHERE status = 'completed') AS projects_completed,
        (SELECT COUNT(*) FROM project_tasks WHERE is_done = 1) AS project_tasks_completed,
        (SELECT COUNT(*) FROM hero_achievements INNER JOIN achievements ON achievements.id = hero_achievements.achievement_id WHERE hero_achievements.is_unlocked = 1 AND achievements.is_active = 1) AS achievements_unlocked,
        (SELECT CAST(COALESCE(SUM(CASE WHEN vault_entries.type = 'deposit' THEN vault_entries.amount WHEN vault_entries.type = 'withdraw' THEN -vault_entries.amount ELSE 0 END), 0) AS INTEGER) FROM vaults LEFT JOIN vault_entries ON vault_entries.vault_id = vaults.id WHERE vaults.status = 'active') AS vault_saved,
        (SELECT COUNT(*) FROM vault_entries WHERE type = 'deposit') AS vault_deposits,
        (SELECT COUNT(*) FROM shop_purchases) AS shop_purchases,
        (SELECT COALESCE(SUM(xp), 0) FROM hero_attributes) AS total_attribute_xp,
        (SELECT COALESCE(xp, 0) FROM hero_attributes WHERE attribute_id = 'strength' LIMIT 1) AS strength_xp,
        (SELECT COALESCE(xp, 0) FROM hero_attributes WHERE attribute_id = 'vigor' LIMIT 1) AS vigor_xp,
        (SELECT COALESCE(xp, 0) FROM hero_attributes WHERE attribute_id = 'clarity' LIMIT 1) AS clarity_xp,
        (SELECT COALESCE(xp, 0) FROM hero_attributes WHERE attribute_id = 'focus' LIMIT 1) AS focus_xp,
        (SELECT COALESCE(xp, 0) FROM hero_attributes WHERE attribute_id = 'responsibility' LIMIT 1) AS responsibility_xp,
        (SELECT COALESCE(xp, 0) FROM hero_attributes WHERE attribute_id = 'discipline' LIMIT 1) AS discipline_xp,
        (SELECT COALESCE(xp, 0) FROM hero_attributes WHERE attribute_id = 'faith' LIMIT 1) AS faith_xp,
        (SELECT COALESCE(xp, 0) FROM hero_areas WHERE area_id = 'body_health' LIMIT 1) AS body_health_area_xp,
        (SELECT COALESCE(xp, 0) FROM hero_areas WHERE area_id = 'mind_knowledge' LIMIT 1) AS mind_knowledge_area_xp,
        (SELECT COALESCE(xp, 0) FROM hero_areas WHERE area_id = 'spirit_purpose' LIMIT 1) AS spirit_purpose_area_xp,
        (SELECT COALESCE(xp, 0) FROM hero_areas WHERE area_id = 'projects_career' LIMIT 1) AS projects_career_area_xp,
        (SELECT COALESCE(xp, 0) FROM hero_areas WHERE area_id = 'creation_expression' LIMIT 1) AS creation_expression_area_xp,
        (SELECT COALESCE(xp, 0) FROM hero_areas WHERE area_id = 'finance_responsibility' LIMIT 1) AS finance_responsibility_area_xp,
        (SELECT COALESCE(xp, 0) FROM hero_areas WHERE area_id = 'routine_order' LIMIT 1) AS routine_order_area_xp;
    ''');

    final row = rows.isEmpty ? <String, Object?>{} : rows.first;
    return CampaignProgressSignals(
      checkIns: readInt(row, 'checkins'),
      bestStreak: readInt(row, 'best_streak'),
      missionsCompleted: readInt(row, 'missions_completed'),
      objectivesCompleted: readInt(row, 'objectives_completed'),
      sessionsRegistered: readInt(row, 'sessions_registered'),
      focusMinutes: readInt(row, 'focus_minutes'),
      habitRewards: readInt(row, 'habit_rewards'),
      waterDays: readInt(row, 'water_days'),
      foodLimitRewards: readInt(row, 'food_limit_rewards'),
      projectsCompleted: readInt(row, 'projects_completed'),
      projectTasksCompleted: readInt(row, 'project_tasks_completed'),
      achievementsUnlocked: readInt(row, 'achievements_unlocked'),
      vaultSaved: readInt(row, 'vault_saved'),
      vaultDeposits: readInt(row, 'vault_deposits'),
      shopPurchases: readInt(row, 'shop_purchases'),
      totalAttributeXp: readInt(row, 'total_attribute_xp'),
      strengthXp: readInt(row, 'strength_xp'),
      vigorXp: readInt(row, 'vigor_xp'),
      clarityXp: readInt(row, 'clarity_xp'),
      focusXp: readInt(row, 'focus_xp'),
      responsibilityXp: readInt(row, 'responsibility_xp'),
      disciplineXp: readInt(row, 'discipline_xp'),
      faithXp: readInt(row, 'faith_xp'),
      bodyHealthAreaXp: readInt(row, 'body_health_area_xp'),
      mindKnowledgeAreaXp: readInt(row, 'mind_knowledge_area_xp'),
      spiritPurposeAreaXp: readInt(row, 'spirit_purpose_area_xp'),
      projectsCareerAreaXp: readInt(row, 'projects_career_area_xp'),
      creationExpressionAreaXp: readInt(row, 'creation_expression_area_xp'),
      financeResponsibilityAreaXp: readInt(row, 'finance_responsibility_area_xp'),
      routineOrderAreaXp: readInt(row, 'routine_order_area_xp'),
    );
  }

  _ComputedCampaignProgress _computeMilestoneProgress(CampaignMilestone milestone, CampaignProgressSignals signals) {
    final keyProgress = _computeAutomationKeyProgress(milestone.automationKey, signals);
    final areaProgress = _computeAreaProgress(milestone, signals);

    if (areaProgress == null) return keyProgress;

    final combined = (areaProgress.progress * 0.55) + (keyProgress.progress * 0.45);
    return _ComputedCampaignProgress(
      progress: combined.clamp(0.0, 1.0).toDouble(),
      note: '${areaProgress.note} • ${keyProgress.note}',
    );
  }

  _ComputedCampaignProgress? _computeAreaProgress(CampaignMilestone milestone, CampaignProgressSignals signals) {
    final primaryAreaId = milestone.primaryAreaId.trim();
    if (primaryAreaId.isEmpty) return null;

    final target = _chapterAreaTargetXp(milestone);
    final primaryXp = signals.areaXp(primaryAreaId);
    final secondaryIds = milestone.secondaryAreaIdList;
    final secondaryProgress = secondaryIds.isEmpty
        ? 0.0
        : _average(secondaryIds.map((id) => _ratio(signals.areaXp(id), (target * 0.6).round())).toList());

    final progress = secondaryIds.isEmpty
        ? _ratio(primaryXp, target)
        : (_ratio(primaryXp, target) * 0.72) + (secondaryProgress * 0.28);

    final primaryLabel = _areaLabel(primaryAreaId);
    final secondaryLabel = secondaryIds.isEmpty ? 'sem áreas secundárias' : secondaryIds.map(_areaLabel).join(', ');
    return _ComputedCampaignProgress(
      progress: progress.clamp(0.0, 1.0).toDouble(),
      note: '$primaryLabel: $primaryXp/$target XP • Apoio: $secondaryLabel',
    );
  }

  int _chapterAreaTargetXp(CampaignMilestone milestone) {
    final order = milestone.sortOrder <= 0 ? 1 : milestone.sortOrder;
    return 140 + (order * 80);
  }

  _ComputedCampaignProgress _computeAutomationKeyProgress(String automationKey, CampaignProgressSignals signals) {
    switch (automationKey) {
      case 'foundation':
        return _ComputedCampaignProgress(
          progress: _average([
            _ratio(signals.bestStreak, 7),
            _ratio(signals.missionsCompleted, 15),
            _ratio(signals.habitRewards, 10),
            _ratio(signals.waterDays, 7),
            _ratio(signals.disciplineXp, 100),
          ]),
          note: '${signals.bestStreak}/7 dias de sequência • ${signals.missionsCompleted}/15 missões • ${signals.habitRewards}/10 recompensas de hábito',
        );
      case 'body_health':
        return _ComputedCampaignProgress(
          progress: _average([
            _ratio(signals.waterDays, 14),
            _ratio(signals.foodLimitRewards, 4),
            _ratio(signals.sessionsRegistered, 8),
            _ratio(signals.strengthXp + signals.vigorXp, 220),
          ]),
          note: '${signals.waterDays}/14 dias com água • ${signals.foodLimitRewards}/4 períodos alimentares • ${signals.sessionsRegistered}/8 sessões',
        );
      case 'mind_programming':
        return _ComputedCampaignProgress(
          progress: _average([
            _ratio(signals.focusMinutes, 900),
            _ratio(signals.objectivesCompleted, 2),
            _ratio(signals.projectTasksCompleted, 12),
            _ratio(signals.clarityXp + signals.focusXp, 220),
          ]),
          note: '${signals.focusHours}/15h de foco • ${signals.objectivesCompleted}/2 objetivos • ${signals.projectTasksCompleted}/12 tarefas de projeto',
        );
      case 'faith_purpose':
        return _ComputedCampaignProgress(
          progress: _average([
            _ratio(signals.checkIns, 20),
            _ratio(signals.bestStreak, 14),
            _ratio(signals.faithXp, 160),
            _ratio(signals.habitRewards, 18),
          ]),
          note: '${signals.checkIns}/20 check-ins • sequência ${signals.bestStreak}/14 • ${signals.faithXp}/160 XP em Fé',
        );
      case 'projects_finance':
        return _ComputedCampaignProgress(
          progress: _average([
            _ratio(signals.projectTasksCompleted, 20),
            _ratio(signals.projectsCompleted, 1),
            _ratio(signals.vaultSaved, 100),
            _ratio(signals.vaultDeposits, 3),
            _ratio(signals.responsibilityXp, 160),
          ]),
          note: '${signals.projectTasksCompleted}/20 tarefas • ${signals.projectsCompleted}/1 projeto • R\$ ${signals.vaultSaved}/100 guardados',
        );
      case 'campaign_consolidation':
        return _ComputedCampaignProgress(
          progress: _average([
            _ratio(signals.achievementsUnlocked, 12),
            _ratio(signals.totalAttributeXp, 700),
            _ratio(signals.missionsCompleted, 40),
            _ratio(signals.habitRewards, 30),
            _ratio(signals.focusMinutes, 1800),
          ]),
          note: '${signals.achievementsUnlocked}/12 conquistas • ${signals.totalAttributeXp}/700 XP de atributos • ${signals.focusHours}/30h de foco',
        );
      default:
        return const _ComputedCampaignProgress(progress: 0, note: 'Capítulo sem automação vinculada.');
    }
  }

  String _areaLabel(String areaId) {
    return switch (areaId) {
      'body_health' => 'Corpo e Saúde',
      'mind_knowledge' => 'Mente e Conhecimento',
      'spirit_purpose' => 'Fé e Propósito',
      'projects_career' => 'Carreira e Projetos',
      'creation_expression' => 'Criação e Expressão',
      'finance_responsibility' => 'Finanças e Reino',
      'routine_order' => 'Rotina e Ordem',
      _ => 'Área não definida',
    };
  }

  Future<void> _ensureDefaultCampaign(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'campaigns',
      {
        'id': 'transformation_20_25',
        'title': 'Transformação dos 20 aos 25',
        'description': 'Campanha principal de evolução pessoal com foco em corpo, mente, fé, finanças, programação e projetos.',
        'lore': 'Uma jornada de cinco anos para sair do automático e construir uma vida mais forte, lúcida e responsável.',
        'main_goal': 'Chegar aos 25 anos com saúde melhor, disciplina real, carreira/projetos encaminhados, fé fortalecida e vida financeira mais madura.',
        'start_date': '2026-07-13',
        'end_date': '2031-07-13',
        'difficulty_mode': 'normal',
        'victory_minimum_percent': 60,
        'victory_good_percent': 75,
        'victory_excellent_percent': 90,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  String? _nullable(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String _readString(Map<String, Object?>? map, String key, {String fallback = ''}) {
    if (map == null) return fallback;
    final value = map[key];
    final text = value?.toString();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }

  int _readInt(Map<String, Object?>? map, String key, {int fallback = 0}) {
    if (map == null) return fallback;
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class _ComputedCampaignProgress {
  const _ComputedCampaignProgress({required this.progress, required this.note});

  final double progress;
  final String note;
}

double _ratio(num value, num target) {
  if (target <= 0) return 0;
  final result = value / target;
  if (result < 0) return 0;
  if (result > 1) return 1;
  return result.toDouble();
}

double _average(List<double> values) {
  if (values.isEmpty) return 0;
  final total = values.fold<double>(0, (sum, value) => sum + value.clamp(0.0, 1.0).toDouble());
  return (total / values.length).clamp(0.0, 1.0).toDouble();
}
