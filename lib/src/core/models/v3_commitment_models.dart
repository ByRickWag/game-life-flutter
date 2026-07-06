import 'game_models.dart';

class DifficultyProfile {
  const DifficultyProfile({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.penaltyPercent,
    required this.allowCustomRewards,
    required this.isActive,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final int penaltyPercent;
  final bool allowCustomRewards;
  final bool isActive;

  factory DifficultyProfile.fromMap(Map<String, Object?> map) {
    return DifficultyProfile(
      id: readString(map, 'id'),
      code: readString(map, 'code'),
      name: readString(map, 'name'),
      description: readString(map, 'description'),
      penaltyPercent: readInt(map, 'penalty_percent'),
      allowCustomRewards: readInt(map, 'allow_custom_rewards') == 1,
      isActive: readInt(map, 'is_active') == 1,
    );
  }
}

class CampaignMilestone {
  const CampaignMilestone({
    required this.id,
    required this.campaignId,
    required this.title,
    required this.description,
    required this.lore,
    required this.targetDate,
    required this.startDate,
    required this.endDate,
    required this.primaryAreaId,
    required this.secondaryAreaIds,
    required this.chapterKind,
    required this.sortOrder,
    required this.status,
    required this.progress,
    required this.xpReward,
    required this.coinsReward,
    required this.completedAt,
    required this.automationKey,
    required this.autoProgressEnabled,
    required this.progressNote,
  });

  final String id;
  final String campaignId;
  final String title;
  final String description;
  final String lore;
  final String targetDate;
  final String startDate;
  final String endDate;
  final String primaryAreaId;
  final String secondaryAreaIds;
  final String chapterKind;
  final int sortOrder;
  final String status;
  final double progress;
  final int xpReward;
  final int coinsReward;
  final String completedAt;
  final String automationKey;
  final bool autoProgressEnabled;
  final String progressNote;

  factory CampaignMilestone.fromMap(Map<String, Object?> map) {
    return CampaignMilestone(
      id: readString(map, 'id'),
      campaignId: readString(map, 'campaign_id'),
      title: readString(map, 'title'),
      description: readString(map, 'description'),
      lore: readString(map, 'lore'),
      targetDate: readString(map, 'target_date'),
      startDate: readString(map, 'start_date'),
      endDate: readString(map, 'end_date'),
      primaryAreaId: readString(map, 'primary_area_id'),
      secondaryAreaIds: readString(map, 'secondary_area_ids'),
      chapterKind: readString(map, 'chapter_kind', fallback: 'chapter'),
      sortOrder: readInt(map, 'sort_order'),
      status: readString(map, 'status', fallback: 'active'),
      progress: readDouble(map, 'progress'),
      xpReward: readInt(map, 'xp_reward'),
      coinsReward: readInt(map, 'coins_reward'),
      completedAt: readString(map, 'completed_at'),
      automationKey: readString(map, 'automation_key'),
      autoProgressEnabled: map.containsKey('auto_progress_enabled') ? readInt(map, 'auto_progress_enabled') == 1 : true,
      progressNote: readString(map, 'progress_note'),
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isChapter => chapterKind == 'chapter';

  List<String> get secondaryAreaIdList {
    return secondaryAreaIds
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

class CheckInSummary {
  const CheckInSummary({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCheckIns,
    required this.lastCheckInDate,
    required this.canCheckInToday,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalCheckIns;
  final String lastCheckInDate;
  final bool canCheckInToday;

  factory CheckInSummary.empty({bool canCheckInToday = true}) {
    return CheckInSummary(
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 0,
      lastCheckInDate: '',
      canCheckInToday: canCheckInToday,
    );
  }
}

class DailyCheckIn {
  const DailyCheckIn({
    required this.id,
    required this.checkInDate,
    required this.streakCount,
    required this.coinsGained,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String checkInDate;
  final int streakCount;
  final int coinsGained;
  final String notes;
  final String createdAt;

  factory DailyCheckIn.fromMap(Map<String, Object?> map) {
    return DailyCheckIn(
      id: readString(map, 'id'),
      checkInDate: readString(map, 'checkin_date'),
      streakCount: readInt(map, 'streak_count'),
      coinsGained: readInt(map, 'coins_gained'),
      notes: readString(map, 'notes'),
      createdAt: readString(map, 'created_at'),
    );
  }
}

class GameAchievement {
  const GameAchievement({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.targetValue,
    required this.xpReward,
    required this.coinsReward,
    required this.isActive,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final String icon;
  final String category;
  final int targetValue;
  final int xpReward;
  final int coinsReward;
  final bool isActive;

  factory GameAchievement.fromMap(Map<String, Object?> map) {
    return GameAchievement(
      id: readString(map, 'id'),
      code: readString(map, 'code'),
      title: readString(map, 'title'),
      description: readString(map, 'description'),
      icon: readString(map, 'icon', fallback: 'emoji_events'),
      category: readString(map, 'category', fallback: 'general'),
      targetValue: readInt(map, 'target_value'),
      xpReward: readInt(map, 'xp_reward'),
      coinsReward: readInt(map, 'coins_reward'),
      isActive: readInt(map, 'is_active') == 1,
    );
  }
}

class HeroAchievementProgress {
  const HeroAchievementProgress({
    required this.id,
    required this.achievementId,
    required this.progressValue,
    required this.isUnlocked,
    required this.unlockedAt,
    required this.achievement,
  });

  final String id;
  final String achievementId;
  final int progressValue;
  final bool isUnlocked;
  final String unlockedAt;
  final GameAchievement achievement;

  factory HeroAchievementProgress.fromMap(Map<String, Object?> map) {
    return HeroAchievementProgress(
      id: readString(map, 'hero_achievement_id'),
      achievementId: readString(map, 'achievement_id'),
      progressValue: readInt(map, 'progress_value'),
      isUnlocked: readInt(map, 'is_unlocked') == 1,
      unlockedAt: readString(map, 'unlocked_at'),
      achievement: GameAchievement.fromMap(map),
    );
  }
}

class MissionTask {
  const MissionTask({
    required this.id,
    required this.missionId,
    required this.title,
    required this.notes,
    required this.isDone,
    required this.sortOrder,
  });

  final String id;
  final String missionId;
  final String title;
  final String notes;
  final bool isDone;
  final int sortOrder;

  factory MissionTask.fromMap(Map<String, Object?> map) {
    return MissionTask(
      id: readString(map, 'id'),
      missionId: readString(map, 'mission_id'),
      title: readString(map, 'title'),
      notes: readString(map, 'notes'),
      isDone: readInt(map, 'is_done') == 1,
      sortOrder: readInt(map, 'sort_order'),
    );
  }
}

class ItemAttributeLink {
  const ItemAttributeLink({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.attributeId,
    required this.attributeName,
    required this.weight,
    required this.isPrimary,
  });

  final String id;
  final String itemType;
  final String itemId;
  final String attributeId;
  final String attributeName;
  final int weight;
  final bool isPrimary;

  factory ItemAttributeLink.fromMap(Map<String, Object?> map) {
    return ItemAttributeLink(
      id: readString(map, 'id'),
      itemType: readString(map, 'item_type'),
      itemId: readString(map, 'item_id'),
      attributeId: readString(map, 'attribute_id'),
      attributeName: readString(map, 'attribute_name', fallback: 'Atributo'),
      weight: readInt(map, 'weight'),
      isPrimary: readInt(map, 'is_primary') == 1,
    );
  }
}

class ReminderConfig {
  const ReminderConfig({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.title,
    required this.body,
    required this.reminderType,
    required this.timeOfDay,
    required this.scheduledDate,
    required this.isEnabled,
  });

  final String id;
  final String itemType;
  final String itemId;
  final String title;
  final String body;
  final String reminderType;
  final String timeOfDay;
  final String scheduledDate;
  final bool isEnabled;

  factory ReminderConfig.fromMap(Map<String, Object?> map) {
    return ReminderConfig(
      id: readString(map, 'id'),
      itemType: readString(map, 'item_type'),
      itemId: readString(map, 'item_id'),
      title: readString(map, 'title'),
      body: readString(map, 'body'),
      reminderType: readString(map, 'reminder_type', fallback: 'general'),
      timeOfDay: readString(map, 'time_of_day'),
      scheduledDate: readString(map, 'scheduled_date'),
      isEnabled: readInt(map, 'is_enabled') == 1,
    );
  }
}

class SessionTimerDraft {
  const SessionTimerDraft({
    required this.id,
    required this.title,
    required this.sessionType,
    required this.areaId,
    required this.status,
    required this.elapsedSeconds,
  });

  final String id;
  final String title;
  final String sessionType;
  final String areaId;
  final String status;
  final int elapsedSeconds;

  factory SessionTimerDraft.fromMap(Map<String, Object?> map) {
    return SessionTimerDraft(
      id: readString(map, 'id'),
      title: readString(map, 'title'),
      sessionType: readString(map, 'session_type', fallback: 'general'),
      areaId: readString(map, 'area_id'),
      status: readString(map, 'status', fallback: 'idle'),
      elapsedSeconds: readInt(map, 'elapsed_seconds'),
    );
  }
}
