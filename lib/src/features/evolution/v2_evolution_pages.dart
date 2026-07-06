import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/models/game_models.dart';
import '../../core/repositories/history_repository.dart';
import '../../core/repositories/system_repository.dart';
import '../../core/services/progression_service.dart';
import '../../design_system/game_design_system.dart';
import '../history/history_screen.dart';
import '../system/system_report_screen.dart';

class V2HeroOverviewPage extends StatelessWidget {
  const V2HeroOverviewPage({super.key});

  Future<_EvolutionOverview> _load() async {
    final db = await AppDatabase.instance.database;
    final heroRows = await db.query('hero_profiles', limit: 1);
    final campaignRows = await db.query(
      'campaigns',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    final attributes = await _loadAttributes();
    final areas = await _loadAreas();
    final stats = await const SystemRepository().getStats();
    final historyStats = await HistoryRepository().getStats();
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day).toIso8601String();

    final todayRows = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS events,
        COALESCE(SUM(xp_delta), 0) AS xp,
        COALESCE(SUM(coins_delta), 0) AS coins
      FROM history_events
      WHERE occurred_at >= ?;
      ''',
      [startOfToday],
    );

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

    return _EvolutionOverview(
      hero: heroRows.isEmpty ? null : heroRows.first,
      campaign: campaignRows.isEmpty ? null : campaignRows.first,
      attributes: attributes,
      areas: areas,
      systemStats: stats,
      historyStats: historyStats,
      todayStats: todayRows.isEmpty ? const <String, Object?>{} : todayRows.first,
      activeDifficultyMode: activeDifficultyMode.isEmpty ? 'normal' : activeDifficultyMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EvolutionOverview>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _EvolutionErrorCard(
            title: 'Erro ao carregar herói',
            message: snapshot.error.toString(),
          );
        }

        final data = snapshot.data ?? _EvolutionOverview.empty();
        final hero = data.hero ?? const <String, Object?>{};
        final campaign = data.campaign ?? const <String, Object?>{};
        final name = readString(hero, 'name', fallback: 'Herói da Jornada');
        final title = readString(hero, 'title', fallback: 'Iniciante da Transformação');
        final level = readInt(hero, 'level');
        final xp = readInt(hero, 'xp');
        final coins = readInt(hero, 'coins');
        final xpInfo = _levelProgressInfoFromXp(xp, data.activeDifficultyMode);
        final xpProgress = xpInfo.progress;
        final campaignTitle = readString(campaign, 'title', fallback: 'Transformação 20–25');
        final topAttribute = data.topAttribute;
        final topArea = data.topArea;

        return SafeArea(
          child: SingleChildScrollView(
            padding: GameSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameHighlightCard(
                  accentColor: GameColors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: GameColors.reward.withValues(alpha: 0.18),
                              border: Border.all(color: GameColors.reward.withValues(alpha: 0.36)),
                            ),
                            child: const Icon(Icons.shield_rounded, color: GameColors.rewardSoft, size: 32),
                          ),
                          const SizedBox(width: GameSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.title),
                                const SizedBox(height: GameSpacing.xxs),
                                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GameTextStyles.body),
                                const SizedBox(height: GameSpacing.xs),
                                GameChip(
                                  label: campaignTitle,
                                  icon: Icons.auto_awesome_rounded,
                                  color: GameColors.faith,
                                  selected: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: GameSpacing.lg),
                      Row(
                        children: [
                          Text('Nível $level', style: GameTextStyles.cardTitle),
                          const Spacer(),
                          Text('${xpInfo.current}/${xpInfo.required} XP', style: GameTextStyles.caption),
                        ],
                      ),
                      const SizedBox(height: GameSpacing.xs),
                      GameProgressBar(
                        value: xpProgress,
                        color: GameColors.primary,
                        showGlow: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GameSpacing.md),
                const GameSectionHeader(
                  title: 'Resumo do herói',
                  subtitle: 'Indicadores principais da sua campanha pessoal.',
                  icon: Icons.insights_rounded,
                ),
                _StatPair(
                  left: GameStatTile(label: 'XP total', value: '$xp', icon: Icons.bolt_rounded, color: GameColors.info),
                  right: GameStatTile(label: 'Coins', value: '$coins', icon: Icons.monetization_on_rounded, color: GameColors.reward),
                ),
                const SizedBox(height: GameSpacing.sm),
                _StatPair(
                  left: GameStatTile(label: 'Eventos hoje', value: '${readInt(data.todayStats, 'events')}', icon: Icons.today_rounded, color: GameColors.success),
                  right: GameStatTile(label: 'XP hoje', value: '${readInt(data.todayStats, 'xp')}', icon: Icons.flash_on_rounded, color: GameColors.primary),
                ),
                const SizedBox(height: GameSpacing.sm),
                _StatPair(
                  left: GameStatTile(label: 'Eventos totais', value: '${data.historyStats.totalEvents}', icon: Icons.history_rounded, color: GameColors.textMuted),
                  right: GameStatTile(label: 'Atributos', value: '${data.attributes.length}', icon: Icons.auto_graph_rounded, color: GameColors.faith),
                ),
                const SizedBox(height: GameSpacing.sm),
                _StatPair(
                  left: GameStatTile(label: 'Áreas', value: '${data.areas.length}', icon: Icons.public_rounded, color: GameColors.success),
                  right: GameStatTile(label: 'Área líder', value: topArea?.name ?? '—', icon: Icons.flag_circle_rounded, color: topArea == null ? GameColors.textMuted : GameColors.areaById(topArea.id)),
                ),
                const SizedBox(height: GameSpacing.md),
                const GameSectionHeader(
                  title: 'Atributo dominante',
                  subtitle: 'O atributo que recebeu mais XP até agora.',
                  icon: Icons.emoji_events_rounded,
                ),
                if (topAttribute == null)
                  const GameEmptyState(
                    title: 'Nenhum atributo treinado ainda',
                    message: 'Conclua missões, objetivos, sessões ou projetos para fortalecer seu herói.',
                    icon: Icons.auto_graph_rounded,
                  )
                else
                  _AttributeSpotlight(attribute: topAttribute),
                const SizedBox(height: GameSpacing.md),
                const GameSectionHeader(
                  title: 'Estrutura atual',
                  subtitle: 'Volume de conteúdo registrado no app.',
                  icon: Icons.account_tree_rounded,
                ),
                GameCard(
                  child: Column(
                    children: [
                      _InfoLine(label: 'Missões criadas', value: '${data.systemStats.missions}'),
                      _InfoLine(label: 'Objetivos criados', value: '${data.systemStats.objectives}'),
                      _InfoLine(label: 'Sessões registradas', value: '${data.systemStats.sessions}'),
                      _InfoLine(label: 'Projetos criados', value: '${data.systemStats.projects}'),
                    ],
                  ),
                ),
                const SizedBox(height: GameSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}

class V2AttributesPage extends StatelessWidget {
  const V2AttributesPage({super.key});

  Future<List<AttributeEvolution>> _load() => _loadAttributes();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AttributeEvolution>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _EvolutionErrorCard(
            title: 'Erro ao carregar atributos',
            message: snapshot.error.toString(),
          );
        }

        final attributes = snapshot.data ?? const <AttributeEvolution>[];
        final totalXp = attributes.fold<int>(0, (sum, item) => sum + item.xp);
        final totalPoints = attributes.fold<int>(0, (sum, item) => sum + item.points);
        final trained = attributes.where((item) => item.xp > 0 || item.points > 0).length;
        final top = [...attributes]..sort((a, b) => b.xp.compareTo(a.xp));
        final topAttribute = top.isEmpty ? null : top.first;

        return SafeArea(
          child: SingleChildScrollView(
            padding: GameSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameHighlightCard(
                  accentColor: GameColors.faith,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_graph_rounded, color: GameColors.faith, size: 34),
                      const SizedBox(height: GameSpacing.sm),
                      const Text('Atributos', style: GameTextStyles.title),
                      const SizedBox(height: GameSpacing.xs),
                      const Text(
                        'Seu crescimento distribuído em força, vigor, clareza, foco, criatividade, responsabilidade, disciplina e fé.',
                        style: GameTextStyles.body,
                      ),
                      const SizedBox(height: GameSpacing.md),
                      Row(
                        children: [
                          Expanded(child: _MiniMetric(label: 'XP', value: '$totalXp', color: GameColors.info)),
                          const SizedBox(width: GameSpacing.sm),
                          Expanded(child: _MiniMetric(label: 'Pontos', value: '$totalPoints', color: GameColors.reward)),
                          const SizedBox(width: GameSpacing.sm),
                          Expanded(child: _MiniMetric(label: 'Treinados', value: '$trained/${attributes.length}', color: GameColors.success)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GameSpacing.md),
                if (topAttribute != null && topAttribute.xp > 0) ...[
                  const GameSectionHeader(
                    title: 'Mais desenvolvido',
                    subtitle: 'Atributo que mais recebeu XP até agora.',
                    icon: Icons.workspace_premium_rounded,
                  ),
                  _AttributeSpotlight(attribute: topAttribute),
                  const SizedBox(height: GameSpacing.md),
                ],
                const GameSectionHeader(
                  title: 'Todos os atributos',
                  subtitle: 'Barras animadas indicam o avanço para o próximo ponto.',
                  icon: Icons.grid_view_rounded,
                ),
                if (attributes.isEmpty)
                  const GameEmptyState(
                    title: 'Atributos não encontrados',
                    message: 'O seed inicial deve criar os atributos automaticamente.',
                    icon: Icons.auto_graph_rounded,
                  )
                else
                  for (final attribute in attributes) ...[
                    _AttributeProgressCard(attribute: attribute),
                    const SizedBox(height: GameSpacing.sm),
                  ],
                const SizedBox(height: GameSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}


class V2AreasPage extends StatelessWidget {
  const V2AreasPage({super.key});

  Future<List<AreaEvolution>> _load() => _loadAreas();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AreaEvolution>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _EvolutionErrorCard(
            title: 'Erro ao carregar áreas',
            message: snapshot.error.toString(),
          );
        }

        final areas = snapshot.data ?? const <AreaEvolution>[];
        final totalXp = areas.fold<int>(0, (sum, item) => sum + item.xp);
        final trained = areas.where((item) => item.xp > 0 || item.points > 0).length;
        final top = [...areas]..sort((a, b) => b.xp.compareTo(a.xp));
        final topArea = top.isEmpty ? null : top.first;

        return SafeArea(
          child: SingleChildScrollView(
            padding: GameSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameHighlightCard(
                  accentColor: GameColors.success,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.public_rounded, color: GameColors.success, size: 34),
                      const SizedBox(height: GameSpacing.sm),
                      const Text('Áreas da vida', style: GameTextStyles.title),
                      const SizedBox(height: GameSpacing.xs),
                      const Text(
                        'Cada missão, hábito, objetivo, sessão ou projeto agora fortalece também a área vinculada. É o mapa maior da sua evolução.',
                        style: GameTextStyles.body,
                      ),
                      const SizedBox(height: GameSpacing.md),
                      Row(
                        children: [
                          Expanded(child: _MiniMetric(label: 'XP total', value: '$totalXp', color: GameColors.info)),
                          const SizedBox(width: GameSpacing.sm),
                          Expanded(child: _MiniMetric(label: 'Treinadas', value: '$trained/${areas.length}', color: GameColors.success)),
                          const SizedBox(width: GameSpacing.sm),
                          Expanded(child: _MiniMetric(label: 'Líder', value: topArea?.name ?? '—', color: topArea == null ? GameColors.textMuted : GameColors.areaById(topArea.id))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GameSpacing.md),
                if (topArea != null && topArea.xp > 0) ...[
                  const GameSectionHeader(
                    title: 'Domínio mais forte',
                    subtitle: 'Área que mais recebeu XP até agora.',
                    icon: Icons.workspace_premium_rounded,
                  ),
                  _AreaSpotlight(area: topArea),
                  const SizedBox(height: GameSpacing.md),
                ],
                const GameSectionHeader(
                  title: 'Todos os domínios',
                  subtitle: 'As áreas evoluem em ciclos de 100 XP, como um panorama macro da campanha.',
                  icon: Icons.grid_view_rounded,
                ),
                if (areas.isEmpty)
                  const GameEmptyState(
                    title: 'Áreas não encontradas',
                    message: 'O seed inicial deve criar as áreas automaticamente.',
                    icon: Icons.public_rounded,
                  )
                else
                  for (final area in areas) ...[
                    _AreaProgressCard(area: area),
                    const SizedBox(height: GameSpacing.sm),
                  ],
                const SizedBox(height: GameSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}

class V2EvolutionReportPage extends StatelessWidget {
  const V2EvolutionReportPage({super.key});

  Future<_EvolutionReport> _load() async {
    final db = await AppDatabase.instance.database;
    final historyRepository = HistoryRepository();
    final systemRepository = const SystemRepository();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final week = today.subtract(Duration(days: today.weekday - 1));
    final month = DateTime(now.year, now.month);

    final dayStats = await _loadPeriodStats(today.toIso8601String());
    final weekStats = await _loadPeriodStats(week.toIso8601String());
    final monthStats = await _loadPeriodStats(month.toIso8601String());
    final historyStats = await historyRepository.getStats();
    final systemStats = await systemRepository.getStats();
    final recentRewards = await historyRepository.getRecentRewardEvents(limit: 5);

    final sessionRows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(duration_minutes), 0) AS total_minutes,
        COALESCE(SUM(CASE WHEN created_at >= ? THEN duration_minutes ELSE 0 END), 0) AS week_minutes,
        COALESCE(SUM(CASE WHEN created_at >= ? THEN duration_minutes ELSE 0 END), 0) AS month_minutes
      FROM sessions;
    ''', [week.toIso8601String(), month.toIso8601String()]);

