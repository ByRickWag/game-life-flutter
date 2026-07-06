import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/models/v3_commitment_models.dart';
import '../../core/repositories/mission_repository.dart';
import '../../core/repositories/mission_task_repository.dart' as task_repo;
import '../../design_system/game_design_system.dart';
import 'mission_form_screen.dart';

class MissionDetailScreen extends StatefulWidget {
  const MissionDetailScreen({super.key, required this.mission});

  final Mission mission;

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final MissionRepository _missionRepository = MissionRepository();
  final task_repo.MissionTaskRepository _taskRepository = task_repo.MissionTaskRepository();

  late Mission _mission;
  Future<_MissionDetailData>? _future;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _mission = widget.mission;
    _future = _load();
  }

  Future<_MissionDetailData> _load() async {
    final missions = await _missionRepository.getActiveMissions();
    for (final mission in missions) {
      if (mission.id == _mission.id) {
        _mission = mission;
        break;
      }
    }

    final tasks = await _taskRepository.getTasks(_mission.id);
    final stats = await _taskRepository.getStats(_mission.id);
    final completion = await _missionRepository.getCurrentPeriodCompletionMap([_mission]);

    return _MissionDetailData(
      tasks: tasks,
      stats: stats,
      completed: completion[_mission.id] ?? false,
    );
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  void _showLockedChecklistMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checklist bloqueado: desfaça a conclusão da missão antes de alterar subtarefas.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openEditMission() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MissionFormScreen(mission: _mission)),
    );
    if (changed == true && mounted) {
      await _reload();
    }
  }

  Future<void> _openTaskDialog({MissionTask? task}) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _MissionTaskDialog(
        initialTitle: task?.title ?? '',
        initialNotes: task?.notes ?? '',
        editing: task != null,
        onSave: (title, notes) async {
          if (task == null) {
            await _taskRepository.addTask(
              missionId: _mission.id,
              title: title,
              notes: notes,
            );
          } else {
            await _taskRepository.updateTask(
              taskId: task.id,
              title: title,
              notes: notes,
            );
          }
        },
      ),
    );

    if (changed == true && mounted) {
      await _reload();
    }
  }

  Future<void> _toggleTask(MissionTask task, bool completed) async {
    if (_working) return;
    setState(() => _working = true);

    try {
      await _taskRepository.toggleTask(taskId: task.id, isDone: completed);
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar subtarefa: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: GameColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _deleteTask(MissionTask task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir subtarefa?'),
        content: Text('A subtarefa "${task.title}" será removida do checklist.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _taskRepository.deleteTask(task.id);
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir subtarefa: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: GameColors.danger,
        ),
      );
    }
  }

  Future<void> _completeMission() async {
    if (_working) return;
    setState(() => _working = true);

    try {
      final result = await _missionRepository.completeMission(_mission);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: result.completed ? GameColors.success : GameColors.surfaceRaised,
        ),
      );
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao concluir missão: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: GameColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _undoMission() async {
    if (_working) return;
    setState(() => _working = true);

    try {
      final result = await _missionRepository.undoMissionCompletion(_mission);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: result.completed ? GameColors.surfaceRaised : GameColors.danger,
        ),
      );
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao desfazer conclusão: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: GameColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalhe da missão'),
          actions: [
            IconButton(
              tooltip: 'Editar missão',
              onPressed: _openEditMission,
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FutureBuilder<_MissionDetailData>(
          future: _future,
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data == null || data.completed) return const SizedBox.shrink();

            return FloatingActionButton.extended(
              onPressed: () => _openTaskDialog(),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Subtarefa'),
            );
          },
        ),
        body: FutureBuilder<_MissionDetailData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ScrollPage(
                children: [
                  GameEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Erro ao carregar missão',
                    message: snapshot.error.toString(),
                    actionLabel: 'Tentar novamente',
                    onAction: _reload,
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            final effectiveCompound = _mission.isCompound || data.stats.total > 0;
            return _ScrollPage(
              children: [
                _MissionSummaryCard(
                  mission: _mission,
                  stats: data.stats,
                  completed: data.completed,
                  effectiveCompound: effectiveCompound,
                ),
                const SizedBox(height: GameSpacing.md),
                if (_mission.notes.trim().isNotEmpty) ...[
                  GameCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notas', style: GameTextStyles.cardTitle),
                        const SizedBox(height: GameSpacing.xs),
                        Text(_mission.notes.trim(), style: GameTextStyles.body),
                      ],
                    ),
                  ),
                  const SizedBox(height: GameSpacing.md),
                ],
                GameSectionHeader(
                  title: 'Checklist da missão',
                  subtitle: data.completed
                      ? 'Desfaça a conclusão para editar o checklist com segurança.'
                      : 'Marque as subtarefas concluídas. A missão composta só conclui com o checklist completo.',
                  icon: Icons.checklist_rounded,
                  actionLabel: data.completed ? null : 'Adicionar',
                  onAction: data.completed ? null : () => _openTaskDialog(),
                ),
                const SizedBox(height: GameSpacing.sm),
                if (data.tasks.isEmpty)
                  GameEmptyState(
                    icon: Icons.add_task_rounded,
                    title: 'Nenhuma subtarefa ainda',
                    message: 'Adicione etapas para transformar esta missão em uma missão composta com progresso real.',
                    actionLabel: data.completed ? null : 'Adicionar subtarefa',
                    onAction: data.completed ? null : () => _openTaskDialog(),
                  )
                else
                  for (final task in data.tasks) ...[
                    _MissionTaskCard(
                      task: task,
                      locked: data.completed,
                      onChanged: (value) => _toggleTask(task, value),
                      onEdit: data.completed ? _showLockedChecklistMessage : () => _openTaskDialog(task: task),
                      onDelete: data.completed ? _showLockedChecklistMessage : () => _deleteTask(task),
                    ),
                    const SizedBox(height: GameSpacing.sm),
                  ],
                const SizedBox(height: GameSpacing.sm),
                if (_working)
                  const LinearProgressIndicator(minHeight: 3)
                else if (data.completed) ...[
                  const GamePrimaryButton(
                    label: 'Concluída neste período',
                    icon: Icons.verified_rounded,
                    onPressed: null,
                  ),
                  const SizedBox(height: GameSpacing.xs),
                  GameSecondaryButton(
                    label: 'Desfazer conclusão',
                    icon: Icons.undo_rounded,
                    onPressed: _undoMission,
                  ),
                ] else ...[
                  GamePrimaryButton(
                    label: effectiveCompound ? 'Concluir missão composta' : 'Concluir missão',
                    icon: Icons.check_circle_rounded,
                    onPressed: _completeMission,
                  ),
                  if (effectiveCompound && !data.stats.allDone) ...[
                    const SizedBox(height: GameSpacing.xs),
                    Text(
                      'Conclua todas as subtarefas antes de finalizar esta missão composta.',
                      style: GameTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
                const SizedBox(height: 96),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MissionDetailData {
  const _MissionDetailData({
    required this.tasks,
    required this.stats,
    required this.completed,
  });

  final List<MissionTask> tasks;
  final task_repo.MissionTaskStats stats;
  final bool completed;
}

class _ScrollPage extends StatelessWidget {
  const _ScrollPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: GameSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MissionSummaryCard extends StatelessWidget {
  const _MissionSummaryCard({
    required this.mission,
    required this.stats,
    required this.completed,
    required this.effectiveCompound,
  });

  final Mission mission;
  final task_repo.MissionTaskStats stats;
  final bool completed;
  final bool effectiveCompound;

  @override
  Widget build(BuildContext context) {
    final progress = effectiveCompound ? stats.progress : (completed ? 1.0 : 0.0);
    return GameHighlightCard(
      accentColor: completed ? GameColors.success : GameColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            completed ? Icons.verified_rounded : Icons.flag_rounded,
            color: completed ? GameColors.success : GameColors.primarySoft,
            size: 34,
          ),
          const SizedBox(height: GameSpacing.sm),
          Text(mission.title, style: GameTextStyles.title),
          if (mission.description.trim().isNotEmpty) ...[
            const SizedBox(height: GameSpacing.xs),
            Text(mission.description.trim(), style: GameTextStyles.body),
          ],
          const SizedBox(height: GameSpacing.sm),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              GameChip(
                label: effectiveCompound ? 'Composta' : 'Simples',
                icon: effectiveCompound ? Icons.checklist_rounded : Icons.flag_rounded,
                color: GameColors.primary,
                selected: effectiveCompound,
              ),
              GameChip(label: mission.typeLabel, icon: Icons.event_repeat_rounded, color: GameColors.info),
              GameChip(label: mission.difficultyLabel, icon: Icons.speed_rounded, color: GameColors.reward),
              if (completed)
                const GameChip(
                  label: 'Concluída',
                  icon: Icons.check_circle_rounded,
                  color: GameColors.success,
                  selected: true,
                ),
            ],
          ),
          const SizedBox(height: GameSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  effectiveCompound ? '${stats.done}/${stats.total} subtarefas' : 'Progresso do período',
                  style: GameTextStyles.caption,
                ),
              ),
              Text('${(progress * 100).round()}%', style: GameTextStyles.caption),
            ],
          ),
          const SizedBox(height: GameSpacing.xs),
          GameProgressBar(
            value: progress,
            color: completed ? GameColors.success : GameColors.primary,
            showGlow: completed,
          ),
          const SizedBox(height: GameSpacing.sm),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: GameColors.rewardSoft, size: 20),
              const SizedBox(width: 4),
              Text('+${mission.xpReward} XP', style: GameTextStyles.body.copyWith(color: GameColors.rewardSoft)),
              const SizedBox(width: GameSpacing.sm),
              const Icon(Icons.monetization_on_rounded, color: GameColors.rewardSoft, size: 20),
              const SizedBox(width: 4),
              Text('+${mission.coinsReward} coins', style: GameTextStyles.body.copyWith(color: GameColors.rewardSoft)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionTaskCard extends StatelessWidget {
  const _MissionTaskCard({
    required this.task,
    required this.locked,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final MissionTask task;
  final bool locked;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      showShadow: !task.isDone,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox.adaptive(
            value: task.isDone,
            onChanged: locked ? null : (value) => onChanged(value ?? false),
          ),
          const SizedBox(width: GameSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GameTextStyles.cardTitle.copyWith(
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(task.notes.trim(), style: GameTextStyles.caption),
                ],
                if (locked) ...[
                  const SizedBox(height: 4),
                  Text('Checklist bloqueado enquanto a missão está concluída.', style: GameTextStyles.caption),
                ],
              ],
            ),
          ),
          if (locked)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(Icons.lock_rounded, color: GameColors.textMuted, size: 20),
            )
          else
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
        ],
      ),
    );
  }
}

class _MissionTaskDialog extends StatefulWidget {
  const _MissionTaskDialog({
    required this.initialTitle,
    required this.initialNotes,
    required this.editing,
    required this.onSave,
  });

  final String initialTitle;
  final String initialNotes;
  final bool editing;
  final Future<void> Function(String title, String notes) onSave;

  @override
  State<_MissionTaskDialog> createState() => _MissionTaskDialogState();
}

class _MissionTaskDialogState extends State<_MissionTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _saving) return;
    setState(() => _saving = true);

    try {
      await widget.onSave(_titleController.text, _notesController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar subtarefa: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: GameColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.editing ? 'Editar subtarefa' : 'Nova subtarefa'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 2) return 'Digite pelo menos 2 caracteres.';
                return null;
              },
            ),
            const SizedBox(height: GameSpacing.sm),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notas'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_rounded),
          label: Text(_saving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
