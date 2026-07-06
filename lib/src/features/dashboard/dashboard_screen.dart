import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/models/game_models.dart';
import '../../core/models/v3_commitment_models.dart';
import '../../core/repositories/checkin_repository.dart';
import '../../core/services/progression_service.dart';
import '../../design_system/game_design_system.dart';
import '../checkins/checkin_screen.dart';
import '../history/history_screen.dart';
import '../missions/mission_form_screen.dart';
import '../missions/mission_list_screen.dart';
import '../objectives/objective_form_screen.dart';
import '../objectives/objective_list_screen.dart';
import '../projects/project_form_screen.dart';
import '../projects/project_list_screen.dart';
import '../sessions/session_form_screen.dart';
import '../sessions/session_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _DashboardData? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _load();
      if (!mounted) return;

      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<_DashboardData> _load() async {
    final Database db = await AppDatabase.instance.database;

    final heroRows = await db.query('hero_profiles', limit: 1);
    final campaignRows = await db.query(
      'campaigns',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final activeMissionRows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM missions WHERE is_active = 1;',
    );
    final todayCompletionRows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM mission_completions WHERE completed_on >= ? AND completed_on < ?;',
      [today.toIso8601String(), tomorrow.toIso8601String()],
    );
    final activeObjectiveRows = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM objectives WHERE status = 'active';",
    );
    final todaySessionRows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM sessions WHERE created_at >= ? AND created_at < ?;',
      [today.toIso8601String(), tomorrow.toIso8601String()],
    );
    final todaySessionMinutesRows = await db.rawQuery(
      'SELECT COALESCE(SUM(duration_minutes), 0) AS total FROM sessions WHERE created_at >= ? AND created_at < ?;',
      [today.toIso8601String(), tomorrow.toIso8601String()],
    );
    final activeProjectRows = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM projects WHERE status IN ('active', 'paused');",
    );
    final activeHabitRows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM habits WHERE is_active = 1;',
    );
    final unlockedAchievementRows = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM hero_achievements
      INNER JOIN achievements ON achievements.id = hero_achievements.achievement_id
      WHERE hero_achievements.is_unlocked = 1 AND achievements.is_active = 1;
    ''');
    final difficultyModeRows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['active_difficulty_mode'],
      limit: 1,
    );
    final activeDifficultyMode = difficultyModeRows.isEmpty
        ? 'normal'
        : (difficultyModeRows.first['value']?.toString() ?? 'normal');

    final missionRows = await db.rawQuery('''
      SELECT missions.*, areas.name AS area_name, attributes.name AS attribute_name
      FROM missions
      LEFT JOIN areas ON areas.id = missions.area_id
      LEFT JOIN attributes ON attributes.id = missions.attribute_id
      WHERE missions.is_active = 1
      ORDER BY missions.created_at DESC
      LIMIT 3;
    ''');

    final objectiveRows = await db.rawQuery('''
      SELECT objectives.*, areas.name AS area_name, attributes.name AS attribute_name
      FROM objectives
      LEFT JOIN areas ON areas.id = objectives.area_id
      LEFT JOIN attributes ON attributes.id = objectives.attribute_id
      WHERE objectives.status = 'active'
      ORDER BY objectives.updated_at DESC
      LIMIT 3;
    ''');

    final sessionRows = await db.rawQuery('''
      SELECT sessions.*, areas.name AS area_name, attributes.name AS attribute_name
      FROM sessions
      LEFT JOIN areas ON areas.id = sessions.area_id
      LEFT JOIN attributes ON attributes.id = sessions.attribute_id
      ORDER BY sessions.created_at DESC
      LIMIT 3;
    ''');

    final projectRows = await db.rawQuery('''
      SELECT
        projects.*,
        areas.name AS area_name,
        attributes.name AS attribute_name,
        COUNT(project_tasks.id) AS task_count,
        COALESCE(SUM(CASE WHEN project_tasks.is_done = 1 THEN 1 ELSE 0 END), 0) AS done_task_count
      FROM projects
      LEFT JOIN areas ON areas.id = projects.area_id
      LEFT JOIN attributes ON attributes.id = projects.attribute_id
      LEFT JOIN project_tasks ON project_tasks.project_id = projects.id
      WHERE projects.status IN ('active', 'paused')
      GROUP BY projects.id
      ORDER BY projects.updated_at DESC
      LIMIT 3;
    ''');

    final attributeRows = await db.rawQuery('''
      SELECT attributes.id, attributes.name, hero_attributes.points, hero_attributes.xp
      FROM hero_attributes
      INNER JOIN attributes ON attributes.id = hero_attributes.attribute_id
      ORDER BY hero_attributes.xp DESC, attributes.sort_order ASC
      LIMIT 4;
    ''');

    final historyRows = await db.query(
      'history_events',
      orderBy: 'occurred_at DESC',
      limit: 4,
    );

    final checkInRepository = CheckInRepository();
    final checkInSummary = await checkInRepository.getSummary();
    final checkInPreviewCoins = await checkInRepository.previewTodayCoins();
    final recentCheckIns = await checkInRepository.getRecentCheckIns(limit: 5);

    return _DashboardData(
      hero: heroRows.isEmpty ? null : heroRows.first,
      campaign: campaignRows.isEmpty ? null : campaignRows.first,
      todayMissionCompletions: readInt(todayCompletionRows.first, 'total'),
      activeMissions: readInt(activeMissionRows.first, 'total'),
      activeObjectives: readInt(activeObjectiveRows.first, 'total'),
      todaySessions: readInt(todaySessionRows.first, 'total'),
      todaySessionMinutes: readInt(todaySessionMinutesRows.first, 'total'),
      activeProjects: readInt(activeProjectRows.first, 'total'),
      activeHabits: readInt(activeHabitRows.first, 'total'),
      unlockedAchievements: readInt(unlockedAchievementRows.first, 'total'),
      activeDifficultyMode: activeDifficultyMode.isEmpty
          ? 'normal'
          : activeDifficultyMode,
      missions: missionRows.map(Mission.fromMap).toList(),
      objectives: objectiveRows.map(Objective.fromMap).toList(),
      sessions: sessionRows.map(ManualSession.fromMap).toList(),
      projects: projectRows.map(Project.fromMap).toList(),
      attributes: attributeRows,
      history: historyRows.map(HistoryEvent.fromMap).toList(),
      checkInSummary: checkInSummary,
      checkInPreviewCoins: checkInPreviewCoins,
      recentCheckIns: recentCheckIns,
    );
  }

  Future<void> _doDailyCheckIn() async {
    try {
      final result = await CheckInRepository().checkInToday();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.coinsGained > 0
                ? '${result.message} +${result.coinsGained} coins.'
                : result.message,
          ),
        ),
      );
      await _loadDashboard();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao fazer check-in: $error')));
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    if (!mounted) return;
    await _loadDashboard();
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;

    if (hours <= 0) return '${minutes}min';
    if (rest == 0) return '${hours}h';
    return '${hours}h ${rest}min';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _data == null) {
      return _DashboardError(error: _error.toString(), onRetry: _loadDashboard);
    }

    final data = _data;
    if (data == null) {
      return _DashboardError(
        error: 'Dashboard sem dados carregados.',
        onRetry: _loadDashboard,
      );
    }

    final hero = data.hero;
    final campaign = data.campaign;
    final xp = hero == null ? 0 : readInt(hero, 'xp');
    final coins = hero == null ? 0 : readInt(hero, 'coins');
    final level = hero == null ? 1 : readInt(hero, 'level');
    final levelProgress = _levelProgressFromXp(xp, data.activeDifficultyMode);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: GameSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DashboardEntry(
                delay: 0,
                child: _HeroSummaryCard(
                  campaignTitle:
                      campaign?['title']?.toString() ?? 'Transformação 20–25',
                  heroTitle:
                      hero?['title']?.toString() ??
                      'Iniciante da Transformação',
                  level: level,
                  xp: xp,
                  coins: coins,
                  levelProgress: levelProgress,
                  difficultyMode: data.activeDifficultyMode,
                ),
              ),
              const SizedBox(height: GameSpacing.md),
              _DashboardEntry(
                delay: 40,
                child: _TodaySummarySection(
                  completedMissions: data.todayMissionCompletions,
                  sessionCount: data.todaySessions,
                  focusTime: _formatDuration(data.todaySessionMinutes),
                  activeMissions: data.activeMissions,
                  activeObjectives: data.activeObjectives,
                  activeProjects: data.activeProjects,
                  activeHabits: data.activeHabits,
                  unlockedAchievements: data.unlockedAchievements,
                  loading: _loading,
                  onRefresh: _loading ? null : _loadDashboard,
                ),
              ),
              const SizedBox(height: GameSpacing.md),
              _DashboardEntry(
                delay: 80,
                child: _DailyRhythmSection(
                  summary: data.checkInSummary,
                  previewCoins: data.checkInPreviewCoins,
                  recentCheckIns: data.recentCheckIns,
                  onCheckIn: _doDailyCheckIn,
                  onOpen: () => _open(const CheckInScreen()),
                ),
              ),
              const SizedBox(height: GameSpacing.md),
              _DashboardEntry(
                delay: 120,
                child: _MissionPreviewSection(
                  missions: data.missions,
                  onOpen: () => _open(const MissionListScreen()),
                  onCreate: () => _open(const MissionFormScreen()),
                ),
              ),
              const SizedBox(height: GameSpacing.md),
              _DashboardEntry(
                delay: 160,
                child: _ObjectivePreviewSection(
                  objectives: data.objectives,
                  onOpen: () => _open(const ObjectiveListScreen()),
                  onCreate: () => _open(const ObjectiveFormScreen()),
                ),
              ),
              const SizedBox(height: GameSpacing.md),
              _DashboardEntry(
                delay: 200,
                child: _ProjectPreviewSection(
                  projects: data.projects,
                  onOpen: () => _open(const ProjectListScreen()),
                  onCreate: () => _open(const ProjectFormScreen()),
                ),
              ),
              const SizedBox(height: GameSpacing.md),
              _DashboardEntry(
                delay: 240,
                child: _SessionPreviewSection(
                  sessions: data.sessions,
                  onOpen: () => _open(const SessionListScreen()),
                  onCreate: () => _open(const SessionFormScreen()),
                ),
              ),
              const SizedBox(height: GameSpacing.md),
              _DashboardEntry(
                delay: 280,
                child: _AttributePreviewSection(attributes: data.attributes),
              ),
              const SizedBox(height: GameSpacing.md),
              _DashboardEntry(
                delay: 320,
                child: _HistoryPreviewSection(
                  events: data.history,
                  onOpen: () => _open(const HistoryScreen()),
                ),
              ),
              const SizedBox(height: GameSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardEntry extends StatelessWidget {
  const _DashboardEntry({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GameMotion.normal + Duration(milliseconds: delay),
      curve: GameMotion.curve,
      builder: (context, value, animatedChild) {
        return AnimatedOpacity(
          opacity: value,
          duration: GameMotion.fast,
          child: Padding(
            padding: EdgeInsets.only(top: (1 - value) * 8),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.campaignTitle,
    required this.heroTitle,
    required this.level,
    required this.xp,
    required this.coins,
    required this.levelProgress,
    required this.difficultyMode,
  });

  final String campaignTitle;
  final String heroTitle;
  final int level;
  final int xp;
  final int coins;
  final double levelProgress;
  final String difficultyMode;

  @override
  Widget build(BuildContext context) {
    return GameHighlightCard(
      accentColor: GameColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameColors.primary.withValues(alpha: 0.20),
                  border: Border.all(
                    color: GameColors.primary.withValues(alpha: 0.36),
                  ),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: GameColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: GameSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaignTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.display,
                    ),
                    const SizedBox(height: GameSpacing.xs),
                    Text(
                      heroTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.body,
                    ),
                    const SizedBox(height: GameSpacing.sm),
                    Wrap(
                      spacing: GameSpacing.xs,
                      runSpacing: GameSpacing.xs,
                      children: [
                        const GameChip(
                          label: 'Campanha ativa',
                          icon: Icons.auto_awesome_rounded,
                          color: GameColors.reward,
                          selected: true,
                        ),
                        GameChip(
                          label: _difficultyLabel(difficultyMode),
                          icon: Icons.speed_rounded,
                          color: _difficultyColor(difficultyMode),
                          selected: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroMiniStat(
                  label: 'Nível',
                  value: '$level',
                  icon: Icons.star_rounded,
                  color: GameColors.primary,
                ),
              ),
              const SizedBox(width: GameSpacing.xs),
              Expanded(
                child: _HeroMiniStat(
                  label: 'XP',
                  value: '$xp',
                  icon: Icons.bolt_rounded,
                  color: GameColors.success,
                ),
              ),
              const SizedBox(width: GameSpacing.xs),
              Expanded(
                child: _HeroMiniStat(
                  label: 'Coins',
                  value: '$coins',
                  icon: Icons.monetization_on_rounded,
                  color: GameColors.coin,
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progresso do nível',
                  style: GameTextStyles.caption,
                ),
              ),
              Text(
                '${(levelProgress * 100).round()}%',
                style: GameTextStyles.caption.copyWith(
                  color: GameColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.xs),
          GameProgressBar(
            value: levelProgress,
            height: 12,
            color: GameColors.primary,
            showGlow: true,
          ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GameSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.16),
            GameColors.surface.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(GameRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: GameSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameTextStyles.statValue,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _TodaySummarySection extends StatelessWidget {
  const _TodaySummarySection({
    required this.completedMissions,
    required this.sessionCount,
    required this.focusTime,
    required this.activeMissions,
    required this.activeObjectives,
    required this.activeProjects,
    required this.activeHabits,
    required this.unlockedAchievements,
    required this.loading,
    required this.onRefresh,
  });

  final int completedMissions;
  final int sessionCount;
  final String focusTime;
  final int activeMissions;
  final int activeObjectives;
  final int activeProjects;
  final int activeHabits;
  final int unlockedAchievements;
  final bool loading;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameSectionHeader(
          title: 'Resumo de hoje',
          subtitle: 'Seu estado atual da jornada.',
          icon: Icons.today_rounded,
          actionLabel: loading ? 'Atualizando...' : 'Atualizar',
          onAction: onRefresh,
        ),
        _StatRow(
          left: GameStatTile(
            label: 'Missões hoje',
            value: '$completedMissions',
            icon: Icons.check_circle_rounded,
            color: GameColors.success,
          ),
          right: GameStatTile(
            label: 'Sessões hoje',
            value: '$sessionCount',
            icon: Icons.timer_rounded,
            color: GameColors.info,
          ),
        ),
        const SizedBox(height: GameSpacing.xs),
        _StatRow(
          left: GameStatTile(
            label: 'Tempo focado',
            value: focusTime,
            icon: Icons.hourglass_bottom_rounded,
            color: GameColors.primary,
          ),
          right: GameStatTile(
            label: 'Hábitos ativos',
            value: '$activeHabits',
            icon: Icons.repeat_rounded,
            color: GameColors.vigor,
          ),
        ),
        const SizedBox(height: GameSpacing.xs),
        _StatRow(
          left: GameStatTile(
            label: 'Missões ativas',
            value: '$activeMissions',
            icon: Icons.flag_rounded,
            color: GameColors.success,
          ),
          right: GameStatTile(
            label: 'Objetivos ativos',
            value: '$activeObjectives',
            icon: Icons.track_changes_rounded,
            color: GameColors.info,
          ),
        ),
        const SizedBox(height: GameSpacing.xs),
        _StatRow(
          left: GameStatTile(
            label: 'Projetos ativos',
            value: '$activeProjects',
            icon: Icons.folder_special_rounded,
            color: GameColors.reward,
          ),
          right: GameStatTile(
            label: 'Conquistas',
            value: '$unlockedAchievements',
            icon: Icons.emoji_events_rounded,
            color: GameColors.reward,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: GameSpacing.xs),
        Expanded(child: right),
      ],
    );
  }
}

class _DailyRhythmSection extends StatelessWidget {
  const _DailyRhythmSection({
    required this.summary,
    required this.previewCoins,
    required this.recentCheckIns,
    required this.onCheckIn,
    required this.onOpen,
  });

  final CheckInSummary summary;
  final int previewCoins;
  final List<DailyCheckIn> recentCheckIns;
  final VoidCallback onCheckIn;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final recentLabel = recentCheckIns.isEmpty
        ? 'Nenhum check-in ainda'
        : 'Último: ${_formatDashboardCheckInDate(recentCheckIns.first.checkInDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameSectionHeader(
          title: 'Ritmo diário',
          subtitle: 'Presença, sequência e recompensa diária.',
          icon: Icons.local_fire_department_rounded,
          actionLabel: 'Abrir',
          onAction: onOpen,
        ),
        GameCard(
          borderColor: summary.canCheckInToday
              ? GameColors.reward.withValues(alpha: 0.42)
              : GameColors.success.withValues(alpha: 0.36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GameColors.reward.withValues(alpha: 0.16),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: GameColors.reward,
                    ),
                  ),
                  const SizedBox(width: GameSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.canCheckInToday
                              ? 'Check-in disponível'
                              : 'Check-in feito hoje',
                          style: GameTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(recentLabel, style: GameTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GameSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _HeroMiniStat(
                      label: 'Sequência',
                      value: '${summary.currentStreak}d',
                      icon: Icons.local_fire_department_rounded,
                      color: GameColors.reward,
                    ),
                  ),
                  const SizedBox(width: GameSpacing.xs),
                  Expanded(
                    child: _HeroMiniStat(
                      label: 'Melhor',
                      value: '${summary.bestStreak}d',
                      icon: Icons.military_tech_rounded,
                      color: GameColors.primary,
                    ),
                  ),
                  const SizedBox(width: GameSpacing.xs),
                  Expanded(
                    child: _HeroMiniStat(
                      label: 'Check-ins',
                      value: '${summary.totalCheckIns}',
                      icon: Icons.event_available_rounded,
                      color: GameColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GameSpacing.md),
              if (summary.canCheckInToday)
                GamePrimaryButton(
                  label: 'Fazer check-in (+$previewCoins coins)',
                  icon: Icons.done_rounded,
                  onPressed: onCheckIn,
                )
              else
                GameSecondaryButton(
                  label: 'Ver ritmo diário',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: onOpen,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDashboardCheckInDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return value;
  return '${parts[2]}/${parts[1]}';
}

class _MissionPreviewSection extends StatelessWidget {
  const _MissionPreviewSection({
    required this.missions,
    required this.onOpen,
    required this.onCreate,
  });

  final List<Mission> missions;
  final VoidCallback onOpen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      title: 'Missões ativas',
      subtitle: 'As próximas ações da sua jornada.',
      icon: Icons.flag_rounded,
      actionLabel: missions.isEmpty ? 'Criar' : 'Ver',
      onAction: missions.isEmpty ? onCreate : onOpen,
      empty: missions.isEmpty
          ? GameEmptyState(
              title: 'Nenhuma missão ativa',
              message:
                  'Crie uma missão diária, semanal ou especial para começar a pontuar hoje.',
              icon: Icons.flag_rounded,
              actionLabel: 'Criar missão',
              onAction: onCreate,
            )
          : null,
      children: [
        for (final mission in missions)
          _MissionCard(mission: mission, onTap: onOpen),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission, required this.onTap});

  final Mission mission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = GameColors.attributeById(mission.attributeId);

    return GameCompactCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoundIcon(icon: Icons.flag_rounded, color: color),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  '${mission.typeLabel} • ${mission.difficultyLabel} • ${mission.attributeName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: GameSpacing.xs),
          _RewardBadge(xp: mission.xpReward, coins: mission.coinsReward),
        ],
      ),
    );
  }
}

class _ObjectivePreviewSection extends StatelessWidget {
  const _ObjectivePreviewSection({
    required this.objectives,
    required this.onOpen,
    required this.onCreate,
  });

  final List<Objective> objectives;
  final VoidCallback onOpen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      title: 'Objetivos ativos',
      subtitle: 'Metas mensuráveis em andamento.',
      icon: Icons.track_changes_rounded,
      actionLabel: objectives.isEmpty ? 'Criar' : 'Ver',
      onAction: objectives.isEmpty ? onCreate : onOpen,
      empty: objectives.isEmpty
          ? GameEmptyState(
              title: 'Nenhum objetivo ativo',
              message:
                  'Crie uma meta com número, unidade e recompensa para acompanhar avanço real.',
              icon: Icons.track_changes_rounded,
              actionLabel: 'Criar objetivo',
              onAction: onCreate,
            )
          : null,
      children: [
        for (final objective in objectives)
          _ObjectiveCard(objective: objective, onTap: onOpen),
      ],
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({required this.objective, required this.onTap});

  final Objective objective;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = GameColors.attributeById(objective.attributeId);

    return GameCompactCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundIcon(icon: Icons.track_changes_rounded, color: color),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      objective.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      objective.progressText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: objective.progressPercent, color: color),
        ],
      ),
    );
  }
}

class _ProjectPreviewSection extends StatelessWidget {
  const _ProjectPreviewSection({
    required this.projects,
    required this.onOpen,
    required this.onCreate,
  });

  final List<Project> projects;
  final VoidCallback onOpen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      title: 'Projetos ativos',
      subtitle: 'Construções de médio e longo prazo.',
      icon: Icons.folder_special_rounded,
      actionLabel: projects.isEmpty ? 'Criar' : 'Ver',
      onAction: projects.isEmpty ? onCreate : onOpen,
      empty: projects.isEmpty
          ? GameEmptyState(
              title: 'Nenhum projeto ativo',
              message:
                  'Crie projetos para organizar tarefas maiores como estudos, apps e finanças.',
              icon: Icons.folder_special_rounded,
              actionLabel: 'Criar projeto',
              onAction: onCreate,
            )
          : null,
      children: [
        for (final project in projects)
          _ProjectCard(project: project, onTap: onOpen),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = GameColors.attributeById(project.attributeId);

    return GameCompactCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundIcon(icon: Icons.folder_special_rounded, color: color),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${project.progressText} • ${project.doneTaskCount}/${project.taskCount} tarefas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: project.progressPercent, color: color),
        ],
      ),
    );
  }
}

class _SessionPreviewSection extends StatelessWidget {
  const _SessionPreviewSection({
    required this.sessions,
    required this.onOpen,
    required this.onCreate,
  });

  final List<ManualSession> sessions;
  final VoidCallback onOpen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      title: 'Sessões recentes',
      subtitle: 'Blocos reais de foco registrados.',
      icon: Icons.timer_rounded,
      actionLabel: sessions.isEmpty ? 'Registrar' : 'Ver',
      onAction: sessions.isEmpty ? onCreate : onOpen,
      empty: sessions.isEmpty
          ? GameEmptyState(
              title: 'Nenhuma sessão recente',
              message:
                  'Registre blocos de treino, estudo, devocional, programação ou organização.',
              icon: Icons.timer_rounded,
              actionLabel: 'Registrar sessão',
              onAction: onCreate,
            )
          : null,
      children: [
        for (final session in sessions)
          _SessionCard(session: session, onTap: onOpen),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final ManualSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = GameColors.attributeById(session.attributeId);

    return GameCompactCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoundIcon(icon: Icons.timer_rounded, color: color),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.typeLabel} • ${session.durationText} • ${session.attributeName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: GameSpacing.xs),
          _RewardBadge(xp: session.xpGained, coins: session.coinsGained),
        ],
      ),
    );
  }
}

class _AttributePreviewSection extends StatelessWidget {
  const _AttributePreviewSection({required this.attributes});

  final List<Map<String, Object?>> attributes;

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      title: 'Atributos em destaque',
      subtitle: 'Os atributos mais movimentados até agora.',
      icon: Icons.auto_graph_rounded,
      empty: attributes.isEmpty
          ? const GameEmptyState(
              title: 'Nenhum atributo carregado',
              message:
                  'Os atributos aparecem aqui conforme suas ações geram XP.',
              icon: Icons.auto_graph_rounded,
            )
          : null,
      children: [
        _StatRow(
          left: attributes.isNotEmpty
              ? _AttributeTile(attribute: attributes[0])
              : const SizedBox.shrink(),
          right: attributes.length > 1
              ? _AttributeTile(attribute: attributes[1])
              : const SizedBox.shrink(),
        ),
        if (attributes.length > 2) ...[
          const SizedBox(height: GameSpacing.xs),
          _StatRow(
            left: _AttributeTile(attribute: attributes[2]),
            right: attributes.length > 3
                ? _AttributeTile(attribute: attributes[3])
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _AttributeTile extends StatelessWidget {
  const _AttributeTile({required this.attribute});

  final Map<String, Object?> attribute;

  @override
  Widget build(BuildContext context) {
    final id = attribute['id']?.toString();
    final name = attribute['name']?.toString() ?? 'Atributo';
    final points = readInt(attribute, 'points');
    final xp = readInt(attribute, 'xp');
    final color = GameColors.attributeById(id);

    return GameStatTile(
      label: '$points pts • $xp XP',
      value: name,
      icon: Icons.auto_awesome_rounded,
      color: color,
    );
  }
}

class _HistoryPreviewSection extends StatelessWidget {
  const _HistoryPreviewSection({required this.events, required this.onOpen});

  final List<HistoryEvent> events;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      title: 'Histórico recente',
      subtitle: 'Memória curta da sua jornada.',
      icon: Icons.history_rounded,
      actionLabel: 'Ver',
      onAction: onOpen,
      empty: events.isEmpty
          ? const GameEmptyState(
              title: 'Nenhum evento recente',
              message:
                  'Quando missões, sessões e objetivos forem registrados, eles aparecem aqui.',
              icon: Icons.history_rounded,
            )
          : null,
      children: [
        for (final event in events)
          GameCompactCard(
            onTap: onOpen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _RoundIcon(
                  icon: Icons.bolt_rounded,
                  color: GameColors.primary,
                ),
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GameTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${event.typeLabel} • ${event.dateText}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GameTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.actionLabel,
    this.onAction,
    this.empty,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameSectionHeader(
          title: title,
          subtitle: subtitle,
          icon: icon,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
        if (empty != null)
          empty!
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(height: GameSpacing.xs),
                children[index],
              ],
            ],
          ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.xp, required this.coins});

  final int xp;
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '+$xp XP',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameTextStyles.caption.copyWith(color: GameColors.success),
        ),
        const SizedBox(height: 2),
        Text(
          '+$coins c',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameTextStyles.caption.copyWith(color: GameColors.coin),
        ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: GameSpacing.screen,
        child: GameCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: GameColors.danger),
              const SizedBox(height: GameSpacing.sm),
              Text(
                'Erro ao carregar o Dashboard',
                style: GameTextStyles.sectionTitle,
              ),
              const SizedBox(height: GameSpacing.xs),
              Text(error, style: GameTextStyles.body),
              const SizedBox(height: GameSpacing.md),
              GamePrimaryButton(
                label: 'Tentar novamente',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.hero,
    required this.campaign,
    required this.todayMissionCompletions,
    required this.activeMissions,
    required this.activeObjectives,
    required this.todaySessions,
    required this.todaySessionMinutes,
    required this.activeProjects,
    required this.activeHabits,
    required this.unlockedAchievements,
    required this.activeDifficultyMode,
    required this.missions,
    required this.objectives,
    required this.sessions,
    required this.projects,
    required this.attributes,
    required this.history,
    required this.checkInSummary,
    required this.checkInPreviewCoins,
    required this.recentCheckIns,
  });

  final Map<String, Object?>? hero;
  final Map<String, Object?>? campaign;
  final int todayMissionCompletions;
  final int activeMissions;
  final int activeObjectives;
  final int todaySessions;
  final int todaySessionMinutes;
  final int activeProjects;
  final int activeHabits;
  final int unlockedAchievements;
  final String activeDifficultyMode;
  final List<Mission> missions;
  final List<Objective> objectives;
  final List<ManualSession> sessions;
  final List<Project> projects;
  final List<Map<String, Object?>> attributes;
  final List<HistoryEvent> history;
  final CheckInSummary checkInSummary;
  final int checkInPreviewCoins;
  final List<DailyCheckIn> recentCheckIns;
}

String _difficultyLabel(String mode) {
  return switch (mode) {
    'hard' => 'Modo difícil',
    'hardcore' => 'Modo hardcore',
    _ => 'Modo normal',
  };
}

Color _difficultyColor(String mode) {
  return switch (mode) {
    'hard' => GameColors.warning,
    'hardcore' => GameColors.danger,
    _ => GameColors.success,
  };
}

double _levelProgressFromXp(int xp, String difficultyMode) {
  return ProgressionService.snapshotFromXpSync(
    xp,
    difficultyMode: difficultyMode,
  ).progress;
}
