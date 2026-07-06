import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/game_models.dart';
import '../services/reward_service.dart';
import '../services/progression_service.dart';
import '../services/area_progression_service.dart';
import '../utils/id_generator.dart';
import 'achievement_repository.dart';

class CreateProjectInput {
  const CreateProjectInput({
    required this.title,
    required this.description,
    required this.areaId,
    required this.attributeIds,
    required this.difficulty,
  });

  final String title;
  final String description;
  final String? areaId;
  final List<String> attributeIds;
  final String difficulty;

  String? get primaryAttributeId => attributeIds.isEmpty ? null : attributeIds.first;
}

class CompleteProjectResult {
  const CompleteProjectResult({
    required this.completed,
    required this.message,
    required this.xpGained,
    required this.coinsGained,
  });

  final bool completed;
  final String message;
  final int xpGained;
  final int coinsGained;
}

class ProjectTaskDraft {
  const ProjectTaskDraft({
    required this.title,
    required this.xpReward,
    this.notes = '',
  });

  final String title;
  final int xpReward;
  final String notes;
}

class ProjectRepository {
  String get _projectSelect => '''
      SELECT
        projects.*,
        areas.name AS area_name,
        attributes.name AS attribute_name,
        (SELECT COUNT(*) FROM project_milestones WHERE project_milestones.project_id = projects.id) AS milestone_count,
        (SELECT COUNT(*) FROM project_milestones WHERE project_milestones.project_id = projects.id AND project_milestones.status = 'completed') AS done_milestone_count,
        (SELECT COUNT(*) FROM project_tasks WHERE project_tasks.project_id = projects.id) AS task_count,
        (SELECT COUNT(*) FROM project_tasks WHERE project_tasks.project_id = projects.id AND project_tasks.is_done = 1) AS done_task_count,
        (SELECT COALESCE(SUM(project_tasks.xp_reward), 0) FROM project_tasks WHERE project_tasks.project_id = projects.id) AS task_xp_total,
        (SELECT COALESCE(SUM(CASE WHEN project_tasks.xp_applied = 1 THEN project_tasks.xp_reward ELSE 0 END), 0) FROM project_tasks WHERE project_tasks.project_id = projects.id) AS task_xp_applied
      FROM projects
      LEFT JOIN areas ON areas.id = projects.area_id
      LEFT JOIN attributes ON attributes.id = projects.attribute_id
  ''';

  Future<List<Project>> getVisibleProjects() async {
    final db = await AppDatabase.instance.database;
    await _ensureAllProjectsHaveMilestones(db);
    final rows = await db.rawQuery('''
      $_projectSelect
      WHERE projects.status != 'archived'
      ORDER BY
        CASE projects.status
          WHEN 'active' THEN 1
          WHEN 'paused' THEN 2
          WHEN 'completed' THEN 3
          ELSE 4
        END,
        projects.updated_at DESC;
    ''');

    return rows.map(Project.fromMap).toList();
  }

  Future<List<Project>> getActiveProjects() async {
    final db = await AppDatabase.instance.database;
    await _ensureAllProjectsHaveMilestones(db);
    final rows = await db.rawQuery('''
      $_projectSelect
      WHERE projects.status IN ('active', 'paused')
      ORDER BY
        CASE projects.status
          WHEN 'active' THEN 1
          WHEN 'paused' THEN 2
          ELSE 3
        END,
        projects.updated_at DESC;
    ''');

    return rows.map(Project.fromMap).toList();
  }

