import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/v3_commitment_models.dart';
import '../../core/repositories/campaign_commitment_repository.dart';
import '../../design_system/game_design_system.dart';


const List<_ChapterAreaOption> _chapterAreaOptions = [
  _ChapterAreaOption(id: 'body_health', label: 'Corpo e Saúde', icon: Icons.fitness_center_rounded, color: GameColors.vigor),
  _ChapterAreaOption(id: 'mind_knowledge', label: 'Mente e Conhecimento', icon: Icons.menu_book_rounded, color: GameColors.clarity),
  _ChapterAreaOption(id: 'spirit_purpose', label: 'Fé e Propósito', icon: Icons.auto_awesome_rounded, color: GameColors.faith),
  _ChapterAreaOption(id: 'projects_career', label: 'Carreira e Projetos', icon: Icons.work_rounded, color: GameColors.reward),
  _ChapterAreaOption(id: 'creation_expression', label: 'Criação e Expressão', icon: Icons.brush_rounded, color: GameColors.primary),
  _ChapterAreaOption(id: 'finance_responsibility', label: 'Finanças e Reino', icon: Icons.savings_rounded, color: GameColors.responsibility),
  _ChapterAreaOption(id: 'routine_order', label: 'Rotina e Ordem', icon: Icons.checklist_rounded, color: GameColors.discipline),
];

class _ChapterAreaOption {
  const _ChapterAreaOption({required this.id, required this.label, required this.icon, required this.color});

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
  late Future<CampaignCommitmentSummary> _future;

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

