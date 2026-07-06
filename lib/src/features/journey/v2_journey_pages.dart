import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/models/game_models.dart';
import '../../design_system/game_design_system.dart';
import '../missions/mission_form_screen.dart';
import '../missions/mission_list_screen.dart';
import '../objectives/objective_form_screen.dart';
import '../objectives/objective_list_screen.dart';

class V2MissionHubPage extends StatefulWidget {
  const V2MissionHubPage({super.key});

  @override
  State<V2MissionHubPage> createState() => _V2MissionHubPageState();
}

class _V2MissionHubPageState extends State<V2MissionHubPage> {
  late Future<_MissionHubData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_MissionHubData> _load() async {
    final db = await AppDatabase.instance.database;

    final missionRows = await db.rawQuery('''
      SELECT
        missions.*,
        areas.name AS area_name,
        attributes.name AS attribute_name
      FROM missions
      LEFT JOIN areas ON areas.id = missions.area_id
      LEFT JOIN attributes ON attributes.id = missions.attribute_id
      WHERE missions.is_active = 1
      ORDER BY
        CASE missions.type
          WHEN 'daily' THEN 1
          WHEN 'weekly' THEN 2
          WHEN 'monthly' THEN 3
          WHEN 'special' THEN 4
          ELSE 5
        END,
        missions.created_at DESC
      LIMIT 4;
    ''');

    final counts = await db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN type = 'daily' THEN 1 ELSE 0 END) AS daily,
        SUM(CASE WHEN type = 'weekly' THEN 1 ELSE 0 END) AS weekly,
        SUM(CASE WHEN type = 'monthly' THEN 1 ELSE 0 END) AS monthly,
        SUM(CASE WHEN type = 'special' THEN 1 ELSE 0 END) AS special
      FROM missions
      WHERE is_active = 1;
    ''');

    final completions = await db.rawQuery('SELECT COUNT(*) AS total FROM mission_completions;');

    final countRow = counts.first;
    return _MissionHubData(
      missions: missionRows.map(Mission.fromMap).toList(),
      total: _asInt(countRow['total']),
      daily: _asInt(countRow['daily']),
      weekly: _asInt(countRow['weekly']),
      monthly: _asInt(countRow['monthly']),
      special: _asInt(countRow['special']),
      completions: _asInt(completions.first['total']),
    );
  }

  Future<void> _openList() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MissionListScreen()));
    if (mounted) setState(() => _future = _load());
  }

  Future<void> _openForm() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const MissionFormScreen()));
    if (created == true && mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MissionHubData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return _V2JourneyScroll(
          children: [
            GameHighlightCard(
              accentColor: GameColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag_rounded, color: GameColors.primary, size: 34),
                  const SizedBox(height: GameSpacing.sm),
                  Text('Missões', style: GameTextStyles.title),
                  const SizedBox(height: GameSpacing.xs),
                  Text(
                    'Rotinas recorrentes e desafios pontuais que geram XP, coins e atributos.',
                    style: GameTextStyles.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: GameSpacing.md),
            Row(
              children: [
                Expanded(
                  child: GameStatTile(
                    label: 'Ativas',
                    value: '${data?.total ?? 0}',
                    icon: Icons.flag_rounded,
                    color: GameColors.primary,
                    onTap: _openList,
                  ),
                ),
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: GameStatTile(
                    label: 'Conclusões',
                    value: '${data?.completions ?? 0}',
                    icon: Icons.check_circle_rounded,
                    color: GameColors.success,
                    onTap: _openList,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GameSpacing.md),
            Wrap(
              spacing: GameSpacing.xs,
              runSpacing: GameSpacing.xs,
              children: [
                GameChip(label: 'Diárias ${data?.daily ?? 0}', icon: Icons.today_rounded, color: GameColors.success, selected: (data?.daily ?? 0) > 0),
                GameChip(label: 'Semanais ${data?.weekly ?? 0}', icon: Icons.calendar_view_week_rounded, color: GameColors.info, selected: (data?.weekly ?? 0) > 0),
                GameChip(label: 'Mensais ${data?.monthly ?? 0}', icon: Icons.calendar_month_rounded, color: GameColors.primary, selected: (data?.monthly ?? 0) > 0),
                GameChip(label: 'Especiais ${data?.special ?? 0}', icon: Icons.auto_awesome_rounded, color: GameColors.reward, selected: (data?.special ?? 0) > 0),
              ],
            ),
            const SizedBox(height: GameSpacing.md),
            Row(
              children: [
                Expanded(
                  child: GamePrimaryButton(label: 'Criar missão', icon: Icons.add_rounded, onPressed: _openForm),
                ),
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: GameSecondaryButton(label: 'Ver lista', icon: Icons.list_alt_rounded, onPressed: _openList),
                ),
              ],
            ),
            const SizedBox(height: GameSpacing.lg),
            GameSectionHeader(
              title: 'Próximas missões',
              subtitle: loading ? 'Carregando...' : 'Prévia segura das missões ativas.',
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(height: GameSpacing.sm),
            if (loading)
              const Center(child: Padding(padding: EdgeInsets.all(GameSpacing.lg), child: CircularProgressIndicator()))
            else if ((data?.missions ?? const <Mission>[]).isEmpty)
              GameEmptyState(
                icon: Icons.flag_outlined,
                title: 'Nenhuma missão ativa',
                message: 'Crie uma missão diária, semanal, mensal ou especial para iniciar o ciclo da Jornada.',
                actionLabel: 'Criar missão',
                onAction: _openForm,
              )
            else
              for (final mission in data!.missions) ...[
                _MissionPreviewCard(mission: mission, onTap: _openList),
                const SizedBox(height: GameSpacing.sm),
              ],
          ],
        );
      },
    );
  }
}

class V2ObjectiveHubPage extends StatefulWidget {
  const V2ObjectiveHubPage({super.key});

  @override
  State<V2ObjectiveHubPage> createState() => _V2ObjectiveHubPageState();
}

class _V2ObjectiveHubPageState extends State<V2ObjectiveHubPage> {
  late Future<_ObjectiveHubData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ObjectiveHubData> _load() async {
    final db = await AppDatabase.instance.database;

    final objectiveRows = await db.rawQuery('''
      SELECT
        objectives.*,
        areas.name AS area_name,
        attributes.name AS attribute_name
      FROM objectives
      LEFT JOIN areas ON areas.id = objectives.area_id
      LEFT JOIN attributes ON attributes.id = objectives.attribute_id
      WHERE objectives.status = 'active'
      ORDER BY objectives.created_at DESC
      LIMIT 4;
    ''');

    final activeCount = await db.rawQuery("SELECT COUNT(*) AS total FROM objectives WHERE status = 'active';");
    final completedCount = await db.rawQuery("SELECT COUNT(*) AS total FROM objectives WHERE status = 'completed';");

    final objectives = objectiveRows.map(Objective.fromMap).toList();
    final averageProgress = objectives.isEmpty
        ? 0.0
        : objectives.fold<double>(0, (total, objective) => total + objective.progressPercent) / objectives.length;

    return _ObjectiveHubData(
      objectives: objectives,
      active: _asInt(activeCount.first['total']),
      completed: _asInt(completedCount.first['total']),
      averageProgress: averageProgress,
    );
  }

  Future<void> _openList() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ObjectiveListScreen()));
    if (mounted) setState(() => _future = _load());
  }

  Future<void> _openForm() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const ObjectiveFormScreen()));
    if (created == true && mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ObjectiveHubData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final progress = data?.averageProgress ?? 0;

        return _V2JourneyScroll(
          children: [
            GameHighlightCard(
              accentColor: GameColors.info,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.track_changes_rounded, color: GameColors.info, size: 34),
                  const SizedBox(height: GameSpacing.sm),
                  Text('Objetivos', style: GameTextStyles.title),
                  const SizedBox(height: GameSpacing.xs),
                  Text(
                    'Metas mensuráveis para transformar intenção em avanço visível.',
                    style: GameTextStyles.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: GameSpacing.md),
            Row(
              children: [
                Expanded(
                  child: GameStatTile(
                    label: 'Ativos',
                    value: '${data?.active ?? 0}',
                    icon: Icons.track_changes_rounded,
                    color: GameColors.info,
                    onTap: _openList,
                  ),
                ),
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: GameStatTile(
                    label: 'Concluídos',
                    value: '${data?.completed ?? 0}',
                    icon: Icons.emoji_events_rounded,
                    color: GameColors.reward,
                    onTap: _openList,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GameSpacing.md),
            GameCard(
              backgroundColor: GameColors.surfaceSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timeline_rounded, color: GameColors.info),
                      const SizedBox(width: GameSpacing.xs),
                      Expanded(child: Text('Progresso médio', style: GameTextStyles.cardTitle)),
                      Text('${(progress * 100).round()}%', style: GameTextStyles.statValue),
                    ],
                  ),
                  const SizedBox(height: GameSpacing.sm),
                  GameProgressBar(value: progress, color: GameColors.info, showGlow: true),
                ],
              ),
            ),
            const SizedBox(height: GameSpacing.md),
            Row(
              children: [
                Expanded(
                  child: GamePrimaryButton(label: 'Criar objetivo', icon: Icons.add_rounded, onPressed: _openForm),
                ),
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: GameSecondaryButton(label: 'Ver lista', icon: Icons.list_alt_rounded, onPressed: _openList),
                ),
              ],
            ),
            const SizedBox(height: GameSpacing.lg),
            GameSectionHeader(
              title: 'Objetivos em andamento',
              subtitle: loading ? 'Carregando...' : 'Prévia com progresso visual.',
              icon: Icons.auto_graph_rounded,
            ),
            const SizedBox(height: GameSpacing.sm),
            if (loading)
              const Center(child: Padding(padding: EdgeInsets.all(GameSpacing.lg), child: CircularProgressIndicator()))
            else if ((data?.objectives ?? const <Objective>[]).isEmpty)
              GameEmptyState(
                icon: Icons.track_changes_outlined,
                title: 'Nenhum objetivo ativo',
                message: 'Crie uma meta mensurável para acompanhar progresso parcial até a recompensa final.',
                actionLabel: 'Criar objetivo',
                onAction: _openForm,
              )
            else
              for (final objective in data!.objectives) ...[
                _ObjectivePreviewCard(objective: objective, onTap: _openList),
                const SizedBox(height: GameSpacing.sm),
              ],
          ],
        );
      },
    );
  }
}

class V2CampaignPage extends StatelessWidget {
  const V2CampaignPage({super.key});

  Future<_CampaignHubData> _load() async {
    final db = await AppDatabase.instance.database;

    final campaignRows = await db.query('campaigns', where: 'is_active = ?', whereArgs: [1], limit: 1);
    final heroRows = await db.query('hero_profiles', limit: 1);
    final missionCompletions = await db.rawQuery('SELECT COUNT(*) AS total FROM mission_completions;');
    final sessions = await db.rawQuery('SELECT COUNT(*) AS total FROM sessions;');
    final completedObjectives = await db.rawQuery("SELECT COUNT(*) AS total FROM objectives WHERE status = 'completed';");
    final completedProjects = await db.rawQuery("SELECT COUNT(*) AS total FROM projects WHERE status = 'completed';");
    final history = await db.rawQuery('SELECT COUNT(*) AS total FROM history_events;');

    return _CampaignHubData(
      campaign: campaignRows.isEmpty ? null : campaignRows.first,
      hero: heroRows.isEmpty ? null : heroRows.first,
      missionCompletions: _asInt(missionCompletions.first['total']),
      sessions: _asInt(sessions.first['total']),
      completedObjectives: _asInt(completedObjectives.first['total']),
      completedProjects: _asInt(completedProjects.first['total']),
      historyEvents: _asInt(history.first['total']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CampaignHubData>(
      future: _load(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final campaign = data?.campaign ?? const <String, Object?>{};
        final hero = data?.hero ?? const <String, Object?>{};
        final title = readString(campaign, 'title', fallback: 'Transformação 20–25');
        final description = readString(
          campaign,
          'description',
          fallback: 'Campanha principal de evolução pessoal do Game Life.',
        );
        final heroLevel = hero.isEmpty ? 1 : readInt(hero, 'level');
        final heroXp = readInt(hero, 'xp');
        final coins = readInt(hero, 'coins');

        return _V2JourneyScroll(
          children: [
            GameHighlightCard(
              accentColor: GameColors.faith,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: GameColors.faith, size: 36),
                  const SizedBox(height: GameSpacing.sm),
                  Text(title, style: GameTextStyles.title),
                  const SizedBox(height: GameSpacing.xs),
                  Text(description, style: GameTextStyles.body),
                ],
              ),
            ),
            const SizedBox(height: GameSpacing.md),
            Row(
              children: [
                Expanded(
                  child: GameStatTile(label: 'Nível', value: '$heroLevel', icon: Icons.star_rounded, color: GameColors.primary),
                ),
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: GameStatTile(label: 'Coins', value: '$coins', icon: Icons.monetization_on_rounded, color: GameColors.coin),
                ),
              ],
            ),
            const SizedBox(height: GameSpacing.sm),
            GameStatTile(label: 'XP acumulado na campanha', value: '$heroXp', icon: Icons.bolt_rounded, color: GameColors.info),
            const SizedBox(height: GameSpacing.lg),
            const GameSectionHeader(
              title: 'Resumo da campanha',
              subtitle: 'Uma leitura rápida do que já foi registrado na jornada.',
              icon: Icons.map_rounded,
            ),
            const SizedBox(height: GameSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: GameStatTile(
                    label: 'Missões feitas',
                    value: '${data?.missionCompletions ?? 0}',
                    icon: Icons.check_circle_rounded,
                    color: GameColors.success,
                  ),
                ),
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: GameStatTile(
                    label: 'Sessões',
                    value: '${data?.sessions ?? 0}',
                    icon: Icons.timer_rounded,
                    color: GameColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GameSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: GameStatTile(
                    label: 'Objetivos',
                    value: '${data?.completedObjectives ?? 0}',
                    icon: Icons.emoji_events_rounded,
                    color: GameColors.reward,
                  ),
                ),
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: GameStatTile(
                    label: 'Projetos',
                    value: '${data?.completedProjects ?? 0}',
                    icon: Icons.folder_special_rounded,
                    color: GameColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GameSpacing.sm),
            GameStatTile(
              label: 'Eventos no histórico',
              value: '${data?.historyEvents ?? 0}',
              icon: Icons.history_rounded,
              color: GameColors.discipline,
            ),
            const SizedBox(height: GameSpacing.lg),
            GameCard(
              backgroundColor: GameColors.surfaceSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nota da campanha', style: GameTextStyles.cardTitle),
                  const SizedBox(height: GameSpacing.xs),
                  Text(
                    'A Campanha agora é uma tela real da Jornada, ainda sem edição avançada. Esta área pode evoluir depois com capítulos, marcos e leitura de longo prazo.',
                    style: GameTextStyles.body,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _V2JourneyScroll extends StatelessWidget {
  const _V2JourneyScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: GameSpacing.screen,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - GameSpacing.md * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MissionPreviewCard extends StatelessWidget {
  const _MissionPreviewCard({required this.mission, required this.onTap});

  final Mission mission;
  final VoidCallback onTap;

  Color get _color {
    return switch (mission.type) {
      'daily' => GameColors.success,
      'weekly' => GameColors.info,
      'monthly' => GameColors.primary,
      'special' => GameColors.reward,
      _ => GameColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GameCard(
      onTap: onTap,
      padding: const EdgeInsets.all(GameSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _color.withValues(alpha: 0.16)),
            child: Icon(Icons.flag_rounded, color: _color, size: 20),
          ),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mission.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text('${mission.typeLabel} • ${mission.difficultyLabel}', style: GameTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: GameSpacing.xs),
          Text('+${mission.xpReward} XP', style: GameTextStyles.caption.copyWith(color: GameColors.info, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ObjectivePreviewCard extends StatelessWidget {
  const _ObjectivePreviewCard({required this.objective, required this.onTap});

  final Objective objective;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = GameColors.attributeById(objective.attributeId);

    return GameCard(
      onTap: onTap,
      padding: const EdgeInsets.all(GameSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.16)),
                child: Icon(Icons.track_changes_rounded, color: color, size: 20),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Text(objective.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
              ),
              Text('${(objective.progressPercent * 100).round()}%', style: GameTextStyles.caption.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: objective.progressPercent, color: color),
          const SizedBox(height: GameSpacing.xs),
          Text(objective.progressText, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
        ],
      ),
    );
  }
}

class _MissionHubData {
  const _MissionHubData({
    required this.missions,
    required this.total,
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.special,
    required this.completions,
  });

  final List<Mission> missions;
  final int total;
  final int daily;
  final int weekly;
  final int monthly;
  final int special;
  final int completions;
}

class _ObjectiveHubData {
  const _ObjectiveHubData({
    required this.objectives,
    required this.active,
    required this.completed,
    required this.averageProgress,
  });

  final List<Objective> objectives;
  final int active;
  final int completed;
  final double averageProgress;
}

class _CampaignHubData {
  const _CampaignHubData({
    required this.campaign,
    required this.hero,
    required this.missionCompletions,
    required this.sessions,
    required this.completedObjectives,
    required this.completedProjects,
    required this.historyEvents,
  });

  final Map<String, Object?>? campaign;
  final Map<String, Object?>? hero;
  final int missionCompletions;
  final int sessions;
  final int completedObjectives;
  final int completedProjects;
  final int historyEvents;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