  Future<List<Project>> getCompletedProjects() async {
    final db = await AppDatabase.instance.database;
    await _ensureAllProjectsHaveMilestones(db);
    final rows = await db.rawQuery('''
      $_projectSelect
      WHERE projects.status = 'completed'
      ORDER BY projects.completed_at DESC, projects.updated_at DESC;
    ''');

    return rows.map(Project.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> getProjectTaskRows({
    String filter = 'open',
    int limit = 80,
  }) async {
    final db = await AppDatabase.instance.database;
    await _ensureAllProjectsHaveMilestones(db);
    final whereTask = switch (filter) {
      'done' => 'AND project_tasks.is_done = 1',
      'all' => '',
      _ => 'AND project_tasks.is_done = 0',
    };

    return db.rawQuery('''
      SELECT
        project_tasks.*,
        project_milestones.title AS milestone_title,
        projects.title AS project_title,
        projects.status AS project_status,
        projects.progress AS project_progress,
        projects.area_id AS project_area_id,
        projects.attribute_id AS project_attribute_id
      FROM project_tasks
      INNER JOIN projects ON projects.id = project_tasks.project_id
      LEFT JOIN project_milestones ON project_milestones.id = project_tasks.milestone_id
      WHERE projects.status IN ('active', 'paused')
      $whereTask
      ORDER BY project_tasks.is_done ASC, project_tasks.updated_at DESC, project_tasks.created_at DESC
      LIMIT ?;
    ''', [limit]);
  }

  Future<Project?> getProjectById(String projectId) async {
    final db = await AppDatabase.instance.database;
    await _ensureProjectHasMilestone(db, projectId);
    final rows = await db.rawQuery('''
      $_projectSelect
      WHERE projects.id = ?
      LIMIT 1;
    ''', [projectId]);

    if (rows.isEmpty) return null;
    return Project.fromMap(rows.first);
  }

  Future<List<ProjectMilestone>> getMilestones(String projectId) async {
    final db = await AppDatabase.instance.database;
    await _ensureProjectHasMilestone(db, projectId);
    final rows = await db.rawQuery('''
      SELECT
        project_milestones.*,
        COUNT(project_tasks.id) AS task_count,
        COALESCE(SUM(CASE WHEN project_tasks.is_done = 1 THEN 1 ELSE 0 END), 0) AS done_task_count,
        COALESCE(SUM(project_tasks.xp_reward), 0) AS task_xp_total,
        COALESCE(SUM(CASE WHEN project_tasks.xp_applied = 1 THEN project_tasks.xp_reward ELSE 0 END), 0) AS task_xp_applied
      FROM project_milestones
      LEFT JOIN project_tasks ON project_tasks.milestone_id = project_milestones.id
      WHERE project_milestones.project_id = ?
      GROUP BY project_milestones.id
      ORDER BY project_milestones.sort_order ASC, project_milestones.created_at ASC;
    ''', [projectId]);

    return rows.map(ProjectMilestone.fromMap).toList();
  }

  Future<List<ProjectTask>> getTasks(String projectId) async {
    final db = await AppDatabase.instance.database;
    await _ensureProjectHasMilestone(db, projectId);
    final rows = await db.rawQuery('''
      SELECT
        project_tasks.*,
        project_milestones.title AS milestone_title
      FROM project_tasks
      LEFT JOIN project_milestones ON project_milestones.id = project_tasks.milestone_id
      WHERE project_tasks.project_id = ?
      ORDER BY
        project_milestones.sort_order ASC,
        project_tasks.is_done ASC,
        project_tasks.created_at ASC;
    ''', [projectId]);

    return rows.map(ProjectTask.fromMap).toList();
  }

  Future<List<ProjectTask>> getTasksForMilestone(String milestoneId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        project_tasks.*,
        project_milestones.title AS milestone_title
      FROM project_tasks
      LEFT JOIN project_milestones ON project_milestones.id = project_tasks.milestone_id
      WHERE project_tasks.milestone_id = ?
      ORDER BY project_tasks.is_done ASC, project_tasks.created_at ASC;
    ''', [milestoneId]);

    return rows.map(ProjectTask.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> getAreas() async {
    final db = await AppDatabase.instance.database;
    return db.query('areas', orderBy: 'sort_order ASC');
  }

  Future<List<Map<String, Object?>>> getAttributes() async {
    final db = await AppDatabase.instance.database;
    return db.query('attributes', orderBy: 'sort_order ASC');
  }

  Future<ProjectReward> previewReward({required String difficulty}) async {
    final db = await AppDatabase.instance.database;
    return RewardService(db).calculateProjectReward(difficulty: difficulty);
  }

  Future<int> defaultTaskXp() async {
    final db = await AppDatabase.instance.database;
    return RewardService(db).projectTaskDefaultXp();
  }

  Future<int> maxTaskXp() async {
    final db = await AppDatabase.instance.database;
    return RewardService(db).projectTaskXpCap();
  }

  Future<void> createProject(CreateProjectInput input) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final projectId = IdGenerator.create('project');
    final attributeIds = _normalizeAttributeIds(input.attributeIds);
    final reward = await RewardService(db).calculateProjectReward(
      difficulty: input.difficulty,
    );

    await db.transaction((txn) async {
      await txn.insert(
        'projects',
        {
          'id': projectId,
          'title': input.title.trim(),
          'description': input.description.trim(),
          'area_id': input.areaId,
          'attribute_id': attributeIds.isEmpty ? null : attributeIds.first,
          'difficulty': input.difficulty,
          'status': 'active',
          'progress': 0.0,
          'xp_reward': reward.xp,
          'coins_reward': reward.coins,
          'created_at': now,
          'updated_at': now,
          'completed_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await txn.insert(
        'project_milestones',
        {
          'id': IdGenerator.create('project_milestone'),
          'project_id': projectId,
          'title': 'Marco inicial',
          'description': 'Primeira etapa do projeto.',
          'status': 'active',
          'sort_order': 0,
          'completed_at': null,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _replaceAttributeLinks(
        txn: txn,
        itemType: 'project',
        itemId: projectId,
        attributeIds: attributeIds,
        nowIso: now,
      );
    });
  }

  Future<void> createMilestone({
    required String projectId,
    required String title,
    String description = '',
  }) async {
    final trimmed = title.trim();
    if (trimmed.length < 2) return;

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final orderRow = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM project_milestones WHERE project_id = ?;',
      [projectId],
    );
    final sortOrder = readInt(orderRow.first, 'next_order');

    await db.insert(
      'project_milestones',
      {
        'id': IdGenerator.create('project_milestone'),
        'project_id': projectId,
        'title': trimmed,
        'description': description.trim(),
        'status': 'active',
        'sort_order': sortOrder,
        'completed_at': null,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateMilestone({
    required ProjectMilestone milestone,
    required String title,
    required String description,
  }) async {
    final trimmed = title.trim();
    if (trimmed.length < 2) return;

    final db = await AppDatabase.instance.database;
    await db.update(
      'project_milestones',
      {
        'title': trimmed,
        'description': description.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [milestone.id],
    );
  }

  Future<void> deleteMilestone(ProjectMilestone milestone) async {
    final db = await AppDatabase.instance.database;
    final tasks = await getTasksForMilestone(milestone.id);
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      for (final task in tasks) {
        if (task.isDone && task.xpApplied) {
          await _applyHeroReward(txn: txn, xp: -task.xpReward, coins: 0, nowIso: now);
          await _applyAttributeRewardsForItem(
            txn: txn,
            itemType: 'project',
            itemId: task.projectId,
            fallbackAttributeId: null,
            xp: -task.xpReward,
            nowIso: now,
          );
          await AreaProgressionService.applyAreaXp(
            executor: txn,
            areaId: await _projectAreaId(executor: txn, projectId: task.projectId),
            xp: -task.xpReward,
            nowIso: now,
          );
        }
      }

      await txn.delete('project_milestones', where: 'id = ?', whereArgs: [milestone.id]);
      await _recalculateProjectProgressFromTasks(txn: txn, projectId: milestone.projectId, nowIso: now);
    });
  }

  Future<void> addTask({
    required String projectId,
    required String title,
    String? milestoneId,
    int? xpReward,
    String notes = '',
  }) async {
    final trimmed = title.trim();
    if (trimmed.length < 2) return;

    final db = await AppDatabase.instance.database;
    final rewardService = RewardService(db);
    final now = DateTime.now().toIso8601String();
    final safeMilestoneId = milestoneId ?? await _ensureProjectHasMilestone(db, projectId);
    final defaultXp = await rewardService.projectTaskDefaultXp();
    final safeXp = await rewardService.clampProjectTaskXp(xpReward ?? defaultXp);

    await db.insert(
      'project_tasks',
      {
        'id': IdGenerator.create('project_task'),
        'project_id': projectId,
        'milestone_id': safeMilestoneId,
        'title': trimmed,
        'notes': notes.trim(),
        'xp_reward': safeXp,
        'xp_applied': 0,
        'is_done': 0,
        'completed_at': null,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateTask({
    required ProjectTask task,
    required ProjectTaskDraft draft,
  }) async {
    final db = await AppDatabase.instance.database;
    final rewardService = RewardService(db);
    final title = draft.title.trim();
    if (title.length < 2) return;

    final newXp = await rewardService.clampProjectTaskXp(draft.xpReward);
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      if (task.isDone && task.xpApplied && newXp != task.xpReward) {
        final delta = newXp - task.xpReward;
        await _applyHeroReward(txn: txn, xp: delta, coins: 0, nowIso: now);
        await _applyAttributeRewardsForItem(
          txn: txn,
          itemType: 'project',
          itemId: task.projectId,
          fallbackAttributeId: null,
          xp: delta,
          nowIso: now,
        );
        await AreaProgressionService.applyAreaXp(
          executor: txn,
          areaId: await _projectAreaId(executor: txn, projectId: task.projectId),
          xp: delta,
          nowIso: now,
        );
      }

      await txn.update(
        'project_tasks',
        {
          'title': title,
          'notes': draft.notes.trim(),
          'xp_reward': newXp,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [task.id],
      );
    });
  }

  Future<void> toggleTask(ProjectTask task, bool isDone) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final rows = await txn.query(
        'project_tasks',
        where: 'id = ?',
        whereArgs: [task.id],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final current = ProjectTask.fromMap(rows.first);
      if (current.isDone == isDone) return;

      final deltaXp = isDone ? current.xpReward : -current.xpReward;

      await txn.update(
        'project_tasks',
        {
          'is_done': isDone ? 1 : 0,
          'xp_applied': isDone ? 1 : 0,
          'completed_at': isDone ? now : null,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [task.id],
      );

      await _applyHeroReward(txn: txn, xp: deltaXp, coins: 0, nowIso: now);
      await _applyAttributeRewardsForItem(
        txn: txn,
        itemType: 'project',
        itemId: current.projectId,
        fallbackAttributeId: null,
        xp: deltaXp,
        nowIso: now,
      );
      await AreaProgressionService.applyAreaXp(
        executor: txn,
        areaId: await _projectAreaId(executor: txn, projectId: current.projectId),
        xp: deltaXp,
        nowIso: now,
      );

      await txn.insert(
        'history_events',
        {
          'id': IdGenerator.create('history'),
          'title': isDone ? 'Tarefa de projeto concluída' : 'Conclusão de tarefa desfeita',
          'description': isDone
              ? '${current.title} concedeu +${current.xpReward} XP.'
              : '${current.title} teve ${current.xpReward} XP revertidos.',
          'type': 'project_task',
          'xp_delta': deltaXp,
          'coins_delta': 0,
          'occurred_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _recalculateProjectProgressFromTasks(txn: txn, projectId: current.projectId, nowIso: now);
    });

    if (isDone) {
      await AchievementRepository().refreshAutomaticAchievements();
    }
  }

  Future<void> deleteTask(ProjectTask task) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      if (task.isDone && task.xpApplied) {
        await _applyHeroReward(txn: txn, xp: -task.xpReward, coins: 0, nowIso: now);
        await _applyAttributeRewardsForItem(
          txn: txn,
          itemType: 'project',
          itemId: task.projectId,
          fallbackAttributeId: null,
          xp: -task.xpReward,
          nowIso: now,
        );
        await AreaProgressionService.applyAreaXp(
          executor: txn,
          areaId: await _projectAreaId(executor: txn, projectId: task.projectId),
          xp: -task.xpReward,
          nowIso: now,
        );
      }

      await txn.delete('project_tasks', where: 'id = ?', whereArgs: [task.id]);

      await txn.insert(
        'history_events',
        {
          'id': IdGenerator.create('history'),
          'title': 'Tarefa de projeto removida',
          'description': task.isDone && task.xpApplied
              ? '${task.title} foi removida e ${task.xpReward} XP foram revertidos.'
              : '${task.title} foi removida do projeto.',
          'type': 'project_task',
          'xp_delta': task.isDone && task.xpApplied ? -task.xpReward : 0,
          'coins_delta': 0,
          'occurred_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _recalculateProjectProgressFromTasks(txn: txn, projectId: task.projectId, nowIso: now);
    });
  }

  Future<void> setStatus({
    required String projectId,
    required String status,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'projects',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  Future<void> archiveProject(String projectId) async {
    await setStatus(projectId: projectId, status: 'archived');
  }

  Future<CompleteProjectResult> completeProject(Project project) async {
    if (project.status == 'completed') {
      return const CompleteProjectResult(
        completed: false,
        message: 'Esse projeto já foi concluído.',
        xpGained: 0,
        coinsGained: 0,
      );
    }

    if (!project.isReadyForCompletion) {
      return const CompleteProjectResult(
        completed: false,
        message: 'Conclua todas as tarefas antes de finalizar o projeto.',
        xpGained: 0,
        coinsGained: 0,
      );
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    var xpGained = 0;
    var coinsGained = 0;

    await db.transaction((txn) async {
      final rows = await txn.query('projects', where: 'id = ?', whereArgs: [project.id], limit: 1);
      if (rows.isEmpty) return;
      final current = rows.first;
      if (readString(current, 'status') == 'completed') return;

      xpGained = readInt(current, 'xp_reward');
      coinsGained = readInt(current, 'coins_reward');

      await txn.update(
        'projects',
        {
          'status': 'completed',
          'progress': 100.0,
          'updated_at': now,
          'completed_at': now,
        },
        where: 'id = ?',
        whereArgs: [project.id],
      );

      await _applyHeroReward(txn: txn, xp: xpGained, coins: coinsGained, nowIso: now);
      await _applyAttributeRewardsForItem(
        txn: txn,
        itemType: 'project',
        itemId: project.id,
        fallbackAttributeId: readNullableString(current, 'attribute_id'),
        xp: xpGained,
        nowIso: now,
      );
      await AreaProgressionService.applyAreaXp(
        executor: txn,
        areaId: readNullableString(current, 'area_id'),
        xp: xpGained,
        nowIso: now,
      );

      await txn.insert(
        'history_events',
        {
          'id': IdGenerator.create('history'),
          'title': 'Projeto concluído: ${project.title}',
          'description': '+$xpGained XP, +$coinsGained coins. Recompensa final do projeto aplicada.',
          'type': 'project_completion',
          'xp_delta': xpGained,
          'coins_delta': coinsGained,
          'occurred_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });

    await AchievementRepository().refreshAutomaticAchievements();

    return CompleteProjectResult(
      completed: true,
      message: 'Projeto concluído! +$xpGained XP e +$coinsGained coins.',
      xpGained: xpGained,
      coinsGained: coinsGained,
    );
  }

  Future<CompleteProjectResult> undoProjectCompletion(Project project) async {
    if (project.status != 'completed') {
      return const CompleteProjectResult(
        completed: false,
        message: 'Esse projeto ainda não está concluído.',
        xpGained: 0,
        coinsGained: 0,
      );
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        'projects',
        {
          'status': 'active',
          'updated_at': now,
          'completed_at': null,
        },
        where: 'id = ?',
        whereArgs: [project.id],
      );

      await _applyHeroReward(txn: txn, xp: -project.xpReward, coins: -project.coinsReward, nowIso: now);
      await _applyAttributeRewardsForItem(
        txn: txn,
        itemType: 'project',
        itemId: project.id,
        fallbackAttributeId: project.attributeId,
        xp: -project.xpReward,
        nowIso: now,
      );
      await AreaProgressionService.applyAreaXp(
        executor: txn,
        areaId: project.areaId,
        xp: -project.xpReward,
        nowIso: now,
      );

      await txn.insert(
        'history_events',
        {
          'id': IdGenerator.create('history'),
          'title': 'Conclusão de projeto desfeita',
          'description': '${project.title} voltou para ativo. Revertidos ${project.xpReward} XP e ${project.coinsReward} coins finais.',
          'type': 'project_completion_undo',
          'xp_delta': -project.xpReward,
          'coins_delta': -project.coinsReward,
          'occurred_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await _recalculateProjectProgressFromTasks(txn: txn, projectId: project.id, nowIso: now);
    });

    return CompleteProjectResult(
      completed: true,
      message: 'Conclusão desfeita. Recompensa final revertida.',
      xpGained: -project.xpReward,
      coinsGained: -project.coinsReward,
    );
  }

  Future<String> _ensureProjectHasMilestone(Database db, String projectId) async {
    final rows = await db.query(
      'project_milestones',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'sort_order ASC, created_at ASC',
      limit: 1,
    );

    if (rows.isNotEmpty) {
      final id = rows.first['id']?.toString() ?? '';
      await db.update(
        'project_tasks',
        {'milestone_id': id, 'updated_at': DateTime.now().toIso8601String()},
        where: 'project_id = ? AND (milestone_id IS NULL OR milestone_id = ?)',
        whereArgs: [projectId, ''],
      );
      return id;
    }

    final now = DateTime.now().toIso8601String();
    final id = IdGenerator.create('project_milestone');
    await db.insert(
      'project_milestones',
      {
        'id': id,
        'project_id': projectId,
        'title': 'Marco inicial',
        'description': 'Primeira etapa do projeto.',
        'status': 'active',
        'sort_order': 0,
        'completed_at': null,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    await db.update(
      'project_tasks',
      {'milestone_id': id, 'updated_at': now},
      where: 'project_id = ? AND (milestone_id IS NULL OR milestone_id = ?)',
      whereArgs: [projectId, ''],
    );
    return id;
  }

  Future<void> _ensureAllProjectsHaveMilestones(Database db) async {
    final projects = await db.query('projects', columns: ['id']);
    for (final row in projects) {
      final id = row['id']?.toString() ?? '';
      if (id.isNotEmpty) await _ensureProjectHasMilestone(db, id);
    }
  }

  Future<void> _recalculateProjectProgressFromTasks({
    required Transaction txn,
    required String projectId,
    required String nowIso,
  }) async {
    final taskRows = await txn.rawQuery('''
      SELECT
        COUNT(*) AS total,
        COALESCE(SUM(CASE WHEN is_done = 1 THEN 1 ELSE 0 END), 0) AS done
      FROM project_tasks
      WHERE project_id = ?;
    ''', [projectId]);

    final total = readInt(taskRows.first, 'total');
    final done = readInt(taskRows.first, 'done');
    final progress = total <= 0 ? 0.0 : ((done / total) * 100).clamp(0, 100).toDouble();

    final milestoneRows = await txn.rawQuery('''
      SELECT
        project_milestones.id,
        COUNT(project_tasks.id) AS total,
        COALESCE(SUM(CASE WHEN project_tasks.is_done = 1 THEN 1 ELSE 0 END), 0) AS done
      FROM project_milestones
      LEFT JOIN project_tasks ON project_tasks.milestone_id = project_milestones.id
      WHERE project_milestones.project_id = ?
      GROUP BY project_milestones.id;
    ''', [projectId]);

    for (final row in milestoneRows) {
      final milestoneId = readString(row, 'id');
      final milestoneTotal = readInt(row, 'total');
      final milestoneDone = readInt(row, 'done');
      final completed = milestoneTotal > 0 && milestoneDone >= milestoneTotal;
      await txn.update(
        'project_milestones',
        {
          'status': completed ? 'completed' : 'active',
          'completed_at': completed ? nowIso : null,
          'updated_at': nowIso,
        },
        where: 'id = ?',
        whereArgs: [milestoneId],
      );
    }

    await txn.update(
      'projects',
      {
        'progress': progress,
        'updated_at': nowIso,
      },
      where: 'id = ? AND status != ?',
      whereArgs: [projectId, 'completed'],
    );
  }


  Future<String?> _projectAreaId({
    required DatabaseExecutor executor,
    required String projectId,
  }) async {
    final rows = await executor.rawQuery(
      'SELECT area_id FROM projects WHERE id = ? LIMIT 1;',
      [projectId],
    );
    if (rows.isEmpty) return null;
    final value = rows.first['area_id'];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _applyHeroReward({
    required Transaction txn,
    required int xp,
    required int coins,
    required String nowIso,
  }) async {
    final heroRows = await txn.query(
      'hero_profiles',
      where: 'id = ?',
      whereArgs: ['main_hero'],
      limit: 1,
    );

    if (heroRows.isEmpty) return;

    final hero = heroRows.first;
    final newXp = (readInt(hero, 'xp') + xp).clamp(0, 1 << 31).toInt();
    final newCoins = (readInt(hero, 'coins') + coins).clamp(0, 1 << 31).toInt();

    await txn.update(
      'hero_profiles',
      {
        'xp': newXp,
        'coins': newCoins,
        'level': await ProgressionService.levelFromXp(txn, newXp),
        'updated_at': nowIso,
      },
      where: 'id = ?',
      whereArgs: ['main_hero'],
    );
  }

  List<String> _normalizeAttributeIds(List<String> ids) {
    final seen = <String>{};
    final result = <String>[];

    for (final id in ids) {
      final trimmed = id.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      result.add(trimmed);
      if (result.length >= 3) break;
    }

    return result;
  }

  List<int> _weightsForCount(int count) {
    return switch (count) {
      1 => [100],
      2 => [70, 30],
      _ => [50, 30, 20],
    };
  }

  Future<void> _replaceAttributeLinks({
    required Transaction txn,
    required String itemType,
    required String itemId,
    required List<String> attributeIds,
    required String nowIso,
  }) async {
    final normalized = _normalizeAttributeIds(attributeIds);
    final weights = _weightsForCount(normalized.length);

    await txn.delete(
      'item_attribute_links',
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [itemType, itemId],
    );

    for (var index = 0; index < normalized.length; index++) {
      await txn.insert(
        'item_attribute_links',
        {
          'id': IdGenerator.create('attr_link'),
          'item_type': itemType,
          'item_id': itemId,
          'attribute_id': normalized[index],
          'weight': weights[index],
          'is_primary': index == 0 ? 1 : 0,
          'created_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyAttributeRewardsForItem({
    required Transaction txn,
    required String itemType,
    required String itemId,
    required String? fallbackAttributeId,
    required int xp,
    required String nowIso,
  }) async {
    if (xp == 0) return;
    final rows = await txn.rawQuery('''
      SELECT attribute_id, weight
      FROM item_attribute_links
      WHERE item_type = ? AND item_id = ?
      ORDER BY is_primary DESC, weight DESC, created_at ASC;
    ''', [itemType, itemId]);

    if (rows.isEmpty) {
      if (fallbackAttributeId != null && fallbackAttributeId.isNotEmpty) {
        await _applyAttributeReward(
          txn: txn,
          attributeId: fallbackAttributeId,
          xp: xp,
          nowIso: nowIso,
        );
      }
      return;
    }

    final totalWeight = rows.fold<int>(0, (sum, row) => sum + readInt(row, 'weight'));
    if (totalWeight <= 0) return;

    var remainingXp = xp;
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final attributeId = row['attribute_id']?.toString() ?? '';
      if (attributeId.isEmpty) continue;

      final share = index == rows.length - 1
          ? remainingXp
          : ((xp * readInt(row, 'weight')) / totalWeight).round().clamp(
                xp < 0 ? remainingXp : 0,
                xp < 0 ? 0 : remainingXp,
              ).toInt();
      remainingXp -= share;

      if (share == 0) continue;
      await _applyAttributeReward(txn: txn, attributeId: attributeId, xp: share, nowIso: nowIso);
    }
  }

  Future<void> _applyAttributeReward({
    required Transaction txn,
    required String attributeId,
    required int xp,
    required String nowIso,
  }) async {
    final attributeRows = await txn.query(
      'hero_attributes',
      where: 'attribute_id = ?',
      whereArgs: [attributeId],
      limit: 1,
    );

    if (attributeRows.isEmpty) return;

    final current = readInt(attributeRows.first, 'xp');
    final newAttributeXp = (current + xp).clamp(0, 1 << 31).toInt();

    await txn.update(
      'hero_attributes',
      {
        'xp': newAttributeXp,
        'points': newAttributeXp ~/ 100,
        'updated_at': nowIso,
      },
      where: 'attribute_id = ?',
      whereArgs: [attributeId],
    );
  }

}