  Future<void> _openCampaignEditor(CampaignCommitmentSummary summary) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CampaignEditScreen(summary: summary)),
    );
    if (updated == true && mounted) _reload();
  }

  Future<void> _openMilestoneEditor({
    required String campaignId,
    CampaignMilestone? milestone,
    required int nextOrder,
  }) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MilestoneFormScreen(
          campaignId: campaignId,
          milestone: milestone,
          nextOrder: nextOrder,
        ),
      ),
    );
    if (updated == true && mounted) _reload();
  }

  Future<void> _toggleMilestone(CampaignMilestone milestone) async {
    if (milestone.isCompleted) {
      await _repository.reopenMilestone(milestone.id);
    } else {
      await _repository.completeMilestone(milestone.id);
    }
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CampaignCommitmentSummary>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final summary = snapshot.data;
        final campaign = summary?.campaign;
        final title = campaign?.title ?? 'Transformação 20–25';
        final description = campaign?.description ?? 'Campanha principal de evolução pessoal do Game Life.';
        final campaignId = campaign?.id ?? 'transformation_20_25';
        final progress = summary?.progressPercent ?? 0;
        final milestones = summary?.milestones ?? const <CampaignMilestone>[];

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _reload(),
            child: SingleChildScrollView(
              padding: GameSpacing.screen,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GameHighlightCard(
                    accentColor: GameColors.faith,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: GameColors.faith, size: 34),
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
                          '${(progress * 100).round()}% da campanha • ${summary?.victoryStatusLabel ?? 'Em campanha'}',
                          style: GameTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GameSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: GamePrimaryButton(
                          label: 'Editar campanha',
                          icon: Icons.edit_rounded,
                          onPressed: summary == null ? null : () => _openCampaignEditor(summary),
                        ),
                      ),
                      const SizedBox(width: GameSpacing.sm),
                      Expanded(
                        child: GameSecondaryButton(
                          label: 'Novo capítulo',
                          icon: Icons.library_books_rounded,
                          onPressed: summary == null
                              ? null
                              : () => _openMilestoneEditor(
                                    campaignId: campaignId,
                                    nextOrder: milestones.length + 1,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GameSpacing.sm),
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
                    _CampaignInfoGrid(summary: summary),
                    const SizedBox(height: GameSpacing.lg),
                    _CampaignSignalsCard(signals: summary?.signals),
                    const SizedBox(height: GameSpacing.lg),
                    _VictoryCriteriaCard(summary: summary),
                    const SizedBox(height: GameSpacing.lg),
                    GameSectionHeader(
                      title: 'Capítulos da campanha',
                      subtitle: milestones.isEmpty
                          ? 'Crie capítulos para transformar a campanha em uma história concreta, com período, área foco e progresso automático.'
                          : '${summary?.completedMilestones ?? 0}/${summary?.totalMilestones ?? 0} capítulos concluídos.',
                      icon: Icons.auto_stories_rounded,
                    ),
                    const SizedBox(height: GameSpacing.sm),
                    if (milestones.isEmpty)
                      GameEmptyState(
                        icon: Icons.route_outlined,
                        title: 'Nenhum capítulo criado',
                        message: 'Adicione capítulos para dividir a campanha em fases como corpo, programação, fé, finanças e consolidação.',
                        actionLabel: 'Criar capítulo',
                        onAction: () => _openMilestoneEditor(campaignId: campaignId, nextOrder: 1),
                      )
                    else
                      for (final milestone in milestones) ...[
                        _MilestoneCard(
                          milestone: milestone,
                          onEdit: () => _openMilestoneEditor(
                            campaignId: campaignId,
                            milestone: milestone,
                            nextOrder: milestones.length + 1,
                          ),
                          onToggle: () => _toggleMilestone(milestone),
                        ),
                        const SizedBox(height: GameSpacing.sm),
                      ],
                    const SizedBox(height: GameSpacing.lg),
                    GameCard(
                      backgroundColor: GameColors.surfaceSoft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Próximos avanços', style: GameTextStyles.cardTitle),
                          const SizedBox(height: GameSpacing.xs),
                          Text(
                            'Os capítulos padrão evoluem automaticamente a partir das áreas, missões, hábitos, saúde, sessões, objetivos, projetos, conquistas, atributos, cofre e loja. Capítulos criados por você continuam manuais por enquanto.',
                            style: GameTextStyles.body,
                          ),
                        ],
                      ),
                    ),
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

class _CampaignInfoGrid extends StatelessWidget {
  const _CampaignInfoGrid({required this.summary});

  final CampaignCommitmentSummary? summary;

  @override
  Widget build(BuildContext context) {
    final start = _dateText(summary?.startDate ?? '');
    final end = _dateText(summary?.endDate ?? '');
    final difficulty = _difficultyLabel(summary?.difficultyMode ?? 'normal');
    final goal = (summary?.mainGoal ?? '').trim();
    final lore = (summary?.lore ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GameSectionHeader(
          title: 'Configuração da campanha',
          subtitle: 'Base estratégica da jornada atual.',
          icon: Icons.tune_rounded,
        ),
        const SizedBox(height: GameSpacing.sm),
        Row(
          children: [
            Expanded(child: GameStatTile(label: 'Início', value: start, icon: Icons.play_arrow_rounded, color: GameColors.success)),
            const SizedBox(width: GameSpacing.sm),
            Expanded(child: GameStatTile(label: 'Fim', value: end, icon: Icons.flag_circle_rounded, color: GameColors.reward)),
          ],
        ),
        const SizedBox(height: GameSpacing.sm),
        GameStatTile(label: 'Dificuldade', value: difficulty, icon: Icons.local_fire_department_rounded, color: _difficultyColor(summary?.difficultyMode ?? 'normal')),
        if (goal.isNotEmpty) ...[
          const SizedBox(height: GameSpacing.sm),
          GameCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Objetivo principal', style: GameTextStyles.cardTitle),
                const SizedBox(height: GameSpacing.xs),
                Text(goal, style: GameTextStyles.body),
              ],
            ),
          ),
        ],
        if (lore.isNotEmpty) ...[
          const SizedBox(height: GameSpacing.sm),
          GameCard(
            backgroundColor: GameColors.surfaceSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lore curta', style: GameTextStyles.cardTitle),
                const SizedBox(height: GameSpacing.xs),
                Text(lore, style: GameTextStyles.body),
              ],
            ),
          ),
        ],
      ],
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
          title: 'Sinais da campanha',
          subtitle: 'A campanha lê estes dados para calcular os capítulos automáticos.',
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
                child: const Icon(Icons.emoji_events_rounded, color: GameColors.reward, size: 20),
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
              GameChip(label: 'Mínima ${summary?.victoryMinimumPercent ?? 60}%', icon: Icons.shield_rounded, color: GameColors.info, selected: true),
              GameChip(label: 'Boa ${summary?.victoryGoodPercent ?? 75}%', icon: Icons.workspace_premium_rounded, color: GameColors.success, selected: true),
              GameChip(label: 'Excelente ${summary?.victoryExcellentPercent ?? 90}%', icon: Icons.auto_awesome_rounded, color: GameColors.reward, selected: true),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          Text(
            'Esses percentuais serão usados para avaliar o resultado final da campanha quando a lógica de encerramento amadurecer.',
            style: GameTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.milestone,
    required this.onEdit,
    required this.onToggle,
  });

  final CampaignMilestone milestone;
  final VoidCallback onEdit;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final color = milestone.isCompleted ? GameColors.success : GameColors.faith;
    final percent = (milestone.progress * 100).round();
    final isAutomatic = milestone.autoProgressEnabled && milestone.automationKey.trim().isNotEmpty;

    return GameCard(
      padding: const EdgeInsets.all(GameSpacing.md),
      borderColor: color.withValues(alpha: milestone.isCompleted ? 0.55 : 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(milestone.isCompleted ? Icons.verified_rounded : Icons.route_rounded, color: color, size: 22),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(milestone.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(_milestoneMeta(milestone), style: GameTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(width: GameSpacing.xs),
              Text('$percent%', style: GameTextStyles.caption.copyWith(fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: milestone.progress, color: color, showGlow: milestone.isCompleted),
          if (milestone.primaryAreaId.trim().isNotEmpty || milestone.secondaryAreaIdList.isNotEmpty) ...[
            const SizedBox(height: GameSpacing.sm),
            Wrap(
              spacing: GameSpacing.xs,
              runSpacing: GameSpacing.xs,
              children: [
                if (milestone.primaryAreaId.trim().isNotEmpty)
                  GameChip(
                    label: 'Foco: ${_areaLabel(milestone.primaryAreaId)}',
                    icon: Icons.hub_rounded,
                    color: GameColors.faith,
                    selected: true,
                  ),
                if (milestone.secondaryAreaIdList.isNotEmpty)
                  GameChip(
                    label: 'Apoio: ${_areaListLabel(milestone.secondaryAreaIdList)}',
                    icon: Icons.account_tree_rounded,
                    color: GameColors.info,
                    selected: true,
                  ),
              ],
            ),
          ],
          if (milestone.description.trim().isNotEmpty) ...[
            const SizedBox(height: GameSpacing.sm),
            Text(milestone.description, style: GameTextStyles.body),
          ],
          if (milestone.lore.trim().isNotEmpty) ...[
            const SizedBox(height: GameSpacing.sm),
            GameCard(
              padding: const EdgeInsets.all(GameSpacing.sm),
              backgroundColor: GameColors.surfaceSoft,
              child: Text(milestone.lore, style: GameTextStyles.caption),
            ),
          ],
          if (milestone.progressNote.trim().isNotEmpty) ...[
            const SizedBox(height: GameSpacing.sm),
            GameCard(
              padding: const EdgeInsets.all(GameSpacing.sm),
              backgroundColor: GameColors.surfaceSoft,
              child: Text(milestone.progressNote, style: GameTextStyles.caption),
            ),
          ],
          const SizedBox(height: GameSpacing.sm),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              if (isAutomatic)
                const GameChip(label: 'Automático', icon: Icons.auto_awesome_rounded, color: GameColors.info, selected: true),
              GameChip(label: '+${milestone.xpReward} XP', icon: Icons.bolt_rounded, color: GameColors.info, selected: milestone.xpReward > 0),
              GameChip(label: '+${milestone.coinsReward} coins', icon: Icons.monetization_on_rounded, color: GameColors.reward, selected: milestone.coinsReward > 0),
              GameChip(label: milestone.isCompleted ? 'Concluído' : 'Ativo', icon: milestone.isCompleted ? Icons.check_rounded : Icons.hourglass_bottom_rounded, color: color, selected: true),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          Row(
            children: [
              Expanded(child: GameSecondaryButton(label: 'Editar', icon: Icons.edit_rounded, onPressed: onEdit)),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: GamePrimaryButton(
                  label: isAutomatic ? 'Auto' : (milestone.isCompleted ? 'Reabrir' : 'Concluir'),
                  icon: isAutomatic ? Icons.sync_rounded : (milestone.isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded),
                  onPressed: isAutomatic ? null : onToggle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CampaignEditScreen extends StatefulWidget {
  const CampaignEditScreen({super.key, required this.summary});

  final CampaignCommitmentSummary summary;

  @override
  State<CampaignEditScreen> createState() => _CampaignEditScreenState();
}

class _CampaignEditScreenState extends State<CampaignEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = CampaignCommitmentRepository();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _loreController;
  late final TextEditingController _mainGoalController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _minimumController;
  late final TextEditingController _goodController;
  late final TextEditingController _excellentController;
  late String _difficultyMode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final campaign = widget.summary.campaign;
    _titleController = TextEditingController(text: campaign?.title ?? 'Transformação 20–25');
    _descriptionController = TextEditingController(text: campaign?.description ?? '');
    _loreController = TextEditingController(text: widget.summary.lore);
    _mainGoalController = TextEditingController(text: widget.summary.mainGoal);
    _startDateController = TextEditingController(text: _dateInput(widget.summary.startDate));
    _endDateController = TextEditingController(text: _dateInput(widget.summary.endDate));
    _minimumController = TextEditingController(text: '${widget.summary.victoryMinimumPercent}');
    _goodController = TextEditingController(text: '${widget.summary.victoryGoodPercent}');
    _excellentController = TextEditingController(text: '${widget.summary.victoryExcellentPercent}');
    _difficultyMode = widget.summary.difficultyMode;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _loreController.dispose();
    _mainGoalController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _minimumController.dispose();
    _goodController.dispose();
    _excellentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final minimum = _readPercent(_minimumController.text, fallback: 60);
    final good = _readPercent(_goodController.text, fallback: 75);
    final excellent = _readPercent(_excellentController.text, fallback: 90);

    try {
      await _repository.updateCampaign(
        UpdateCampaignCommitmentInput(
          campaignId: widget.summary.campaign?.id ?? 'transformation_20_25',
          title: _titleController.text,
          description: _descriptionController.text,
          lore: _loreController.text,
          mainGoal: _mainGoalController.text,
          startDate: _startDateController.text,
          endDate: _endDateController.text,
          difficultyMode: _difficultyMode,
          victoryMinimumPercent: minimum,
          victoryGoodPercent: good,
          victoryExcellentPercent: excellent,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar a campanha: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar campanha')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: GameSpacing.screen,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const GameSectionHeader(
                  title: 'Identidade da campanha',
                  subtitle: 'Defina o sentido principal desta fase da sua vida.',
                  icon: Icons.auto_awesome_rounded,
                ),
                const SizedBox(height: GameSpacing.sm),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Título', 'Ex.: Transformação 20–25', Icons.title_rounded),
                  validator: (value) => (value?.trim().isEmpty ?? true) ? 'Informe um título.' : null,
                ),
                const SizedBox(height: GameSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration('Descrição', 'Resumo direto da campanha.', Icons.notes_rounded),
                ),
                const SizedBox(height: GameSpacing.sm),
                TextFormField(
                  controller: _mainGoalController,
                  maxLines: 3,
                  decoration: _inputDecoration('Objetivo principal', 'Qual resultado real esta campanha busca?', Icons.flag_circle_rounded),
                ),
                const SizedBox(height: GameSpacing.sm),
                TextFormField(
                  controller: _loreController,
                  maxLines: 4,
                  decoration: _inputDecoration('Lore curta opcional', 'Texto simbólico para dar peso à jornada.', Icons.menu_book_rounded),
                ),
                const SizedBox(height: GameSpacing.lg),
                const GameSectionHeader(
                  title: 'Período e dificuldade',
                  subtitle: 'Configure o ritmo geral da campanha.',
                  icon: Icons.event_rounded,
                ),
                const SizedBox(height: GameSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDateController,
                        decoration: _inputDecoration('Início', 'AAAA-MM-DD', Icons.play_arrow_rounded),
                      ),
                    ),
                    const SizedBox(width: GameSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _endDateController,
                        decoration: _inputDecoration('Fim', 'AAAA-MM-DD', Icons.flag_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GameSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _difficultyMode,
                  decoration: _inputDecoration('Dificuldade', null, Icons.local_fire_department_rounded),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'hard', child: Text('Difícil')),
                    DropdownMenuItem(value: 'hardcore', child: Text('Hardcore')),
                  ],
                  onChanged: (value) => setState(() => _difficultyMode = value ?? 'normal'),
                ),
                const SizedBox(height: GameSpacing.lg),
                const GameSectionHeader(
                  title: 'Critérios de vitória',
                  subtitle: 'Percentuais usados para avaliar o resultado final da campanha.',
                  icon: Icons.emoji_events_rounded,
                ),
                const SizedBox(height: GameSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _PercentField(controller: _minimumController, label: 'Mínima')),
                    const SizedBox(width: GameSpacing.sm),
                    Expanded(child: _PercentField(controller: _goodController, label: 'Boa')),
                    const SizedBox(width: GameSpacing.sm),
                    Expanded(child: _PercentField(controller: _excellentController, label: 'Excelente')),
                  ],
                ),
                const SizedBox(height: GameSpacing.lg),
                GamePrimaryButton(label: _saving ? 'Salvando...' : 'Salvar campanha', icon: Icons.save_rounded, onPressed: _saving ? null : _save),
                const SizedBox(height: GameSpacing.sm),
                GameSecondaryButton(label: 'Cancelar', icon: Icons.close_rounded, onPressed: _saving ? null : () => Navigator.of(context).pop(false)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PercentField extends StatelessWidget {
  const _PercentField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _inputDecoration(label, '%', Icons.percent_rounded),
      validator: (value) {
        final number = int.tryParse(value ?? '');
        if (number == null) return '0-100';
        if (number < 0 || number > 100) return '0-100';
        return null;
      },
    );
  }
}


class MilestoneFormScreen extends StatefulWidget {
  const MilestoneFormScreen({
    super.key,
    required this.campaignId,
    required this.nextOrder,
    this.milestone,
  });

  final String campaignId;
  final int nextOrder;
  final CampaignMilestone? milestone;

  @override
  State<MilestoneFormScreen> createState() => _MilestoneFormScreenState();
}

class _MilestoneFormScreenState extends State<MilestoneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = CampaignCommitmentRepository();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _loreController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _targetDateController;
  late final TextEditingController _sortOrderController;
  late final TextEditingController _xpController;
  late final TextEditingController _coinsController;
  late double _progress;
  late String _primaryAreaId;
  late List<String> _secondaryAreaIds;
  bool _saving = false;

  bool get _editing => widget.milestone != null;

  @override
  void initState() {
    super.initState();
    final milestone = widget.milestone;
    _titleController = TextEditingController(text: milestone?.title ?? '');
    _descriptionController = TextEditingController(text: milestone?.description ?? '');
    _loreController = TextEditingController(text: milestone?.lore ?? '');
    _startDateController = TextEditingController(text: _dateInput(milestone?.startDate ?? ''));
    _endDateController = TextEditingController(text: _dateInput(milestone?.endDate ?? ''));
    _targetDateController = TextEditingController(text: _dateInput(milestone?.targetDate ?? milestone?.endDate ?? ''));
    _sortOrderController = TextEditingController(text: '${milestone?.sortOrder ?? widget.nextOrder}');
    _xpController = TextEditingController(text: '${milestone?.xpReward ?? 100}');
    _coinsController = TextEditingController(text: '${milestone?.coinsReward ?? 25}');
    _progress = milestone?.progress ?? 0;
    _primaryAreaId = _validAreaId(milestone?.primaryAreaId) ?? 'body_health';
    _secondaryAreaIds = (milestone?.secondaryAreaIdList ?? const <String>[])
        .where((id) => _validAreaId(id) != null && id != _primaryAreaId)
        .toList(growable: true);
  }

  bool get _isAutomaticMilestone => widget.milestone?.autoProgressEnabled == true && (widget.milestone?.automationKey.trim().isNotEmpty ?? false);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _loreController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _targetDateController.dispose();
    _sortOrderController.dispose();
    _xpController.dispose();
    _coinsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final secondaryIds = _secondaryAreaIds.where((id) => id != _primaryAreaId).join(',');

    try {
      if (_editing) {
        await _repository.updateMilestone(
          UpdateCampaignMilestoneInput(
            milestoneId: widget.milestone!.id,
            title: _titleController.text,
            description: _descriptionController.text,
            lore: _loreController.text,
            targetDate: _targetDateController.text,
            startDate: _startDateController.text,
            endDate: _endDateController.text,
            primaryAreaId: _primaryAreaId,
            secondaryAreaIds: secondaryIds,
            sortOrder: int.tryParse(_sortOrderController.text) ?? widget.nextOrder,
            progress: _progress,
            xpReward: int.tryParse(_xpController.text) ?? 0,
            coinsReward: int.tryParse(_coinsController.text) ?? 0,
          ),
        );
      } else {
        await _repository.createMilestone(
          CreateCampaignMilestoneInput(
            campaignId: widget.campaignId,
            title: _titleController.text,
            description: _descriptionController.text,
            lore: _loreController.text,
            targetDate: _targetDateController.text,
            startDate: _startDateController.text,
            endDate: _endDateController.text,
            primaryAreaId: _primaryAreaId,
            secondaryAreaIds: secondaryIds,
            sortOrder: int.tryParse(_sortOrderController.text) ?? widget.nextOrder,
            xpReward: int.tryParse(_xpController.text) ?? 0,
            coinsReward: int.tryParse(_coinsController.text) ?? 0,
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o capítulo: $error')),
      );
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir capítulo?'),
        content: const Text('Essa ação remove o capítulo da campanha localmente.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmed != true) return;
    await _repository.deleteMilestone(widget.milestone!.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _toggleSecondaryArea(String areaId) {
    if (areaId == _primaryAreaId) return;
    setState(() {
      if (_secondaryAreaIds.contains(areaId)) {
        _secondaryAreaIds.remove(areaId);
      } else {
        _secondaryAreaIds.add(areaId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryOption = _areaOptionById(_primaryAreaId);

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Editar capítulo' : 'Novo capítulo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: GameSpacing.screen,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameSectionHeader(
                  title: _editing ? 'Detalhes do capítulo' : 'Criar capítulo',
                  subtitle: 'Defina período, área principal e áreas de apoio para este trecho da campanha.',
                  icon: Icons.auto_stories_rounded,
                ),
                const SizedBox(height: GameSpacing.sm),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Título', 'Ex.: Capítulo 1 — Corpo em movimento', Icons.title_rounded),
                  validator: (value) => (value?.trim().isEmpty ?? true) ? 'Informe um título.' : null,
                ),
                const SizedBox(height: GameSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration('Descrição', 'O que precisa acontecer neste capítulo?', Icons.notes_rounded),
                ),
                const SizedBox(height: GameSpacing.sm),
                TextFormField(
                  controller: _loreController,
                  maxLines: 3,
                  decoration: _inputDecoration('Lore curta opcional', 'Texto simbólico para este capítulo.', Icons.menu_book_rounded),
                ),
                const SizedBox(height: GameSpacing.lg),
                const GameSectionHeader(
                  title: 'Período do capítulo',
                  subtitle: 'Datas ajudam a campanha a virar uma trilha cronológica.',
                  icon: Icons.event_rounded,
                ),
                const SizedBox(height: GameSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDateController,
                        decoration: _inputDecoration('Início', 'AAAA-MM-DD', Icons.play_arrow_rounded),
                      ),
                    ),
                    const SizedBox(width: GameSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _endDateController,
                        decoration: _inputDecoration('Fim', 'AAAA-MM-DD', Icons.flag_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GameSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _targetDateController,
                        decoration: _inputDecoration('Data alvo', 'Normalmente igual ao fim', Icons.event_available_rounded),
                      ),
                    ),
                    const SizedBox(width: GameSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _sortOrderController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _inputDecoration('Ordem', null, Icons.sort_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GameSpacing.lg),
                const GameSectionHeader(
                  title: 'Áreas do capítulo',
                  subtitle: 'A área principal pesa mais no progresso automático. As secundárias entram como apoio.',
                  icon: Icons.hub_rounded,
                ),
                const SizedBox(height: GameSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _primaryAreaId,
                  decoration: _inputDecoration('Área principal', null, primaryOption.icon),
                  items: [
                    for (final area in _chapterAreaOptions)
                      DropdownMenuItem(value: area.id, child: Text(area.label)),
                  ],
                  onChanged: (value) {
                    final safe = _validAreaId(value) ?? 'body_health';
                    setState(() {
                      _primaryAreaId = safe;
                      _secondaryAreaIds.remove(safe);
                    });
                  },
                ),
                const SizedBox(height: GameSpacing.sm),
                Wrap(
                  spacing: GameSpacing.xs,
                  runSpacing: GameSpacing.xs,
                  children: [
                    for (final area in _chapterAreaOptions)
                      if (area.id != _primaryAreaId)
                        ChoiceChip(
                          selected: _secondaryAreaIds.contains(area.id),
                          avatar: Icon(area.icon, size: 18, color: area.color),
                          label: Text(area.label),
                          onSelected: (_) => _toggleSecondaryArea(area.id),
                        ),
                  ],
                ),
                const SizedBox(height: GameSpacing.sm),
                GameCard(
                  backgroundColor: GameColors.surfaceSoft,
                  child: Text(
                    'Progresso automático: 55% vem das áreas do capítulo e 45% dos sinais gerais vinculados ao tipo de capítulo.',
                    style: GameTextStyles.caption,
                  ),
                ),
                const SizedBox(height: GameSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _xpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _inputDecoration('XP', null, Icons.bolt_rounded),
                      ),
                    ),
                    const SizedBox(width: GameSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _coinsController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _inputDecoration('Coins', null, Icons.monetization_on_rounded),
                      ),
                    ),
                  ],
                ),
                if (_editing) ...[
                  const SizedBox(height: GameSpacing.lg),
                  GameCard(
                    backgroundColor: GameColors.surfaceSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Progresso do capítulo: ${(_progress * 100).round()}%', style: GameTextStyles.cardTitle),
                        if (_isAutomaticMilestone) ...[
                          const Text(
                            'Este capítulo é automático. O progresso é calculado por áreas, ações reais e sinais registrados no app.',
                            style: GameTextStyles.caption,
                          ),
                          const SizedBox(height: GameSpacing.sm),
                        ] else
                          Slider(
                            value: _progress,
                            divisions: 20,
                            label: '${(_progress * 100).round()}%',
                            onChanged: (value) => setState(() => _progress = value),
                          ),
                        GameProgressBar(value: _progress, color: _progress >= 1 ? GameColors.success : GameColors.faith),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: GameSpacing.lg),
                GamePrimaryButton(label: _saving ? 'Salvando...' : 'Salvar capítulo', icon: Icons.save_rounded, onPressed: _saving ? null : _save),
                const SizedBox(height: GameSpacing.sm),
                GameSecondaryButton(label: 'Cancelar', icon: Icons.close_rounded, onPressed: _saving ? null : () => Navigator.of(context).pop(false)),
                if (_editing && !_isAutomaticMilestone) ...[
                  const SizedBox(height: GameSpacing.sm),
                  GameDangerButton(label: 'Excluir capítulo', icon: Icons.delete_rounded, onPressed: _saving ? null : _delete),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label, String? hint, IconData icon) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon),
  );
}

String _dateInput(String value) {
  final text = value.trim();
  if (text.length >= 10) return text.substring(0, 10);
  return text;
}

String _dateText(String value) {
  final text = _dateInput(value);
  if (text.isEmpty) return 'Não definido';
  return text;
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

String _milestoneMeta(CampaignMilestone milestone) {
  final start = _dateText(milestone.startDate);
  final end = _dateText(milestone.endDate.isNotEmpty ? milestone.endDate : milestone.targetDate);
  final primary = milestone.primaryAreaId.trim().isEmpty ? 'Área não definida' : _areaLabel(milestone.primaryAreaId);
  return 'Capítulo ${milestone.sortOrder} • $start até $end • Foco: $primary';
}

int _readPercent(String value, {required int fallback}) {
  final parsed = int.tryParse(value.trim()) ?? fallback;
  if (parsed < 0) return 0;
  if (parsed > 100) return 100;
  return parsed;
}
