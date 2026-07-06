import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/project_repository.dart';
import '../../design_system/game_design_system.dart';
import 'project_detail_screen.dart';

class ProjectTasksScreen extends StatefulWidget {
  const ProjectTasksScreen({super.key});

  @override
  State<ProjectTasksScreen> createState() => _ProjectTasksScreenState();
}

class _ProjectTasksScreenState extends State<ProjectTasksScreen> {
  final ProjectRepository _repository = ProjectRepository();

  List<Map<String, Object?>> _taskRows = const [];
  String _filter = 'open';
  bool _loading = true;
  bool _working = false;
  String? _error;

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
      final rows = await _repository.getProjectTaskRows(filter: _filter);
      if (!mounted) return;
      setState(() {
        _taskRows = rows;
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

  Future<void> _toggleTask(Map<String, Object?> row, bool value) async {
    if (_working) return;

    final task = ProjectTask.fromMap(row);
    setState(() => _working = true);

    try {
      await _repository.toggleTask(task, value);
      if (mounted) await _load();
    } catch (error) {
      _showMessage('Erro ao atualizar tarefa: $error');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _deleteTask(Map<String, Object?> row) async {
    if (_working) return;

    final task = ProjectTask.fromMap(row);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover tarefa?'),
        content: Text('Remover "${task.title}"?'),
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

  Future<void> _openProject(Map<String, Object?> row) async {
    final projectId = readString(row, 'project_id');
    if (projectId.isEmpty) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: projectId)),
    );

    if (mounted) await _load();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _TaskScrollPage(
        children: [
          GameEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Erro ao carregar tarefas',
            message: error,
            actionLabel: 'Tentar novamente',
            onAction: _load,
          ),
        ],
      );
    }

    final doneCount = _taskRows.where((row) => readInt(row, 'is_done') == 1).length;
    final openCount = _taskRows.length - doneCount;

    return _TaskScrollPage(
      children: [
        GameHighlightCard(
          accentColor: GameColors.discipline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.checklist_rounded, color: GameColors.discipline, size: 32),
              const SizedBox(height: GameSpacing.sm),
              Text('Central de tarefas', style: GameTextStyles.title),
              const SizedBox(height: GameSpacing.xs),
              Text(
                'Veja tarefas de projetos em um único lugar e marque avanços sem abrir cada projeto primeiro.',
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
                label: 'pendentes',
                value: '$openCount',
                icon: Icons.pending_actions_rounded,
                color: GameColors.warning,
              ),
            ),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: GameStatTile(
                label: 'concluídas',
                value: '$doneCount',
                icon: Icons.check_circle_rounded,
                color: GameColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: GameSpacing.md),
        GameCard(
          backgroundColor: GameColors.surfaceSoft,
          child: DropdownButtonFormField<String>(
            initialValue: _filter,
            decoration: const InputDecoration(
              labelText: 'Filtro',
              prefixIcon: Icon(Icons.filter_list_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'open', child: Text('Pendentes')),
              DropdownMenuItem(value: 'done', child: Text('Concluídas')),
              DropdownMenuItem(value: 'all', child: Text('Todas')),
            ],
            onChanged: (value) async {
              if (value == null || value == _filter) return;
              setState(() => _filter = value);
              await _load();
            },
          ),
        ),
        const SizedBox(height: GameSpacing.lg),
        GameSectionHeader(
          title: 'Tarefas de projetos',
          subtitle: 'Lista limitada e segura para preservar estabilidade visual.',
          icon: Icons.task_alt_rounded,
          actionLabel: 'Atualizar',
          onAction: _load,
        ),
        if (_taskRows.isEmpty)
          GameEmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Nenhuma tarefa encontrada',
            message: _filter == 'open'
                ? 'Não há tarefas pendentes nos projetos ativos ou pausados.'
                : 'Crie tarefas dentro dos detalhes de um projeto para vê-las aqui.',
          )
        else
          for (final row in _taskRows) ...[
            _GlobalTaskTile(
              row: row,
              working: _working,
              onChanged: (value) => _toggleTask(row, value),
              onOpenProject: () => _openProject(row),
              onDelete: () => _deleteTask(row),
            ),
            const SizedBox(height: GameSpacing.sm),
          ],
        const SizedBox(height: GameSpacing.xl),
      ],
    );
  }
}

class _TaskScrollPage extends StatelessWidget {
  const _TaskScrollPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: GameSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _GlobalTaskTile extends StatelessWidget {
  const _GlobalTaskTile({
    required this.row,
    required this.working,
    required this.onChanged,
    required this.onOpenProject,
    required this.onDelete,
  });

  final Map<String, Object?> row;
  final bool working;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenProject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = readString(row, 'title', fallback: 'Tarefa');
    final isDone = readInt(row, 'is_done') == 1;
    final projectTitle = readString(row, 'project_title', fallback: 'Projeto');
    final projectStatus = readString(row, 'project_status', fallback: 'active');
    final accent = isDone ? GameColors.success : GameColors.discipline;

    return GameCard(
      onTap: onOpenProject,
      padding: const EdgeInsets.all(GameSpacing.md),
      borderColor: accent.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isDone,
                onChanged: working ? null : (value) => onChanged(value ?? false),
              ),
              const SizedBox(width: GameSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.cardTitle.copyWith(
                    color: isDone ? GameColors.textMuted : GameColors.textPrimary,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.xs),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              GameChip(label: projectTitle, icon: Icons.folder_special_rounded, color: GameColors.reward),
              GameChip(label: _projectStatusLabel(projectStatus), icon: Icons.info_outline_rounded, color: _projectStatusColor(projectStatus)),
              GameChip(label: isDone ? 'Concluída' : 'Pendente', icon: isDone ? Icons.check_rounded : Icons.pending_actions_rounded, color: accent, selected: isDone),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          Row(
            children: [
              Expanded(
                child: GameSecondaryButton(
                  label: 'Abrir projeto',
                  icon: Icons.open_in_new_rounded,
                  onPressed: onOpenProject,
                ),
              ),
              const SizedBox(width: GameSpacing.sm),
              SizedBox(
                width: 52,
                child: IconButton.filledTonal(
                  tooltip: 'Remover tarefa',
                  onPressed: working ? null : onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _projectStatusLabel(String status) {
    return switch (status) {
      'active' => 'Ativo',
      'paused' => 'Pausado',
      'completed' => 'Concluído',
      'archived' => 'Arquivado',
      _ => status,
    };
  }

  Color _projectStatusColor(String status) {
    return switch (status) {
      'active' => GameColors.success,
      'paused' => GameColors.warning,
      'completed' => GameColors.success,
      _ => GameColors.textMuted,
    };
  }
}
