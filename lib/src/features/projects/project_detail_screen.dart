import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/project_repository.dart';
import '../../design_system/game_design_system.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectRepository _repository = ProjectRepository();

  Project? _project;
  List<ProjectMilestone> _milestones = const [];
  List<ProjectTask> _tasks = const [];
  bool _loading = true;
  bool _working = false;
  String? _error;
  int _defaultTaskXp = 5;
  int _maxTaskXp = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final project = await _repository.getProjectById(widget.projectId);
      final milestones = await _repository.getMilestones(widget.projectId);
      final tasks = await _repository.getTasks(widget.projectId);
      final defaultXp = await _repository.defaultTaskXp();
      final maxXp = await _repository.maxTaskXp();

      if (!mounted) return;
      setState(() {
        _project = project;
        _milestones = milestones;
        _tasks = tasks;
        _defaultTaskXp = defaultXp;
        _maxTaskXp = maxXp;
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

  Future<void> _createMilestone() async {
    final project = _project;
    if (project == null || _working || project.isCompleted) return;

    final draft = await showDialog<_MilestoneDraft>(
      context: context,
      builder: (_) => const _MilestoneDialog(),
    );

    if (draft == null) return;

    setState(() => _working = true);
    try {
      await _repository.createMilestone(
        projectId: project.id,
        title: draft.title,
        description: draft.description,
      );
      if (mounted) await _load();
    } catch (error) {
      _showMessage('Erro ao criar marco: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _editMilestone(ProjectMilestone milestone) async {
    if (_working || _project?.isCompleted == true) return;

    final draft = await showDialog<_MilestoneDraft>(
      context: context,
      builder: (_) => _MilestoneDialog(initial: milestone),
    );

    if (draft == null) return;

    setState(() => _working = true);
    try {
      await _repository.updateMilestone(
        milestone: milestone,
        title: draft.title,
        description: draft.description,
      );
      if (mounted) await _load();
    } catch (error) {
      _showMessage('Erro ao editar marco: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _deleteMilestone(ProjectMilestone milestone) async {
    if (_working || _project?.isCompleted == true) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover marco?'),
        content: Text(
          'Remover "${milestone.title}" e suas tarefas? Se alguma tarefa concluída tiver XP aplicado, ele será revertido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _working = true);
    try {
      await _repository.deleteMilestone(milestone);
      if (mounted) await _load();
    } catch (error) {
      _showMessage('Erro ao remover marco: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _createTask(ProjectMilestone milestone) async {
    if (_working || _project?.isCompleted == true) return;

    final draft = await showDialog<ProjectTaskDraft>(
      context: context,
      builder: (_) => _TaskDialog(defaultXp: _defaultTaskXp, maxXp: _maxTaskXp),
    );

    if (draft == null) return;

    setState(() => _working = true);
    try {
      await _repository.addTask(
        projectId: milestone.projectId,
        milestoneId: milestone.id,
        title: draft.title,
        xpReward: draft.xpReward,
        notes: draft.notes,
      );
      if (mounted) await _load();
    } catch (error) {
      _showMessage('Erro ao criar tarefa: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _editTask(ProjectTask task) async {
    if (_working || _project?.isCompleted == true) return;

    final draft = await showDialog<ProjectTaskDraft>(
      context: context,
      builder: (_) => _TaskDialog(defaultXp: _defaultTaskXp, maxXp: _maxTaskXp, initial: task),
    );

    if (draft == null) return;

    setState(() => _working = true);
    try {
      await _repository.updateTask(task: task, draft: draft);
      if (mounted) await _load();
    } catch (error) {
      _showMessage('Erro ao editar tarefa: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _toggleTask(ProjectTask task, bool isDone) async {
    if (_working || _project?.isCompleted == true) return;

    setState(() => _working = true);
    try {
      await _repository.toggleTask(task, isDone);
      _showMessage(isDone ? '+${task.xpReward} XP aplicado.' : '${task.xpReward} XP revertidos.');
      if (mounted) await _load();
    } catch (error) {
      _showMessage('Erro ao atualizar tarefa: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _deleteTask(ProjectTask task) async {
    if (_working || _project?.isCompleted == true) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover tarefa?'),
        content: Text(
          task.isDone && task.xpApplied
              ? 'Remover "${task.title}" e reverter ${task.xpReward} XP?'
              : 'Remover "${task.title}" do projeto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _working = true);
    try {
      await _repository.deleteTask(task);
      if (mounted) await _load();
    } catch (error) {
      _showMessage('Erro ao remover tarefa: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _togglePaused() async {
    final project = _project;
    if (project == null || _working || project.isCompleted) return;

    final nextStatus = project.status == 'paused' ? 'active' : 'paused';
    setState(() => _working = true);

    try {
      await _repository.setStatus(projectId: project.id, status: nextStatus);
      if (mounted) await _load();
    } catch (error) {
      _showMessage('Erro ao alterar status: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _completeProject() async {
    final project = _project;
    if (project == null || _working || project.isCompleted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Concluir projeto?'),
          content: Text(
            'Concluir "${project.title}" e receber a recompensa final de +${project.xpReward} XP e +${project.coinsReward} coins?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Concluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _working = true);

    try {
      final result = await _repository.completeProject(project);
      _showMessage(result.message);
      if (mounted) await _load();
    } catch (error) {
      _showMessage('Erro ao concluir projeto: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _undoProjectCompletion() async {
    final project = _project;
    if (project == null || _working || !project.isCompleted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desfazer conclusão?'),
        content: Text(
          'O projeto voltará para ativo e a recompensa final será revertida: ${project.xpReward} XP e ${project.coinsReward} coins.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desfazer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _working = true);
    try {
      final result = await _repository.undoProjectCompletion(project);
      _showMessage(result.message);
      if (mounted) await _load();
    } catch (error) {
      _showMessage('Erro ao desfazer conclusão: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _archiveProject() async {
    final project = _project;
    if (project == null || _working) return;

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

    setState(() => _working = true);

    try {
      await _repository.archiveProject(project.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      _showMessage('Erro ao arquivar projeto: $error');
    } finally {
      if (mounted) setState(() => _working = false);
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
    final project = _project;

    return Scaffold(
      appBar: AppBar(
        title: Text(project?.title ?? 'Projeto'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: project == null || project.isCompleted
          ? null
          : FloatingActionButton.extended(
              onPressed: _working ? null : _createMilestone,
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Marco'),
            ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final error = _error;
    if (error != null) {
      return _DetailScrollPage(
        children: [
          GameEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Erro ao carregar projeto',
            message: error,
            actionLabel: 'Tentar novamente',
            onAction: _load,
          ),
        ],
      );
    }

    final project = _project;
    if (project == null) return const Center(child: Text('Projeto não encontrado.'));

    final accent = project.isCompleted ? GameColors.success : GameColors.areaById(project.areaId);

    return _DetailScrollPage(
      children: [
        _ProjectHeader(project: project, accent: accent),
        const SizedBox(height: GameSpacing.md),
        Row(
          children: [
            Expanded(
              child: GameStatTile(
                label: 'marcos',
                value: '${project.doneMilestoneCount}/${project.milestoneCount}',
                icon: Icons.flag_rounded,
                color: GameColors.info,
              ),
            ),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: GameStatTile(
                label: 'tarefas',
                value: '${project.doneTaskCount}/${project.taskCount}',
                icon: Icons.checklist_rounded,
                color: GameColors.discipline,
              ),
            ),
          ],
        ),
        const SizedBox(height: GameSpacing.sm),
        GameStatTile(
          label: 'XP de tarefas aplicado',
          value: '${project.taskXpApplied}/${project.taskXpTotal}',
          icon: Icons.bolt_rounded,
          color: GameColors.primary,
        ),
        const SizedBox(height: GameSpacing.md),
        _ProjectActions(
          project: project,
          working: _working,
          onComplete: _completeProject,
          onUndoComplete: _undoProjectCompletion,
          onTogglePaused: _togglePaused,
          onArchive: _archiveProject,
        ),
        const SizedBox(height: GameSpacing.lg),
        GameSectionHeader(
          title: 'Marcos do projeto',
          subtitle: 'Cada marco agrupa tarefas. Tarefas dão XP pequeno; o projeto dá recompensa final.',
          icon: Icons.account_tree_rounded,
          actionLabel: project.isCompleted ? null : 'Novo marco',
          onAction: project.isCompleted || _working ? null : _createMilestone,
        ),
        if (_milestones.isEmpty)
          GameEmptyState(
            icon: Icons.flag_outlined,
            title: 'Nenhum marco ainda',
            message: 'Crie o primeiro marco para dividir o projeto em etapas.',
            actionLabel: project.isCompleted ? null : 'Criar marco',
            onAction: project.isCompleted || _working ? null : _createMilestone,
          )
        else
          for (final milestone in _milestones) ...[
            _MilestoneCard(
              milestone: milestone,
              tasks: _tasks.where((task) => task.milestoneId == milestone.id).toList(),
              working: _working || project.isCompleted,
              onAddTask: () => _createTask(milestone),
              onEditMilestone: () => _editMilestone(milestone),
              onDeleteMilestone: () => _deleteMilestone(milestone),
              onToggleTask: _toggleTask,
              onEditTask: _editTask,
              onDeleteTask: _deleteTask,
            ),
            const SizedBox(height: GameSpacing.md),
          ],
        const SizedBox(height: 96),
      ],
    );
  }
}

class _DetailScrollPage extends StatelessWidget {
  const _DetailScrollPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: GameSpacing.screen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project, required this.accent});

  final Project project;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final description = project.description.trim();

    return GameHighlightCard(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.18)),
                child: Icon(Icons.folder_special_rounded, color: accent, size: 28),
              ),
              const SizedBox(width: GameSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GameTextStyles.title),
                    const SizedBox(height: GameSpacing.xs),
                    Text('${project.statusLabel} • ${project.difficultyLabel}', style: GameTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: GameSpacing.md),
            Text(description, style: GameTextStyles.body),
          ],
          const SizedBox(height: GameSpacing.md),
          GameProgressBar(value: project.progressPercent, color: accent, height: 12, showGlow: true),
          const SizedBox(height: GameSpacing.sm),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              GameChip(label: project.progressText, icon: Icons.auto_graph_rounded, color: accent, selected: true),
              GameChip(label: '${project.doneMilestoneCount}/${project.milestoneCount} marcos', icon: Icons.flag_rounded, color: GameColors.info),
              GameChip(label: '${project.doneTaskCount}/${project.taskCount} tarefas', icon: Icons.checklist_rounded, color: GameColors.discipline),
              GameChip(label: '+${project.xpReward} XP final', icon: Icons.emoji_events_rounded, color: GameColors.reward),
            ],
          ),
          const SizedBox(height: GameSpacing.md),
          Text(
            'Recompensa final: +${project.xpReward} XP • +${project.coinsReward} coins',
            style: GameTextStyles.cardTitle.copyWith(color: GameColors.reward),
          ),
        ],
      ),
    );
  }
}

class _ProjectActions extends StatelessWidget {
  const _ProjectActions({
    required this.project,
    required this.working,
    required this.onComplete,
    required this.onUndoComplete,
    required this.onTogglePaused,
    required this.onArchive,
  });

  final Project project;
  final bool working;
  final VoidCallback onComplete;
  final VoidCallback onUndoComplete;
  final VoidCallback onTogglePaused;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      backgroundColor: GameColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ações do projeto', style: GameTextStyles.cardTitle),
          const SizedBox(height: GameSpacing.sm),
          if (project.isCompleted)
            GameSecondaryButton(
              label: 'Desfazer conclusão',
              icon: Icons.undo_rounded,
              onPressed: working ? null : onUndoComplete,
            )
          else ...[
            GamePrimaryButton(
              label: project.isReadyForCompletion ? 'Concluir projeto' : 'Concluir tarefas primeiro',
              icon: Icons.emoji_events_rounded,
              onPressed: working || !project.isReadyForCompletion ? null : onComplete,
            ),
            const SizedBox(height: GameSpacing.sm),
            GameSecondaryButton(
              label: project.status == 'paused' ? 'Retomar projeto' : 'Pausar projeto',
              icon: project.status == 'paused' ? Icons.play_arrow_rounded : Icons.pause_rounded,
              onPressed: working ? null : onTogglePaused,
            ),
          ],
          const SizedBox(height: GameSpacing.sm),
          GameDangerButton(
            label: 'Arquivar',
            icon: Icons.archive_rounded,
            onPressed: working ? null : onArchive,
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.milestone,
    required this.tasks,
    required this.working,
    required this.onAddTask,
    required this.onEditMilestone,
    required this.onDeleteMilestone,
    required this.onToggleTask,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final ProjectMilestone milestone;
  final List<ProjectTask> tasks;
  final bool working;
  final VoidCallback onAddTask;
  final VoidCallback onEditMilestone;
  final VoidCallback onDeleteMilestone;
  final Future<void> Function(ProjectTask task, bool isDone) onToggleTask;
  final Future<void> Function(ProjectTask task) onEditTask;
  final Future<void> Function(ProjectTask task) onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final color = milestone.isCompleted ? GameColors.success : GameColors.info;
    final description = milestone.description.trim();

    return GameCard(
      borderColor: color.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(milestone.isCompleted ? Icons.flag_rounded : Icons.outlined_flag_rounded, color: color),
              const SizedBox(width: GameSpacing.sm),
              Expanded(child: Text(milestone.title, style: GameTextStyles.cardTitle)),
              GameChip(label: milestone.progressText, color: color, selected: milestone.isCompleted),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: GameSpacing.xs),
            Text(description, style: GameTextStyles.body),
          ],
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: milestone.progressPercent, color: color, showGlow: milestone.isCompleted),
          const SizedBox(height: GameSpacing.sm),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              GameChip(label: '${milestone.doneTaskCount}/${milestone.taskCount} tarefas', icon: Icons.checklist_rounded, color: GameColors.discipline),
              GameChip(label: '${milestone.taskXpApplied}/${milestone.taskXpTotal} XP', icon: Icons.bolt_rounded, color: GameColors.primary),
              if (milestone.isCompleted) GameChip(label: 'Marco concluído', icon: Icons.check_circle_rounded, color: GameColors.success, selected: true),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          Row(
            children: [
              Expanded(
                child: GameSecondaryButton(
                  label: 'Editar marco',
                  icon: Icons.edit_rounded,
                  onPressed: working ? null : onEditMilestone,
                ),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: GameSecondaryButton(
                  label: 'Nova tarefa',
                  icon: Icons.add_task_rounded,
                  onPressed: working ? null : onAddTask,
                ),
              ),
            ],
          ),
          if (tasks.isEmpty) ...[
            const SizedBox(height: GameSpacing.md),
            GameEmptyState(
              icon: Icons.task_alt_rounded,
              title: 'Nenhuma tarefa neste marco',
              message: 'Adicione tarefas pequenas para fazer esse marco avançar.',
            ),
          ] else ...[
            const SizedBox(height: GameSpacing.md),
            for (final task in tasks) ...[
              _TaskTile(
                task: task,
                working: working,
                onChanged: (value) => onToggleTask(task, value),
                onEdit: () => onEditTask(task),
                onDelete: () => onDeleteTask(task),
              ),
              const SizedBox(height: GameSpacing.xs),
            ],
          ],
          const SizedBox(height: GameSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: working ? null : onDeleteMilestone,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Remover marco'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.working,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectTask task;
  final bool working;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = task.isDone ? GameColors.success : GameColors.discipline;

    return GameCompactCard(
      child: Row(
        children: [
          Checkbox(
            value: task.isDone,
            onChanged: working ? null : (value) => onChanged(value ?? false),
          ),
          const SizedBox(width: GameSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.body.copyWith(
                    color: task.isDone ? GameColors.textMuted : GameColors.textPrimary,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.isDone ? '+${task.xpReward} XP aplicado' : '+${task.xpReward} XP ao concluir',
                  style: GameTextStyles.caption.copyWith(color: color),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar tarefa',
            onPressed: working ? null : onEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Remover tarefa',
            onPressed: working ? null : onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _MilestoneDraft {
  const _MilestoneDraft({required this.title, required this.description});

  final String title;
  final String description;
}

class _MilestoneDialog extends StatefulWidget {
  const _MilestoneDialog({this.initial});

  final ProjectMilestone? initial;

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initial?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.length < 2) return;
    Navigator.of(context).pop(_MilestoneDraft(title: title, description: _descriptionController.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Novo marco' : 'Editar marco'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Título do marco'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: GameSpacing.sm),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descrição opcional'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({required this.defaultXp, required this.maxXp, this.initial});

  final int defaultXp;
  final int maxXp;
  final ProjectTask? initial;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _xpController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _notesController = TextEditingController(text: initial?.notes ?? '');
    _xpController = TextEditingController(text: '${initial?.xpReward ?? widget.defaultXp}');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.length < 2) return;
    final parsedXp = int.tryParse(_xpController.text.trim()) ?? widget.defaultXp;
    final safeXp = parsedXp.clamp(1, widget.maxXp).toInt();
    Navigator.of(context).pop(ProjectTaskDraft(title: title, xpReward: safeXp, notes: _notesController.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Nova tarefa' : 'Editar tarefa'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Título da tarefa'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: GameSpacing.sm),
          TextField(
            controller: _xpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'XP da tarefa',
              helperText: 'Teto atual: ${widget.maxXp} XP',
            ),
          ),
          const SizedBox(height: GameSpacing.sm),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notas opcionais'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}