    return _EvolutionReport(
      dayStats: dayStats,
      weekStats: weekStats,
      monthStats: monthStats,
      historyStats: historyStats,
      systemStats: systemStats,
      recentRewards: recentRewards,
      sessionStats: sessionRows.isEmpty ? const <String, Object?>{} : sessionRows.first,
    );
  }

  Future<_PeriodStats> _loadPeriodStats(String startIso) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) AS events,
        COALESCE(SUM(xp_delta), 0) AS xp,
        COALESCE(SUM(coins_delta), 0) AS coins,
        COALESCE(SUM(CASE WHEN type = 'mission_completion' THEN 1 ELSE 0 END), 0) AS missions,
        COALESCE(SUM(CASE WHEN type IN ('objective_completion', 'objective_progress') THEN 1 ELSE 0 END), 0) AS objectives,
        COALESCE(SUM(CASE WHEN type = 'manual_session' THEN 1 ELSE 0 END), 0) AS sessions,
        COALESCE(SUM(CASE WHEN type = 'project_completion' THEN 1 ELSE 0 END), 0) AS projects
      FROM history_events
      WHERE occurred_at >= ?;
    ''', [startIso]);

    if (rows.isEmpty) return _PeriodStats.empty();
    return _PeriodStats.fromMap(rows.first);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EvolutionReport>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _EvolutionErrorCard(
            title: 'Erro ao carregar relatório',
            message: snapshot.error.toString(),
          );
        }

        final data = snapshot.data ?? _EvolutionReport.empty();

        return SafeArea(
          child: SingleChildScrollView(
            padding: GameSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameHighlightCard(
                  accentColor: GameColors.info,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.description_rounded, color: GameColors.info, size: 34),
                      const SizedBox(height: GameSpacing.sm),
                      const Text('Relatório de evolução', style: GameTextStyles.title),
                      const SizedBox(height: GameSpacing.xs),
                      Text(
                        'Período da jornada: ${data.historyStats.journeyPeriodText}',
                        style: GameTextStyles.body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GameSpacing.md),
                const GameSectionHeader(
                  title: 'Hoje',
                  subtitle: 'Movimento registrado desde o início do dia.',
                  icon: Icons.today_rounded,
                ),
                _PeriodCard(stats: data.dayStats, accentColor: GameColors.success),
                const SizedBox(height: GameSpacing.md),
                const GameSectionHeader(
                  title: 'Semana',
                  subtitle: 'Resumo da semana atual.',
                  icon: Icons.calendar_view_week_rounded,
                ),
                _PeriodCard(stats: data.weekStats, accentColor: GameColors.primary),
                const SizedBox(height: GameSpacing.md),
                const GameSectionHeader(
                  title: 'Mês',
                  subtitle: 'Resumo do mês atual.',
                  icon: Icons.calendar_month_rounded,
                ),
                _PeriodCard(stats: data.monthStats, accentColor: GameColors.info),
                const SizedBox(height: GameSpacing.md),
                const GameSectionHeader(
                  title: 'Totais da jornada',
                  subtitle: 'Panorama acumulado da base local.',
                  icon: Icons.stacked_bar_chart_rounded,
                ),
                GameCard(
                  child: Column(
                    children: [
                      _InfoLine(label: 'Eventos registrados', value: '${data.historyStats.totalEvents}'),
                      _InfoLine(label: 'XP no histórico', value: '${data.historyStats.totalXp}'),
                      _InfoLine(label: 'Coins no histórico', value: '${data.historyStats.totalCoins}'),
                      _InfoLine(label: 'Missões / Objetivos', value: '${data.systemStats.missions} / ${data.systemStats.objectives}'),
                      _InfoLine(label: 'Sessões / Projetos', value: '${data.systemStats.sessions} / ${data.systemStats.projects}'),
                      _InfoLine(label: 'Tempo focado na semana', value: _formatMinutes(readInt(data.sessionStats, 'week_minutes'))),
                      _InfoLine(label: 'Tempo focado no mês', value: _formatMinutes(readInt(data.sessionStats, 'month_minutes'))),
                    ],
                  ),
                ),
                const SizedBox(height: GameSpacing.md),
                const GameSectionHeader(
                  title: 'Recompensas recentes',
                  subtitle: 'Últimos ganhos que movimentaram o personagem.',
                  icon: Icons.star_rounded,
                ),
                if (data.recentRewards.isEmpty)
                  const GameEmptyState(
                    title: 'Sem recompensas recentes',
                    message: 'Conclua missões, objetivos, sessões ou projetos para alimentar este painel.',
                    icon: Icons.star_border_rounded,
                  )
                else
                  for (final event in data.recentRewards) ...[
                    _RewardCard(event: event),
                    const SizedBox(height: GameSpacing.sm),
                  ],
                const SizedBox(height: GameSpacing.md),
                GameSecondaryButton(
                  label: 'Abrir histórico completo',
                  icon: Icons.history_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                const SizedBox(height: GameSpacing.sm),
                GameSecondaryButton(
                  label: 'Abrir relatório técnico',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SystemReportScreen()),
                  ),
                ),
                const SizedBox(height: GameSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _AreaProgressCard extends StatelessWidget {
  const _AreaProgressCard({required this.area});

  final AreaEvolution area;

  @override
  Widget build(BuildContext context) {
    final color = GameColors.areaById(area.id);

    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CircleIcon(icon: _areaIcon(area.id), color: color),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(area.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                    if (area.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(area.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
                    ],
                    if (area.linkedAttributes.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Atributos: ${area.linkedAttributes}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: GameSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Nv. ${area.level}', style: GameTextStyles.cardTitle),
                  Text('${area.xp} XP', style: GameTextStyles.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(
            value: area.progressToNextPoint,
            color: color,
            showGlow: area.xp > 0,
          ),
          const SizedBox(height: GameSpacing.xs),
          Text(area.nextPointText, style: GameTextStyles.caption),
        ],
      ),
    );
  }
}

class _AreaSpotlight extends StatelessWidget {
  const _AreaSpotlight({required this.area});

  final AreaEvolution area;

  @override
  Widget build(BuildContext context) {
    final color = GameColors.areaById(area.id);

    return GameHighlightCard(
      accentColor: color,
      padding: const EdgeInsets.all(GameSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleIcon(icon: _areaIcon(area.id), color: color),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(area.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text('${area.xp} XP • nível ${area.level}', style: GameTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: area.progressToNextPoint, color: color, showGlow: true),
        ],
      ),
    );
  }
}

class _AttributeProgressCard extends StatelessWidget {
  const _AttributeProgressCard({required this.attribute});

  final AttributeEvolution attribute;

  @override
  Widget build(BuildContext context) {
    final color = GameColors.attributeById(attribute.id);

    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CircleIcon(icon: _attributeIcon(attribute.id), color: color),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(attribute.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                    if (attribute.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(attribute.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: GameSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${attribute.points} pts', style: GameTextStyles.cardTitle),
                  Text('${attribute.xp} XP', style: GameTextStyles.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(
            value: attribute.progressToNextPoint,
            color: color,
            showGlow: attribute.xp > 0,
          ),
          const SizedBox(height: GameSpacing.xs),
          Text(attribute.nextPointText, style: GameTextStyles.caption),
        ],
      ),
    );
  }
}

class _AttributeSpotlight extends StatelessWidget {
  const _AttributeSpotlight({required this.attribute});

  final AttributeEvolution attribute;

  @override
  Widget build(BuildContext context) {
    final color = GameColors.attributeById(attribute.id);

    return GameHighlightCard(
      accentColor: color,
      padding: const EdgeInsets.all(GameSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleIcon(icon: _attributeIcon(attribute.id), color: color),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(attribute.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text('${attribute.xp} XP • ${attribute.points} pontos', style: GameTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: attribute.progressToNextPoint, color: color, showGlow: true),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.stats, required this.accentColor});

  final _PeriodStats stats;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      child: Column(
        children: [
          _StatPair(
            left: GameStatTile(label: 'Eventos', value: '${stats.events}', icon: Icons.event_available_rounded, color: accentColor),
            right: GameStatTile(label: 'XP', value: '${stats.xp}', icon: Icons.bolt_rounded, color: GameColors.info),
          ),
          const SizedBox(height: GameSpacing.sm),
          _StatPair(
            left: GameStatTile(label: 'Coins', value: '${stats.coins}', icon: Icons.monetization_on_rounded, color: GameColors.reward),
            right: GameStatTile(label: 'Sessões', value: '${stats.sessions}', icon: Icons.timer_rounded, color: GameColors.success),
          ),
          const SizedBox(height: GameSpacing.sm),
          _InfoLine(label: 'Missões concluídas', value: '${stats.missions}'),
          _InfoLine(label: 'Objetivos/progressos', value: '${stats.objectives}'),
          _InfoLine(label: 'Projetos concluídos', value: '${stats.projects}'),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.event});

  final HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    return GameCompactCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star_rounded, color: GameColors.reward, size: 22),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text('${event.dateText} • ${event.rewardText}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GameSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: GameRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.statValue),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _StatPair extends StatelessWidget {
  const _StatPair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: GameSpacing.sm),
        Expanded(child: right),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GameSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: GameTextStyles.caption)),
          const SizedBox(width: GameSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GameTextStyles.body.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionErrorCard extends StatelessWidget {
  const _EvolutionErrorCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: GameSpacing.screen,
        child: GameCard(
          borderColor: GameColors.danger.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: GameColors.danger),
              const SizedBox(height: GameSpacing.sm),
              Text(title, style: GameTextStyles.cardTitle),
              const SizedBox(height: GameSpacing.xs),
              Text(message, style: GameTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvolutionOverview {
  const _EvolutionOverview({
    required this.hero,
    required this.campaign,
    required this.attributes,
    required this.areas,
    required this.systemStats,
    required this.historyStats,
    required this.todayStats,
    required this.activeDifficultyMode,
  });

  final Map<String, Object?>? hero;
  final Map<String, Object?>? campaign;
  final List<AttributeEvolution> attributes;
  final List<AreaEvolution> areas;
  final SystemStats systemStats;
  final HistoryStats historyStats;
  final Map<String, Object?> todayStats;
  final String activeDifficultyMode;

  factory _EvolutionOverview.empty() {
    return _EvolutionOverview(
      hero: null,
      campaign: null,
      attributes: const [],
      areas: const [],
      systemStats: const SystemStats(
        missions: 0,
        objectives: 0,
        habits: 0,
        sessions: 0,
        projects: 0,
        historyEvents: 0,
        totalXpHistory: 0,
        totalCoinsHistory: 0,
      ),
      historyStats: HistoryStats.empty(),
      todayStats: const {},
      activeDifficultyMode: 'normal',
    );
  }

  AttributeEvolution? get topAttribute {
    if (attributes.isEmpty) return null;
    final sorted = [...attributes]..sort((a, b) => b.xp.compareTo(a.xp));
    return sorted.first;
  }

  AreaEvolution? get topArea {
    if (areas.isEmpty) return null;
    final sorted = [...areas]..sort((a, b) => b.xp.compareTo(a.xp));
    return sorted.first;
  }
}

class _EvolutionReport {
  const _EvolutionReport({
    required this.dayStats,
    required this.weekStats,
    required this.monthStats,
    required this.historyStats,
    required this.systemStats,
    required this.recentRewards,
    required this.sessionStats,
  });

  final _PeriodStats dayStats;
  final _PeriodStats weekStats;
  final _PeriodStats monthStats;
  final HistoryStats historyStats;
  final SystemStats systemStats;
  final List<HistoryEvent> recentRewards;
  final Map<String, Object?> sessionStats;

  factory _EvolutionReport.empty() {
    return _EvolutionReport(
      dayStats: _PeriodStats.empty(),
      weekStats: _PeriodStats.empty(),
      monthStats: _PeriodStats.empty(),
      historyStats: HistoryStats.empty(),
      systemStats: const SystemStats(
        missions: 0,
        objectives: 0,
        habits: 0,
        sessions: 0,
        projects: 0,
        historyEvents: 0,
        totalXpHistory: 0,
        totalCoinsHistory: 0,
      ),
      recentRewards: const [],
      sessionStats: const {},
    );
  }
}

class _PeriodStats {
  const _PeriodStats({
    required this.events,
    required this.xp,
    required this.coins,
    required this.missions,
    required this.objectives,
    required this.sessions,
    required this.projects,
  });

  final int events;
  final int xp;
  final int coins;
  final int missions;
  final int objectives;
  final int sessions;
  final int projects;

  factory _PeriodStats.fromMap(Map<String, Object?> map) {
    return _PeriodStats(
      events: readInt(map, 'events'),
      xp: readInt(map, 'xp'),
      coins: readInt(map, 'coins'),
      missions: readInt(map, 'missions'),
      objectives: readInt(map, 'objectives'),
      sessions: readInt(map, 'sessions'),
      projects: readInt(map, 'projects'),
    );
  }

  factory _PeriodStats.empty() {
    return const _PeriodStats(
      events: 0,
      xp: 0,
      coins: 0,
      missions: 0,
      objectives: 0,
      sessions: 0,
      projects: 0,
    );
  }
}


Future<List<AreaEvolution>> _loadAreas() async {
  final db = await AppDatabase.instance.database;
  await db.execute("""
    CREATE TABLE IF NOT EXISTS hero_areas (
      id TEXT PRIMARY KEY,
      area_id TEXT NOT NULL UNIQUE,
      points INTEGER NOT NULL DEFAULT 0,
      xp INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (area_id) REFERENCES areas(id) ON DELETE CASCADE
    );
  """);
  final now = DateTime.now().toIso8601String();
  await db.rawInsert("""
    INSERT OR IGNORE INTO hero_areas (id, area_id, points, xp, created_at, updated_at)
    SELECT 'hero_area_' || areas.id, areas.id, 0, 0, ?, ?
    FROM areas;
  """, [now, now]);

  final rows = await db.rawQuery("""
    SELECT
      areas.id,
      areas.name,
      areas.description,
      areas.color,
      areas.icon,
      areas.sort_order,
      COALESCE(hero_areas.points, 0) AS points,
      COALESCE(hero_areas.xp, 0) AS xp,
      COALESCE(GROUP_CONCAT(attributes.name, ', '), '') AS linked_attributes
    FROM areas
    LEFT JOIN hero_areas ON hero_areas.area_id = areas.id
    LEFT JOIN area_attribute_links ON area_attribute_links.area_id = areas.id
    LEFT JOIN attributes ON attributes.id = area_attribute_links.attribute_id
    GROUP BY areas.id
    ORDER BY areas.sort_order;
  """);

  return rows.map(AreaEvolution.fromMap).toList();
}

Future<List<AttributeEvolution>> _loadAttributes() async {
  final db = await AppDatabase.instance.database;
  final rows = await db.rawQuery('''
    SELECT
      attributes.id,
      attributes.name,
      attributes.description,
      hero_attributes.points,
      hero_attributes.xp
    FROM hero_attributes
    INNER JOIN attributes ON attributes.id = hero_attributes.attribute_id
    ORDER BY attributes.sort_order;
  ''');

  return rows.map(AttributeEvolution.fromMap).toList();
}


IconData _areaIcon(String id) {
  return switch (id) {
    'body_health' => Icons.fitness_center_rounded,
    'mind_knowledge' => Icons.menu_book_rounded,
    'spirit_purpose' => Icons.auto_awesome_rounded,
    'projects_career' => Icons.work_rounded,
    'creation_expression' => Icons.brush_rounded,
    'finance_responsibility' => Icons.savings_rounded,
    'routine_order' => Icons.checklist_rounded,
    _ => Icons.public_rounded,
  };
}

IconData _attributeIcon(String id) {
  return switch (id) {
    'strength' => Icons.fitness_center_rounded,
    'vigor' => Icons.bolt_rounded,
    'clarity' => Icons.psychology_rounded,
    'focus' => Icons.center_focus_strong_rounded,
    'creativity' => Icons.palette_rounded,
    'responsibility' => Icons.account_balance_wallet_rounded,
    'discipline' => Icons.verified_rounded,
    'faith' => Icons.auto_awesome_rounded,
    _ => Icons.auto_graph_rounded,
  };
}

String _formatMinutes(int minutes) {
  if (minutes <= 0) return '0min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours <= 0) return '${minutes}min';
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}min';
}


_LevelProgressInfo _levelProgressInfoFromXp(int xp, String difficultyMode) {
  final snapshot = ProgressionService.snapshotFromXpSync(
    xp,
    difficultyMode: difficultyMode,
  );
  return _LevelProgressInfo(
    current: snapshot.currentLevelXp,
    required: snapshot.requiredForNextLevel,
    progress: snapshot.progress,
  );
}

class _LevelProgressInfo {
  const _LevelProgressInfo({
    required this.current,
    required this.required,
    required this.progress,
  });

  final int current;
  final int required;
  final double progress;
}
