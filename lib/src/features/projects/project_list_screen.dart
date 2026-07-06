import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/project_repository.dart';
import '../../design_system/game_design_system.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final ProjectRepository _repository = ProjectRepository();

  List<Project> _projects = const [];
  bool _loading = true;
  String? _error;
  String? _workingProjectId;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final projects = await _repository.getActiveProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openCreateProject() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
    );

    if (created == true && mounted) {
      await _loadProjects();
    }
  }

  Future<void> _openProject(Project project) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: project.id)),
    );

    if (mounted) await _loadProjects();
  }

  Future<void> _archiveProject(Project project) async {
    if (_workingProjectId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Arquivar projeto?'),
          content: Text('O projeto "${project.title}" vai sair da lista principal.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Arquivar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _workingProjectId = project.id);

    try {
      await _repository.archiveProject(project.id);
      if (mounted) await _loadProjects();
    } catch (error) {
      _showMessage('Erro ao arquivar projeto: $error');
    } finally {
      if (mounted) setState(() => _workingProjectId = null);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(child: _buildBody());

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projetos ativos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loadProjects,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Novo projeto',
            onPressed: _openCreateProject,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateProject,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo'),
      ),
      body: body,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ProjectScrollPage(
        children: [
          GameEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Erro ao carregar projetos',
            message: error,
            actionLabel: 'Tentar novamente',
            onAction: _loadProjects,
          ),
        ],
      );
    }

    if (_projects.isEmpty) {
      return _ProjectScrollPage(
        children: [
          const _ProjectHeroCard(
            title: 'Projetos',
            subtitle: 'Organize apps, estudos, finanças, criação de conteúdo e grandes metas em tarefas concretas.',
            icon: Icons.folder_special_rounded,
          ),
          const SizedBox(height: GameSpacing.md),
          GameEmptyState(
            icon: Icons.folder_open_rounded,
            title: 'Nenhum projeto ativo',
            message: 'Crie um projeto para acompanhar progresso, tarefas, recompensa e conclusão.',
            actionLabel: 'Criar primeiro projeto',
            onAction: _openCreateProject,
          ),
        ],
      );
    }

    final active = _projects.where((project) => project.status == 'active').length;
    final paused = _projects.where((project) => project.status == 'paused').length;
    final taskCount = _projects.fold<int>(0, (total, project) => total + project.taskCount);
    final doneTaskCount = _projects.fold<int>(0, (total, project) => total + project.doneTaskCount);

    return _ProjectScrollPage(
      children: [
        const _ProjectHeroCard(
          title: 'Projetos ativos',
          subtitle: 'Centro dos projetos em andamento, tarefas e progresso de longo prazo.',
          icon: Icons.folder_special_rounded,
        ),
        const SizedBox(height: GameSpacing.md),
        Row(
          children: [
            Expanded(
              child: GameStatTile(
                label: 'ativos',
                value: '$active',
                icon: Icons.play_arrow_rounded,
                color: GameColors.success,
              ),
            ),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: GameStatTile(
                label: 'pausados',
                value: '$paused',
                icon: Icons.pause_rounded,
                color: GameColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: GameSpacing.sm),
        GameStatTile(
          label: 'tarefas concluídas',
          value: '$doneTaskCount/$taskCount',
          icon: Icons.checklist_rounded,
          color: GameColors.discipline,
        ),
        const SizedBox(height: GameSpacing.lg),
        GameSectionHeader(
          title: '${_projects.length} projeto${_projects.length == 1 ? '' : 's'} em acompanhamento',
          subtitle: 'Toque em um card para abrir detalhes, organizar marcos, tarefas e concluir o projeto.',
          icon: Icons.view_list_rounded,
          actionLabel: 'Atualizar',
          onAction: _loadProjects,
        ),
        for (final project in _projects) ...[
          _ProjectCard(
            project: project,
            busy: _workingProjectId == project.id,
            onOpen: () => _openProject(project),
            onArchive: () => _archiveProject(project),
          ),
          const SizedBox(height: GameSpacing.sm),
        ],
        const SizedBox(height: 96),
      ],
    );
  }
}

class _ProjectScrollPage extends StatelessWidget {
  const _ProjectScrollPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: GameSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ProjectHeroCard extends StatelessWidget {
  const _ProjectHeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GameHighlightCard(
      accentColor: GameColors.reward,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GameColors.reward.withValues(alpha: 0.18),
            ),
            child: Icon(icon, color: GameColors.reward, size: 28),
          ),
          const SizedBox(width: GameSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GameTextStyles.title),
                const SizedBox(height: GameSpacing.xs),
                Text(subtitle, style: GameTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.busy,
    required this.onOpen,
    required this.onArchive,
  });

  final Project project;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final accent = project.status == 'paused' ? GameColors.warning : GameColors.areaById(project.areaId);
    final description = project.description.trim();

    return GameCard(
      onTap: busy ? null : onOpen,
      borderColor: accent.withValues(alpha: 0.30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.16),
                ),
                child: Icon(Icons.folder_special_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Text(
                  project.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.cardTitle,
                ),
              ),
              const SizedBox(width: GameSpacing.xs),
              GameChip(label: project.statusLabel, color: accent, selected: true),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: GameSpacing.sm),
            Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GameTextStyles.body),
          ],
          const SizedBox(height: GameSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text('Progresso', style: GameTextStyles.caption),
              ),
              Text(project.progressText, style: GameTextStyles.caption.copyWith(color: GameColors.textSecondary)),
            ],
          ),
          const SizedBox(height: GameSpacing.xs),
          GameProgressBar(value: project.progressPercent, color: accent, showGlow: true),
          const SizedBox(height: GameSpacing.sm),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              GameChip(label: '${project.doneMilestoneCount}/${project.milestoneCount} marcos', icon: Icons.flag_rounded, color: GameColors.info),
              GameChip(label: '${project.doneTaskCount}/${project.taskCount} tarefas', icon: Icons.checklist_rounded, color: GameColors.discipline),
              GameChip(label: project.areaName, icon: Icons.category_rounded, color: GameColors.areaById(project.areaId)),
              GameChip(label: '+${project.xpReward} XP', icon: Icons.bolt_rounded, color: GameColors.primary),
              GameChip(label: '+${project.coinsReward}', icon: Icons.monetization_on_rounded, color: GameColors.reward),
            ],
          ),
          const SizedBox(height: GameSpacing.md),
          Row(
            children: [
              Expanded(
                child: GamePrimaryButton(
                  label: 'Abrir / tarefas',
                  icon: Icons.open_in_new_rounded,
                  onPressed: busy ? null : onOpen,
                ),
              ),
              const SizedBox(width: GameSpacing.sm),
              SizedBox(
                width: 52,
                child: IconButton.filledTonal(
                  tooltip: 'Arquivar',
                  onPressed: busy ? null : onArchive,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.archive_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
