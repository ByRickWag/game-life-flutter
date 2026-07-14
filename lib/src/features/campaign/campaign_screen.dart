import 'package:flutter/material.dart';

import '../../core/models/v3_commitment_models.dart';
import '../../core/repositories/campaign_commitment_repository.dart';
import '../../design_system/game_design_system.dart';

const List<_ChapterAreaOption> _chapterAreaOptions = [
  _ChapterAreaOption(
    id: 'body_health',
    label: 'Corpo e Saúde',
    icon: Icons.fitness_center_rounded,
    color: GameColors.vigor,
  ),
  _ChapterAreaOption(
    id: 'mind_knowledge',
    label: 'Mente e Conhecimento',
    icon: Icons.menu_book_rounded,
    color: GameColors.clarity,
  ),
  _ChapterAreaOption(
    id: 'spirit_purpose',
    label: 'Fé e Propósito',
    icon: Icons.auto_awesome_rounded,
    color: GameColors.faith,
  ),
  _ChapterAreaOption(
    id: 'projects_career',
    label: 'Carreira e Projetos',
    icon: Icons.work_rounded,
    color: GameColors.reward,
  ),
  _ChapterAreaOption(
    id: 'creation_expression',
    label: 'Criação e Expressão',
    icon: Icons.brush_rounded,
    color: GameColors.primary,
  ),
  _ChapterAreaOption(
    id: 'finance_responsibility',
    label: 'Finanças e Reino',
    icon: Icons.savings_rounded,
    color: GameColors.responsibility,
  ),
  _ChapterAreaOption(
    id: 'routine_order',
    label: 'Rotina e Ordem',
    icon: Icons.checklist_rounded,
    color: GameColors.discipline,
  ),
];

