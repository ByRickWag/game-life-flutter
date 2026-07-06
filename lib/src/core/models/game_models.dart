class GameArea {
  const GameArea({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String description;
  final String color;
  final String icon;
  final int sortOrder;

  factory GameArea.fromMap(Map<String, Object?> map) {
    return GameArea(
      id: readString(map, 'id'),
      name: readString(map, 'name'),
      description: readString(map, 'description'),
      color: readString(map, 'color'),
      icon: readString(map, 'icon'),
      sortOrder: readInt(map, 'sort_order'),
    );
  }
}

class GameAttribute {
  const GameAttribute({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final int sortOrder;

  factory GameAttribute.fromMap(Map<String, Object?> map) {
    return GameAttribute(
      id: readString(map, 'id'),
      name: readString(map, 'name'),
      description: readString(map, 'description'),
      icon: readString(map, 'icon'),
      sortOrder: readInt(map, 'sort_order'),
    );
  }
}

class HeroProfile {
  const HeroProfile({
    required this.id,
    required this.name,
    required this.level,
    required this.xp,
    required this.coins,
    required this.title,
  });

  final String id;
  final String name;
  final int level;
  final int xp;
  final int coins;
  final String title;

  factory HeroProfile.fromMap(Map<String, Object?> map) {
    return HeroProfile(
      id: readString(map, 'id'),
      name: readString(map, 'name'),
      level: readInt(map, 'level'),
      xp: readInt(map, 'xp'),
      coins: readInt(map, 'coins'),
      title: readString(map, 'title'),
    );
  }
}

class Campaign {
  const Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
  });

  final String id;
  final String title;
  final String description;
  final bool isActive;

  factory Campaign.fromMap(Map<String, Object?> map) {
    return Campaign(
      id: readString(map, 'id'),
      title: readString(map, 'title'),
      description: readString(map, 'description'),
      isActive: readInt(map, 'is_active') == 1,
    );
  }
}

class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.areaId,
    required this.areaName,
    required this.attributeId,
    required this.attributeName,
    required this.xpReward,
    required this.coinsReward,
    required this.isActive,
    required this.isCompound,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final String difficulty;
  final String? areaId;
  final String areaName;
  final String? attributeId;
  final String attributeName;
  final int xpReward;
  final int coinsReward;
  final bool isActive;
  final bool isCompound;
  final String status;
  final String notes;
  final String createdAt;

  factory Mission.fromMap(Map<String, Object?> map) {
    return Mission(
      id: readString(map, 'id'),
      title: readString(map, 'title'),
      description: readString(map, 'description'),
      type: readString(map, 'type'),
      difficulty: readString(map, 'difficulty'),
      areaId: readNullableString(map, 'area_id'),
      areaName: readString(map, 'area_name', fallback: 'Sem área'),
      attributeId: readNullableString(map, 'attribute_id'),
      attributeName: readString(map, 'attribute_name', fallback: 'Sem atributo'),
      xpReward: readInt(map, 'xp_reward'),
      coinsReward: readInt(map, 'coins_reward'),
      isActive: readInt(map, 'is_active') == 1,
      isCompound: readInt(map, 'is_compound') == 1,
      status: readString(map, 'status', fallback: 'active'),
      notes: readString(map, 'notes'),
      createdAt: readString(map, 'created_at'),
    );
  }

  String get typeLabel {
    return switch (type) {
      'daily' => 'Diária',
      'weekly' => 'Semanal',
      'monthly' => 'Mensal',
      'special' => 'Especial',
      _ => type,
    };
  }

  String get difficultyLabel {
    return switch (difficulty) {
      'easy' => 'Fácil',
      'normal' => 'Normal',
      'medium' => 'Médio',
      'hard' => 'Difícil',
      'very_hard' => 'Muito difícil',
      _ => difficulty,
    };
  }
}

class Objective {
  const Objective({
    required this.id,
    required this.title,
    required this.description,
    required this.areaId,
    required this.areaName,
    required this.attributeId,
    required this.attributeName,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.xpReward,
    required this.coinsReward,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String? areaId;
  final String areaName;
  final String? attributeId;
  final String attributeName;
  final double targetValue;
  final double currentValue;
  final String unit;
  final int xpReward;
  final int coinsReward;
  final String status;
  final String createdAt;

  factory Objective.fromMap(Map<String, Object?> map) {
    return Objective(
      id: readString(map, 'id'),
      title: readString(map, 'title'),
      description: readString(map, 'description'),
      areaId: readNullableString(map, 'area_id'),
      areaName: readString(map, 'area_name', fallback: 'Sem área'),
      attributeId: readNullableString(map, 'attribute_id'),
      attributeName: readString(map, 'attribute_name', fallback: 'Sem atributo'),
      targetValue: readDouble(map, 'target_value'),
      currentValue: readDouble(map, 'current_value'),
      unit: readString(map, 'unit'),
      xpReward: readInt(map, 'xp_reward'),
      coinsReward: readInt(map, 'coins_reward'),
      status: readString(map, 'status', fallback: 'active'),
      createdAt: readString(map, 'created_at'),
    );
  }

  double get safeTargetValue {
    if (targetValue <= 0) return 1;
    return targetValue;
  }

  double get progressPercent {
    final progress = currentValue / safeTargetValue;
    if (progress < 0) return 0;
    if (progress > 1) return 1;
    return progress;
  }

  bool get isCompleted => status == 'completed' || currentValue >= targetValue;

  String get progressText {
    return '${formatNumber(currentValue)} / ${formatNumber(targetValue)} $unit';
  }
}


class ManualSession {
  const ManualSession({
    required this.id,
    required this.title,
    required this.sessionType,
    required this.areaId,
    required this.areaName,
    required this.attributeId,
    required this.attributeName,
    required this.durationMinutes,
    required this.notes,
    required this.xpGained,
    required this.coinsGained,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String sessionType;
  final String? areaId;
  final String areaName;
  final String? attributeId;
  final String attributeName;
  final int durationMinutes;
  final String notes;
  final int xpGained;
  final int coinsGained;
  final String createdAt;

  factory ManualSession.fromMap(Map<String, Object?> map) {
    return ManualSession(
      id: readString(map, 'id'),
      title: readString(map, 'title'),
      sessionType: readString(map, 'session_type', fallback: 'general'),
      areaId: readNullableString(map, 'area_id'),
      areaName: readString(map, 'area_name', fallback: 'Sem área'),
      attributeId: readNullableString(map, 'attribute_id'),
      attributeName: readString(map, 'attribute_name', fallback: 'Sem atributo'),
      durationMinutes: readInt(map, 'duration_minutes'),
      notes: readString(map, 'notes'),
      xpGained: readInt(map, 'xp_gained'),
      coinsGained: readInt(map, 'coins_gained'),
      createdAt: readString(map, 'created_at'),
    );
  }

  String get typeLabel {
    return switch (sessionType) {
      'training' => 'Treino',
      'study' => 'Estudo',
      'devotional' => 'Devocional',
      'programming' => 'Programação',
      'project' => 'Projeto',
      'organization' => 'Organização',
      'reading' => 'Leitura',
      'finance' => 'Finanças',
      _ => 'Geral',
    };
  }

  String get durationText {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours <= 0) return '${durationMinutes}min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }
}


class Project {
  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.areaId,
    required this.areaName,
    required this.attributeId,
    required this.attributeName,
    required this.difficulty,
    required this.status,
    required this.progress,
    required this.xpReward,
    required this.coinsReward,
    required this.milestoneCount,
    required this.doneMilestoneCount,
    required this.taskCount,
    required this.doneTaskCount,
    required this.taskXpTotal,
    required this.taskXpApplied,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final String? areaId;
  final String areaName;
  final String? attributeId;
  final String attributeName;
  final String difficulty;
  final String status;
  final double progress;
  final int xpReward;
  final int coinsReward;
  final int milestoneCount;
  final int doneMilestoneCount;
  final int taskCount;
  final int doneTaskCount;
  final int taskXpTotal;
  final int taskXpApplied;
  final String createdAt;
  final String updatedAt;
  final String completedAt;

  factory Project.fromMap(Map<String, Object?> map) {
    return Project(
      id: readString(map, 'id'),
      title: readString(map, 'title'),
      description: readString(map, 'description'),
      areaId: readNullableString(map, 'area_id'),
      areaName: readString(map, 'area_name', fallback: 'Sem área'),
      attributeId: readNullableString(map, 'attribute_id'),
      attributeName: readString(map, 'attribute_name', fallback: 'Sem atributo'),
      difficulty: readString(map, 'difficulty', fallback: 'normal'),
      status: readString(map, 'status', fallback: 'active'),
      progress: readDouble(map, 'progress'),
      xpReward: readInt(map, 'xp_reward'),
      coinsReward: readInt(map, 'coins_reward'),
      milestoneCount: readInt(map, 'milestone_count'),
      doneMilestoneCount: readInt(map, 'done_milestone_count'),
      taskCount: readInt(map, 'task_count'),
      doneTaskCount: readInt(map, 'done_task_count'),
      taskXpTotal: readInt(map, 'task_xp_total'),
      taskXpApplied: readInt(map, 'task_xp_applied'),
      createdAt: readString(map, 'created_at'),
      updatedAt: readString(map, 'updated_at'),
      completedAt: readString(map, 'completed_at'),
    );
  }

  double get safeProgress {
    if (progress < 0) return 0;
    if (progress > 100) return 100;
    return progress;
  }

  double get progressPercent => safeProgress / 100;

  bool get isCompleted => status == 'completed';
  bool get isReadyForCompletion => taskCount > 0 && doneTaskCount >= taskCount;

  String get progressText => '${formatNumber(safeProgress)}%';

  String get statusLabel {
    return switch (status) {
      'active' => 'Ativo',
      'paused' => 'Pausado',
      'completed' => 'Concluído',
      'archived' => 'Arquivado',
      _ => status,
    };
  }

  String get difficultyLabel {
    return switch (difficulty) {
      'easy' => 'Fácil',
      'normal' => 'Normal',
      'medium' => 'Médio',
      'hard' => 'Difícil',
      'very_hard' => 'Muito difícil',
      _ => difficulty,
    };
  }
}

class ProjectMilestone {
  const ProjectMilestone({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.sortOrder,
    required this.taskCount,
    required this.doneTaskCount,
    required this.taskXpTotal,
    required this.taskXpApplied,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final String status;
  final int sortOrder;
  final int taskCount;
  final int doneTaskCount;
  final int taskXpTotal;
  final int taskXpApplied;
  final String completedAt;
  final String createdAt;
  final String updatedAt;

  factory ProjectMilestone.fromMap(Map<String, Object?> map) {
    return ProjectMilestone(
      id: readString(map, 'id'),
      projectId: readString(map, 'project_id'),
      title: readString(map, 'title'),
      description: readString(map, 'description'),
      status: readString(map, 'status', fallback: 'active'),
      sortOrder: readInt(map, 'sort_order'),
      taskCount: readInt(map, 'task_count'),
      doneTaskCount: readInt(map, 'done_task_count'),
      taskXpTotal: readInt(map, 'task_xp_total'),
      taskXpApplied: readInt(map, 'task_xp_applied'),
      completedAt: readString(map, 'completed_at'),
      createdAt: readString(map, 'created_at'),
      updatedAt: readString(map, 'updated_at'),
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isReadyForCompletion => taskCount > 0 && doneTaskCount >= taskCount;

  double get progressPercent {
    if (taskCount <= 0) return 0;
    final value = doneTaskCount / taskCount;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  String get progressText => '${(progressPercent * 100).round()}%';
}

class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.milestoneId,
    required this.milestoneTitle,
    required this.title,
    required this.notes,
    required this.xpReward,
    required this.xpApplied,
    required this.isDone,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String projectId;
  final String? milestoneId;
  final String milestoneTitle;
  final String title;
  final String notes;
  final int xpReward;
  final bool xpApplied;
  final bool isDone;
  final String completedAt;
  final String createdAt;
  final String updatedAt;

  factory ProjectTask.fromMap(Map<String, Object?> map) {
    return ProjectTask(
      id: readString(map, 'id'),
      projectId: readString(map, 'project_id'),
      milestoneId: readNullableString(map, 'milestone_id'),
      milestoneTitle: readString(map, 'milestone_title', fallback: 'Sem marco'),
      title: readString(map, 'title'),
      notes: readString(map, 'notes'),
      xpReward: readInt(map, 'xp_reward') <= 0 ? 5 : readInt(map, 'xp_reward'),
      xpApplied: readInt(map, 'xp_applied') == 1,
      isDone: readInt(map, 'is_done') == 1,
      completedAt: readString(map, 'completed_at'),
      createdAt: readString(map, 'created_at'),
      updatedAt: readString(map, 'updated_at'),
    );
  }
}


class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.frequency,
    required this.unit,
    required this.targetValue,
    required this.limitValue,
    required this.areaId,
    required this.areaName,
    required this.attributeId,
    required this.attributeName,
    required this.xpReward,
    required this.coinsReward,
    required this.healthKind,
    required this.healthCategory,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final String frequency;
  final String unit;
  final double targetValue;
  final double limitValue;
  final String? areaId;
  final String areaName;
  final String? attributeId;
  final String attributeName;
  final int xpReward;
  final int coinsReward;
  final String healthKind;
  final String healthCategory;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  factory Habit.fromMap(Map<String, Object?> map) {
    return Habit(
      id: readString(map, 'id'),
      title: readString(map, 'title', fallback: 'Hábito'),
      description: readString(map, 'description'),
      type: readString(map, 'type', fallback: 'build'),
      frequency: readString(map, 'frequency', fallback: 'daily'),
      unit: readString(map, 'unit', fallback: 'check'),
      targetValue: readDouble(map, 'target_value') <= 0 ? 1 : readDouble(map, 'target_value'),
      limitValue: readDouble(map, 'limit_value'),
      areaId: readNullableString(map, 'area_id'),
      areaName: readString(map, 'area_name', fallback: 'Sem área'),
      attributeId: readNullableString(map, 'attribute_id'),
      attributeName: readString(map, 'attribute_name', fallback: 'Sem atributo'),
      xpReward: readInt(map, 'xp_reward'),
      coinsReward: readInt(map, 'coins_reward'),
      healthKind: readString(map, 'health_kind'),
      healthCategory: readString(map, 'health_category'),
      isActive: readInt(map, 'is_active') == 1,
      createdAt: readString(map, 'created_at'),
      updatedAt: readString(map, 'updated_at'),
    );
  }

  bool get isReduction => type == 'reduce' || type == 'avoid';
  bool get isBuildStyle => !isReduction;
  bool get isHealthTracked => healthKind.isNotEmpty;
  bool get isWaterTracked => healthKind == 'water';
  bool get isFoodLimitTracked => healthKind == 'food_limit';

  double get effectiveGoal => isReduction ? limitValue : targetValue;

  String get typeLabel {
    return switch (type) {
      'build' => 'Construir',
      'maintain' => 'Manter',
      'reduce' => 'Reduzir',
      'avoid' => 'Evitar',
      _ => type,
    };
  }

  String get frequencyLabel {
    return switch (frequency) {
      'weekly' => 'Semanal',
      'daily' => 'Diário',
      _ => frequency,
    };
  }

  String get unitLabel {
    return switch (unit) {
      'check' => 'check',
      'times' => 'vezes',
      'ml' => 'ml',
      'minutes' => 'minutos',
      'pages' => 'páginas',
      'reps' => 'repetições',
      _ => unit,
    };
  }

  String get healthCategoryLabel {
    return switch (healthCategory) {
      'water' => 'Água',
      'soda' => 'Refrigerante',
      'ultra_processed' => 'Doces e ultraprocessados',
      'fast_food' => 'Salgados e fast-food',
      _ => healthCategory.isEmpty ? 'Saúde' : healthCategory,
    };
  }

  String get healthKindLabel {
    return switch (healthKind) {
      'water' => 'Hidratação',
      'food_limit' => 'Alimentação',
      _ => healthKind.isEmpty ? 'Geral' : healthKind,
    };
  }

  String get goalText {
    final value = formatNumber(effectiveGoal);
    if (isReduction) {
      if (limitValue <= 0) return 'evitar no período';
      return 'limite: $value $unitLabel';
    }
    return 'meta: $value $unitLabel';
  }
}

class HabitPeriodStats {
  const HabitPeriodStats({
    required this.habitId,
    required this.totalLogged,
    required this.logCount,
    required this.periodStart,
    required this.periodEnd,
    required this.rewarded,
    required this.xpGained,
    required this.coinsGained,
  });

  final String habitId;
  final double totalLogged;
  final int logCount;
  final String periodStart;
  final String periodEnd;
  final bool rewarded;
  final int xpGained;
  final int coinsGained;

  factory HabitPeriodStats.fromMap(Map<String, Object?> map) {
    return HabitPeriodStats(
      habitId: readString(map, 'habit_id'),
      totalLogged: readDouble(map, 'total_logged'),
      logCount: readInt(map, 'log_count'),
      periodStart: readString(map, 'period_start'),
      periodEnd: readString(map, 'period_end'),
      rewarded: readInt(map, 'rewarded') == 1,
      xpGained: readInt(map, 'xp_gained'),
      coinsGained: readInt(map, 'coins_gained'),
    );
  }

  factory HabitPeriodStats.empty({
    required String habitId,
    required String periodStart,
    required String periodEnd,
  }) {
    return HabitPeriodStats(
      habitId: habitId,
      totalLogged: 0,
      logCount: 0,
      periodStart: periodStart,
      periodEnd: periodEnd,
      rewarded: false,
      xpGained: 0,
      coinsGained: 0,
    );
  }

  double progressFor(Habit habit) {
    if (habit.isReduction) {
      if (habit.limitValue <= 0) return totalLogged <= 0 ? 1 : 0;
      final remaining = (habit.limitValue - totalLogged).clamp(0, habit.limitValue).toDouble();
      return remaining / habit.limitValue;
    }

    final target = habit.targetValue <= 0 ? 1 : habit.targetValue;
    return (totalLogged / target).clamp(0, 1).toDouble();
  }

  bool isSuccessFor(Habit habit) {
    if (habit.isReduction) return totalLogged <= habit.limitValue;
    return totalLogged >= habit.targetValue;
  }

  String valueTextFor(Habit habit) {
    final total = formatNumber(totalLogged);
    final goal = formatNumber(habit.effectiveGoal);
    if (habit.isReduction) return '$total/$goal ${habit.unitLabel} usados';
    return '$total/$goal ${habit.unitLabel}';
  }

  String statusTextFor(Habit habit) {
    if (rewarded) return 'Recompensa recebida';
    if (habit.isReduction) {
      if (isSuccessFor(habit)) return 'Dentro do plano';
      return 'Limite estourado';
    }
    if (isSuccessFor(habit)) return 'Meta alcançada';
    return 'Em andamento';
  }
}

class HabitLogEntry {
  const HabitLogEntry({
    required this.id,
    required this.habitId,
    required this.value,
    required this.note,
    required this.loggedFor,
    required this.createdAt,
  });

  final String id;
  final String habitId;
  final double value;
  final String note;
  final String loggedFor;
  final String createdAt;

  factory HabitLogEntry.fromMap(Map<String, Object?> map) {
    return HabitLogEntry(
      id: readString(map, 'id'),
      habitId: readString(map, 'habit_id'),
      value: readDouble(map, 'value'),
      note: readString(map, 'note'),
      loggedFor: readString(map, 'logged_for'),
      createdAt: readString(map, 'created_at'),
    );
  }
}

class HabitWithStats {
  const HabitWithStats({required this.habit, required this.stats});

  final Habit habit;
  final HabitPeriodStats stats;
}

class Vault {
  const Vault({
    required this.id,
    required this.name,
    required this.description,
    required this.goalAmount,
    required this.icon,
    required this.color,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  final String id;
  final String name;
  final String description;
  final double goalAmount;
  final String icon;
  final String color;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String archivedAt;

  factory Vault.fromMap(Map<String, Object?> map) {
    return Vault(
      id: readString(map, 'id'),
      name: readString(map, 'name', fallback: 'Cofre'),
      description: readString(map, 'description'),
      goalAmount: readDouble(map, 'goal_amount'),
      icon: readString(map, 'icon', fallback: 'savings'),
      color: readString(map, 'color', fallback: 'amber'),
      status: readString(map, 'status', fallback: 'active'),
      createdAt: readString(map, 'created_at'),
      updatedAt: readString(map, 'updated_at'),
      archivedAt: readString(map, 'archived_at'),
    );
  }

  bool get isActive => status == 'active';
  bool get hasGoal => goalAmount > 0;

  String get goalText {
    if (!hasGoal) return 'sem meta definida';
    return 'meta: ${formatCurrency(goalAmount)}';
  }
}

class VaultSummary {
  const VaultSummary({
    required this.balance,
    required this.depositsTotal,
    required this.withdrawalsTotal,
    required this.entriesCount,
    required this.lastEntryAt,
  });

  final double balance;
  final double depositsTotal;
  final double withdrawalsTotal;
  final int entriesCount;
  final String lastEntryAt;

  factory VaultSummary.fromMap(Map<String, Object?> map) {
    return VaultSummary(
      balance: readDouble(map, 'balance'),
      depositsTotal: readDouble(map, 'deposits_total'),
      withdrawalsTotal: readDouble(map, 'withdrawals_total'),
      entriesCount: readInt(map, 'entries_count'),
      lastEntryAt: readString(map, 'last_entry_at'),
    );
  }

  static const empty = VaultSummary(
    balance: 0,
    depositsTotal: 0,
    withdrawalsTotal: 0,
    entriesCount: 0,
    lastEntryAt: '',
  );
}

class VaultWithSummary {
  const VaultWithSummary({required this.vault, required this.summary});

  final Vault vault;
  final VaultSummary summary;

  double get progress {
    if (vault.goalAmount <= 0) return 0;
    return (summary.balance / vault.goalAmount).clamp(0, 1).toDouble();
  }

  double get remainingAmount {
    final remaining = vault.goalAmount - summary.balance;
    if (remaining < 0) return 0;
    return remaining;
  }

  String get progressLabel {
    if (!vault.hasGoal) return 'Saldo atual: ${formatCurrency(summary.balance)}';
    return '${formatCurrency(summary.balance)} de ${formatCurrency(vault.goalAmount)}';
  }
}

class VaultEntry {
  const VaultEntry({
    required this.id,
    required this.vaultId,
    required this.type,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String vaultId;
  final String type;
  final double amount;
  final String note;
  final String createdAt;

  factory VaultEntry.fromMap(Map<String, Object?> map) {
    return VaultEntry(
      id: readString(map, 'id'),
      vaultId: readString(map, 'vault_id'),
      type: readString(map, 'type', fallback: 'deposit'),
      amount: readDouble(map, 'amount'),
      note: readString(map, 'note'),
      createdAt: readString(map, 'created_at'),
    );
  }

  bool get isDeposit => type == 'deposit';

  String get typeLabel => isDeposit ? 'Depósito' : 'Retirada';
  String get signedAmountText => '${isDeposit ? '+' : '-'} ${formatCurrency(amount)}';
}

class VaultOverview {
  const VaultOverview({
    required this.activeVaults,
    required this.totalBalance,
    required this.totalGoals,
    required this.totalDeposits,
    required this.totalWithdrawals,
  });

  final int activeVaults;
  final double totalBalance;
  final double totalGoals;
  final double totalDeposits;
  final double totalWithdrawals;

  factory VaultOverview.fromMap(Map<String, Object?> map) {
    return VaultOverview(
      activeVaults: readInt(map, 'active_vaults'),
      totalBalance: readDouble(map, 'total_balance'),
      totalGoals: readDouble(map, 'total_goals'),
      totalDeposits: readDouble(map, 'total_deposits'),
      totalWithdrawals: readDouble(map, 'total_withdrawals'),
    );
  }

  static const empty = VaultOverview(
    activeVaults: 0,
    totalBalance: 0,
    totalGoals: 0,
    totalDeposits: 0,
    totalWithdrawals: 0,
  );

  double get progress {
    if (totalGoals <= 0) return 0;
    return (totalBalance / totalGoals).clamp(0, 1).toDouble();
  }
}


class AreaEvolution {
  const AreaEvolution({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.sortOrder,
    required this.points,
    required this.xp,
    required this.linkedAttributes,
  });

  final String id;
  final String name;
  final String description;
  final String color;
  final String icon;
  final int sortOrder;
  final int points;
  final int xp;
  final String linkedAttributes;

  factory AreaEvolution.fromMap(Map<String, Object?> map) {
    return AreaEvolution(
      id: readString(map, 'id'),
      name: readString(map, 'name', fallback: 'Área'),
      description: readString(map, 'description'),
      color: readString(map, 'color'),
      icon: readString(map, 'icon'),
      sortOrder: readInt(map, 'sort_order'),
      points: readInt(map, 'points'),
      xp: readInt(map, 'xp'),
      linkedAttributes: readString(map, 'linked_attributes'),
    );
  }

  int get level => points + 1;
  int get xpInsideCurrentPoint => xp % 100;

  double get progressToNextPoint {
    final value = xpInsideCurrentPoint / 100;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  String get nextPointText {
    final missing = 100 - xpInsideCurrentPoint;
    if (xp == 0) return '0/100 XP neste domínio';
    if (xpInsideCurrentPoint == 0) return 'Novo ciclo de domínio iniciado';
    return '$missing XP para fortalecer este domínio';
  }
}

String readString(
  Map<String, Object?> map,
  String key, {
  String fallback = '',
}) {
  return map[key]?.toString() ?? fallback;
}

String? readNullableString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  final text = value.toString();
  if (text.trim().isEmpty) return null;
  return text;
}

int readInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double readDouble(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse((value?.toString() ?? '').replaceAll(',', '.')) ?? 0;
}

String formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String formatCurrency(double value) {
  final sign = value < 0 ? '-' : '';
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  var integer = parts.first;
  final decimal = parts.length > 1 ? parts[1] : '00';
  final buffer = StringBuffer();

  for (var index = 0; index < integer.length; index++) {
    final remaining = integer.length - index;
    buffer.write(integer[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${sign}R\$ ${buffer.toString()},$decimal';
}


class ShopItem {
  const ShopItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.coinCost,
    required this.requiredMoneyAmount,
    required this.linkedVaultId,
    required this.linkedVaultName,
    required this.linkedVaultBalance,
    required this.icon,
    required this.color,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final int coinCost;
  final double requiredMoneyAmount;
  final String? linkedVaultId;
  final String linkedVaultName;
  final double linkedVaultBalance;
  final String icon;
  final String color;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String archivedAt;

  factory ShopItem.fromMap(Map<String, Object?> map) {
    return ShopItem(
      id: readString(map, 'id'),
      title: readString(map, 'title', fallback: 'Item da loja'),
      description: readString(map, 'description'),
      type: readString(map, 'type', fallback: 'reward'),
      coinCost: readInt(map, 'coin_cost'),
      requiredMoneyAmount: readDouble(map, 'required_money_amount'),
      linkedVaultId: readNullableString(map, 'linked_vault_id'),
      linkedVaultName: readString(map, 'linked_vault_name'),
      linkedVaultBalance: readDouble(map, 'linked_vault_balance'),
      icon: readString(map, 'icon', fallback: 'redeem'),
      color: readString(map, 'color', fallback: 'purple'),
      status: readString(map, 'status', fallback: 'active'),
      createdAt: readString(map, 'created_at'),
      updatedAt: readString(map, 'updated_at'),
      archivedAt: readString(map, 'archived_at'),
    );
  }

  bool get isActive => status == 'active';
  bool get isRealPurchase => type == 'real_purchase';
  bool get isReward => !isRealPurchase;
  bool get hasMoneyRequirement => isRealPurchase && requiredMoneyAmount > 0;
  bool get hasLinkedVault => (linkedVaultId ?? '').isNotEmpty;
  bool get moneyRequirementMet => !hasMoneyRequirement || (hasLinkedVault && linkedVaultBalance >= requiredMoneyAmount);

  String get typeLabel => isRealPurchase ? 'Compra real' : 'Recompensa';
  String get coinCostText => '$coinCost coins';

  String get moneyRequirementText {
    if (!isRealPurchase) return 'sem requisito real';
    if (requiredMoneyAmount <= 0) return 'sem valor real definido';
    final vault = linkedVaultName.isEmpty ? 'sem cofre vinculado' : linkedVaultName;
    return '${formatCurrency(linkedVaultBalance)} de ${formatCurrency(requiredMoneyAmount)} • $vault';
  }

  String buyBlockReason(int heroCoins) {
    if (heroCoins < coinCost) return 'Faltam ${coinCost - heroCoins} coins.';
    if (isRealPurchase && !hasLinkedVault && requiredMoneyAmount > 0) return 'Vincule um cofre primeiro.';
    if (isRealPurchase && !moneyRequirementMet) return 'Cofre ainda não bateu o valor real.';
    return '';
  }

  bool canBuy(int heroCoins) => buyBlockReason(heroCoins).isEmpty;
}

class ShopPurchase {
  const ShopPurchase({
    required this.id,
    required this.shopItemId,
    required this.titleSnapshot,
    required this.typeSnapshot,
    required this.coinCostPaid,
    required this.requiredMoneySnapshot,
    required this.linkedVaultId,
    required this.note,
    required this.purchasedAt,
  });

  final String id;
  final String shopItemId;
  final String titleSnapshot;
  final String typeSnapshot;
  final int coinCostPaid;
  final double requiredMoneySnapshot;
  final String? linkedVaultId;
  final String note;
  final String purchasedAt;

  factory ShopPurchase.fromMap(Map<String, Object?> map) {
    return ShopPurchase(
      id: readString(map, 'id'),
      shopItemId: readString(map, 'shop_item_id'),
      titleSnapshot: readString(map, 'title_snapshot', fallback: 'Compra'),
      typeSnapshot: readString(map, 'type_snapshot', fallback: 'reward'),
      coinCostPaid: readInt(map, 'coin_cost_paid'),
      requiredMoneySnapshot: readDouble(map, 'required_money_snapshot'),
      linkedVaultId: readNullableString(map, 'linked_vault_id'),
      note: readString(map, 'note'),
      purchasedAt: readString(map, 'purchased_at'),
    );
  }

  bool get isRealPurchase => typeSnapshot == 'real_purchase';
  String get typeLabel => isRealPurchase ? 'Compra real' : 'Recompensa';
  String get coinsText => '-$coinCostPaid coins';

  String get dateText {
    final parsed = DateTime.tryParse(purchasedAt);
    if (parsed == null) return purchasedAt;
    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month • $hour:$minute';
  }
}

class HistoryEvent {
  const HistoryEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.xpDelta,
    required this.coinsDelta,
    required this.occurredAt,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final int xpDelta;
  final int coinsDelta;
  final String occurredAt;

  factory HistoryEvent.fromMap(Map<String, Object?> map) {
    return HistoryEvent(
      id: readString(map, 'id'),
      title: readString(map, 'title', fallback: 'Evento'),
      description: readString(map, 'description'),
      type: readString(map, 'type', fallback: 'system'),
      xpDelta: readInt(map, 'xp_delta'),
      coinsDelta: readInt(map, 'coins_delta'),
      occurredAt: readString(map, 'occurred_at'),
    );
  }

  String get typeLabel {
    return switch (type) {
      'mission_completion' => 'Missão',
      'objective_completion' => 'Objetivo',
      'objective_progress' => 'Progresso',
      'habit_reward' => 'Hábito',
      'habit_created' => 'Hábito',
      'habit_updated' => 'Hábito',
      'manual_session' => 'Sessão',
      'project_completion' => 'Projeto',
      'shop_purchase' => 'Loja',
      'shop_real_purchase' => 'Loja',
      'shop_item_created' => 'Loja',
      'shop_item_updated' => 'Loja',
      'shop_item_archived' => 'Loja',
      'vault_created' => 'Cofre',
      'vault_updated' => 'Cofre',
      'vault_archived' => 'Cofre',
      'vault_deposit' => 'Cofre',
      'vault_withdraw' => 'Cofre',
      'achievement_unlocked' => 'Conquista',
      'system' => 'Sistema',
      _ => 'Evento',
    };
  }

  String get rewardText {
    final parts = <String>[];
    if (xpDelta != 0) parts.add('${xpDelta > 0 ? '+' : ''}$xpDelta XP');
    if (coinsDelta != 0) parts.add('${coinsDelta > 0 ? '+' : ''}$coinsDelta coins');
    if (parts.isEmpty) return 'Sem recompensa direta';
    return parts.join(' • ');
  }

  String get dateText {
    final parsed = DateTime.tryParse(occurredAt);
    if (parsed == null) return occurredAt;

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month • $hour:$minute';
  }
}

class HistoryStats {
  const HistoryStats({
    required this.totalEvents,
    required this.totalXp,
    required this.totalCoins,
    required this.missionEvents,
    required this.objectiveEvents,
    required this.sessionEvents,
    required this.projectEvents,
    required this.firstEventAt,
    required this.lastEventAt,
  });

  final int totalEvents;
  final int totalXp;
  final int totalCoins;
  final int missionEvents;
  final int objectiveEvents;
  final int sessionEvents;
  final int projectEvents;
  final String firstEventAt;
  final String lastEventAt;

  factory HistoryStats.empty() {
    return const HistoryStats(
      totalEvents: 0,
      totalXp: 0,
      totalCoins: 0,
      missionEvents: 0,
      objectiveEvents: 0,
      sessionEvents: 0,
      projectEvents: 0,
      firstEventAt: '',
      lastEventAt: '',
    );
  }

  factory HistoryStats.fromMap(Map<String, Object?> map) {
    return HistoryStats(
      totalEvents: readInt(map, 'total_events'),
      totalXp: readInt(map, 'total_xp'),
      totalCoins: readInt(map, 'total_coins'),
      missionEvents: readInt(map, 'mission_events'),
      objectiveEvents: readInt(map, 'objective_events'),
      sessionEvents: readInt(map, 'session_events'),
      projectEvents: readInt(map, 'project_events'),
      firstEventAt: readString(map, 'first_event_at'),
      lastEventAt: readString(map, 'last_event_at'),
    );
  }

  String get journeyPeriodText {
    final first = _formatShortDate(firstEventAt);
    final last = _formatShortDate(lastEventAt);

    if (first.isEmpty && last.isEmpty) return 'Sem eventos ainda';
    if (first == last) return first;
    return '$first até $last';
  }

  static String _formatShortDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

class AttributeEvolution {
  const AttributeEvolution({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
    required this.xp,
  });

  final String id;
  final String name;
  final String description;
  final int points;
  final int xp;

  factory AttributeEvolution.fromMap(Map<String, Object?> map) {
    return AttributeEvolution(
      id: readString(map, 'id'),
      name: readString(map, 'name', fallback: 'Atributo'),
      description: readString(map, 'description'),
      points: readInt(map, 'points'),
      xp: readInt(map, 'xp'),
    );
  }

  int get xpInsideCurrentPoint => xp % 100;

  double get progressToNextPoint {
    final value = xpInsideCurrentPoint / 100;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  String get nextPointText {
    final missing = 100 - xpInsideCurrentPoint;
    if (xpInsideCurrentPoint == 0 && xp > 0) return 'Pronto para próximo ciclo';
    return '$missing XP para +1 ponto';
  }
}