class _ChapterAreaOption {
  const _ChapterAreaOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  final CampaignCommitmentRepository _repository = CampaignCommitmentRepository();
  late Future<CampaignCommitmentSummary?> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getActiveCampaignSummary();
  }

  void _reload() {
    setState(() {
      _future = _repository.getActiveCampaignSummary();
    });
  }

  Future<void> _syncCampaignProgress() async {
    await _repository.syncAutomaticProgress();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Campanha sincronizada com suas ações reais.')),
    );
    _reload();
  }

  Future<void> _toggleManualChapter(CampaignMilestone chapter) async {
    if (chapter.autoProgressEnabled && chapter.automationKey.trim().isNotEmpty) {
      return;
    }

    if (chapter.isCompleted) {
      await _repository.reopenMilestone(chapter.id);
    } else {
      await _repository.completeMilestone(chapter.id);
    }

    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CampaignCommitmentSummary?>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final summary = snapshot.data;
        final campaign = summary?.campaign;
        final chapters = summary?.milestones ?? const <CampaignMilestone>[];
        final currentChapter = _currentChapter(chapters);
        final title = campaign?.title ?? 'Transformação 20–25';
        final description = campaign?.description ??
            'Campanha principal de evolução pessoal do Game Life.';
        final progress = summary?.progressPercent ?? 0;

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _reload(),
            child: SingleChildScrollView(
              padding: GameSpacing.screen,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CampaignHeroCard(
                    title: title,
                    description: description,
                    progress: progress,
                    victoryStatus: summary?.victoryStatusLabel ?? 'Em campanha',
                    summary: summary,
                  ),
                  const SizedBox(height: GameSpacing.md),
                  GameSecondaryButton(
                    label: 'Sincronizar progresso automático',
                    icon: Icons.sync_rounded,
                    onPressed: summary == null ? null : _syncCampaignProgress,
                  ),
                  const SizedBox(height: GameSpacing.lg),
                  if (loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(GameSpacing.lg),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    _CurrentChapterCard(chapter: currentChapter),
                    const SizedBox(height: GameSpacing.lg),
                    _CampaignNarrativeCard(summary: summary),
                    const SizedBox(height: GameSpacing.lg),
                    _VictoryCriteriaCard(summary: summary),
                    const SizedBox(height: GameSpacing.lg),
                    _CampaignSignalsCard(signals: summary?.signals),
                    const SizedBox(height: GameSpacing.lg),
                    GameSectionHeader(
                      title: 'Mapa de capítulos',
                      subtitle: chapters.isEmpty
                          ? 'A campanha ainda não tem capítulos configurados.'
                          : '${summary?.completedMilestones ?? 0}/${summary?.totalMilestones ?? 0} capítulos concluídos.',
                      icon: Icons.auto_stories_rounded,
                    ),
                    const SizedBox(height: GameSpacing.sm),
                    if (chapters.isEmpty)
                      GameEmptyState(
                        icon: Icons.route_outlined,
                        title: 'Nenhum capítulo encontrado',
                        message:
                            'Use a configuração de campanha para criar capítulos e dividir sua jornada em fases reais.',
                      )
                    else
                      for (final chapter in chapters) ...[
                        _ChapterTimelineCard(
                          chapter: chapter,
                          onToggle: () => _toggleManualChapter(chapter),
                        ),
                        const SizedBox(height: GameSpacing.sm),
                      ],
                    const SizedBox(height: GameSpacing.lg),
                    _NextStepsCard(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CampaignHeroCard extends StatelessWidget {
  const _CampaignHeroCard({
    required this.title,
    required this.description,
    required this.progress,
    required this.victoryStatus,
    required this.summary,
  });

  final String title;
  final String description;
  final double progress;
  final String victoryStatus;
  final CampaignCommitmentSummary? summary;

  @override
  Widget build(BuildContext context) {
    return GameHighlightCard(
      accentColor: GameColors.faith,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: GameColors.faith.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: GameColors.faith,
                  size: 26,
                ),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GameTextStyles.title),
                    const SizedBox(height: GameSpacing.xs),
                    Text(description, style: GameTextStyles.body),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.md),
          GameProgressBar(value: progress, color: GameColors.faith, showGlow: true),
          const SizedBox(height: GameSpacing.xs),
          Text(
            '${(progress * 100).round()}% da campanha • $victoryStatus',
            style: GameTextStyles.caption,
          ),
          if (summary != null) ...[
            const SizedBox(height: GameSpacing.sm),
            Wrap(
              spacing: GameSpacing.xs,
              runSpacing: GameSpacing.xs,
              children: [
                GameChip(
                  label: _dateRange(summary!.startDate, summary!.endDate),
                  icon: Icons.event_rounded,
                  color: GameColors.info,
                  selected: true,
                ),
                GameChip(
                  label: _difficultyLabel(summary!.difficultyMode),
                  icon: Icons.local_fire_department_rounded,
                  color: _difficultyColor(summary!.difficultyMode),
                  selected: true,
                ),
                GameChip(
                  label: '${summary!.totalMilestones} capítulos',
                  icon: Icons.route_rounded,
                  color: GameColors.reward,
                  selected: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrentChapterCard extends StatelessWidget {
  const _CurrentChapterCard({required this.chapter});

  final CampaignMilestone? chapter;

  @override
  Widget build(BuildContext context) {
    final current = chapter;
    if (current == null) {
      return const GameCard(
        backgroundColor: GameColors.surfaceSoft,
        child: Text(
          'Nenhum capítulo ativo no momento. Crie capítulos para transformar a campanha em uma trilha cronológica.',
          style: GameTextStyles.body,
        ),
      );
    }

    final area = _areaOptionById(_validAreaId(current.primaryAreaId) ?? 'body_health');
    final progressPercent = (current.progress * 100).round();

    return GameCard(
      borderColor: area.color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: area.color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(area.icon, color: area.color, size: 22),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capítulo ativo', style: GameTextStyles.caption),
                    Text(current.title, style: GameTextStyles.cardTitle),
                  ],
                ),
              ),
              Text(
                '$progressPercent%',
                style: GameTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w900,
                  color: area.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: current.progress, color: area.color, showGlow: true),
          const SizedBox(height: GameSpacing.sm),
          Text(_chapterWindow(current), style: GameTextStyles.caption),
          if (current.description.trim().isNotEmpty) ...[
            const SizedBox(height: GameSpacing.sm),
            Text(current.description, style: GameTextStyles.body),
          ],
          const SizedBox(height: GameSpacing.sm),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              GameChip(
                label: 'Foco: ${area.label}',
                icon: area.icon,
                color: area.color,
                selected: true,
              ),
              if (current.autoProgressEnabled &&
                  current.automationKey.trim().isNotEmpty)
                const GameChip(
                  label: 'Automático',
                  icon: Icons.auto_awesome_rounded,
                  color: GameColors.info,
                  selected: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CampaignNarrativeCard extends StatelessWidget {
  const _CampaignNarrativeCard({required this.summary});

  final CampaignCommitmentSummary? summary;

  @override
  Widget build(BuildContext context) {
    final goal = (summary?.mainGoal ?? '').trim();
    final lore = (summary?.lore ?? '').trim();

    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: GameColors.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: GameColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(child: Text('Declaração da jornada', style: GameTextStyles.cardTitle)),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          Text(
            goal.isEmpty
                ? 'Defina um objetivo principal para que a campanha tenha um norte claro.'
                : goal,
            style: GameTextStyles.body,
          ),
          if (lore.isNotEmpty) ...[
            const SizedBox(height: GameSpacing.sm),
            GameCard(
              padding: const EdgeInsets.all(GameSpacing.sm),
              backgroundColor: GameColors.surfaceSoft,
              child: Text(lore, style: GameTextStyles.caption),
            ),
          ],
        ],
      ),
    );
  }
}

class _VictoryCriteriaCard extends StatelessWidget {
  const _VictoryCriteriaCard({required this.summary});

  final CampaignCommitmentSummary? summary;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: GameColors.reward.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: GameColors.reward,
                  size: 20,
                ),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(child: Text('Critérios de vitória', style: GameTextStyles.cardTitle)),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              GameChip(
                label: 'Mínima ${summary?.victoryMinimumPercent ?? 60}%',
                icon: Icons.shield_rounded,
                color: GameColors.info,
                selected: true,
              ),
              GameChip(
                label: 'Boa ${summary?.victoryGoodPercent ?? 75}%',
                icon: Icons.workspace_premium_rounded,
                color: GameColors.success,
                selected: true,
              ),
              GameChip(
                label: 'Excelente ${summary?.victoryExcellentPercent ?? 90}%',
                icon: Icons.auto_awesome_rounded,
                color: GameColors.reward,
                selected: true,
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          Text(
            'A vitória final é calculada pelo progresso real da campanha. O foco agora é tornar cada capítulo legível e confiável.',
            style: GameTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _CampaignSignalsCard extends StatelessWidget {
  const _CampaignSignalsCard({required this.signals});

  final CampaignProgressSignals? signals;

  @override
  Widget build(BuildContext context) {
    final data = signals;
    if (data == null) {
      return const GameCard(
        backgroundColor: GameColors.surfaceSoft,
        child: Text('Sinais da campanha ainda não carregados.', style: GameTextStyles.caption),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GameSectionHeader(
          title: 'Sinais que alimentam a campanha',
          subtitle: 'A campanha evolui lendo suas ações reais registradas no app.',
          icon: Icons.auto_graph_rounded,
        ),
        const SizedBox(height: GameSpacing.sm),
        Wrap(
          spacing: GameSpacing.xs,
          runSpacing: GameSpacing.xs,
          children: [
            GameChip(label: '${data.missionsCompleted} missões', icon: Icons.flag_rounded, color: GameColors.primary, selected: true),
            GameChip(label: '${data.habitRewards} hábitos', icon: Icons.repeat_rounded, color: GameColors.vigor, selected: true),
            GameChip(label: '${data.waterDays} dias com água', icon: Icons.water_drop_rounded, color: GameColors.info, selected: true),
            GameChip(label: '${data.focusHours}h foco', icon: Icons.timer_rounded, color: GameColors.success, selected: true),
            GameChip(label: '${data.objectivesCompleted} objetivos', icon: Icons.track_changes_rounded, color: GameColors.clarity, selected: true),
            GameChip(label: '${data.projectTasksCompleted} tarefas', icon: Icons.checklist_rounded, color: GameColors.reward, selected: true),
            GameChip(label: '${data.achievementsUnlocked} conquistas', icon: Icons.emoji_events_rounded, color: GameColors.reward, selected: true),
            GameChip(label: '${data.totalAreaXp} XP em áreas', icon: Icons.hub_rounded, color: GameColors.faith, selected: true),
            GameChip(label: 'R\$ ${data.vaultSaved}', icon: Icons.savings_rounded, color: GameColors.responsibility, selected: true),
          ],
        ),
      ],
    );
  }
}

class _ChapterTimelineCard extends StatelessWidget {
  const _ChapterTimelineCard({required this.chapter, required this.onToggle});

  final CampaignMilestone chapter;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final area = _areaOptionById(_validAreaId(chapter.primaryAreaId) ?? 'body_health');
    final color = chapter.isCompleted ? GameColors.success : area.color;
    final percent = (chapter.progress * 100).round();
    final isAutomatic = chapter.autoProgressEnabled && chapter.automationKey.trim().isNotEmpty;

    return GameCard(
      padding: const EdgeInsets.all(GameSpacing.md),
      borderColor: color.withValues(alpha: chapter.isCompleted ? 0.55 : 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  chapter.isCompleted ? Icons.verified_rounded : area.icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chapter.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(_chapterMeta(chapter), style: GameTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(width: GameSpacing.xs),
              Text(
                '$percent%',
                style: GameTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: chapter.progress, color: color, showGlow: chapter.isCompleted),
          if (chapter.description.trim().isNotEmpty) ...[
            const SizedBox(height: GameSpacing.sm),
            Text(chapter.description, style: GameTextStyles.body),
          ],
          if (chapter.progressNote.trim().isNotEmpty) ...[
            const SizedBox(height: GameSpacing.sm),
            GameCard(
              padding: const EdgeInsets.all(GameSpacing.sm),
              backgroundColor: GameColors.surfaceSoft,
              child: Text(chapter.progressNote, style: GameTextStyles.caption),
            ),
          ],
          const SizedBox(height: GameSpacing.sm),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              GameChip(label: 'Foco: ${area.label}', icon: area.icon, color: area.color, selected: true),
              if (chapter.secondaryAreaIdList.isNotEmpty)
                GameChip(
                  label: 'Apoio: ${_areaListLabel(chapter.secondaryAreaIdList)}',
                  icon: Icons.account_tree_rounded,
                  color: GameColors.info,
                  selected: true,
                ),
              if (isAutomatic)
                const GameChip(label: 'Automático', icon: Icons.auto_awesome_rounded, color: GameColors.info, selected: true),
              GameChip(
                label: chapter.isCompleted ? 'Concluído' : 'Ativo',
                icon: chapter.isCompleted ? Icons.check_rounded : Icons.hourglass_bottom_rounded,
                color: color,
                selected: true,
              ),
            ],
          ),
          if (!isAutomatic) ...[
            const SizedBox(height: GameSpacing.sm),
            GameSecondaryButton(
              label: chapter.isCompleted ? 'Reabrir capítulo' : 'Concluir capítulo',
              icon: chapter.isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded,
              onPressed: onToggle,
            ),
          ],
        ],
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const GameCard(
      backgroundColor: GameColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Próximos avanços planejados', style: GameTextStyles.cardTitle),
          SizedBox(height: GameSpacing.xs),
          Text(
            'Esta versão organiza a campanha como uma trilha narrativa de capítulos. O próximo passo é ligar objetivos específicos aos capítulos sem mexer pesado no banco de uma vez.',
            style: GameTextStyles.body,
          ),
        ],
      ),
    );
  }
}

CampaignMilestone? _currentChapter(List<CampaignMilestone> chapters) {
  if (chapters.isEmpty) return null;
  for (final chapter in chapters) {
    if (!chapter.isCompleted) return chapter;
  }
  return chapters.last;
}

String _dateText(String value) {
  final text = value.trim();
  if (text.isEmpty) return 'Não definido';
  if (text.length >= 10) return text.substring(0, 10);
  return text;
}

String _dateRange(String start, String end) {
  return '${_dateText(start)} → ${_dateText(end)}';
}

String _difficultyLabel(String value) {
  return switch (value) {
    'hard' => 'Difícil',
    'hardcore' => 'Hardcore',
    _ => 'Normal',
  };
}

Color _difficultyColor(String value) {
  return switch (value) {
    'hard' => GameColors.warning,
    'hardcore' => GameColors.danger,
    _ => GameColors.success,
  };
}

String? _validAreaId(String? value) {
  final id = value?.trim() ?? '';
  if (id.isEmpty) return null;
  for (final area in _chapterAreaOptions) {
    if (area.id == id) return id;
  }
  return null;
}

_ChapterAreaOption _areaOptionById(String areaId) {
  return _chapterAreaOptions.firstWhere(
    (area) => area.id == areaId,
    orElse: () => _chapterAreaOptions.first,
  );
}

String _areaLabel(String areaId) {
  return _areaOptionById(_validAreaId(areaId) ?? 'body_health').label;
}

String _areaListLabel(List<String> ids) {
  if (ids.isEmpty) return 'Nenhuma';
  return ids.map(_areaLabel).join(', ');
}

String _chapterWindow(CampaignMilestone chapter) {
  final start = _dateText(chapter.startDate);
  final end = _dateText(chapter.endDate.isNotEmpty ? chapter.endDate : chapter.targetDate);
  return '$start até $end';
}

String _chapterMeta(CampaignMilestone chapter) {
  final primary = chapter.primaryAreaId.trim().isEmpty
      ? 'Área não definida'
      : _areaLabel(chapter.primaryAreaId);
  return 'Capítulo ${chapter.sortOrder} • ${_chapterWindow(chapter)} • Foco: $primary';
}
