import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/mission_repository.dart';
import '../../core/repositories/mission_task_repository.dart' as task_repo;
import '../../design_system/game_design_system.dart';
import 'mission_detail_screen.dart';
import 'mission_form_screen.dart';

class MissionListScreen extends StatefulWidget {
  const MissionListScreen({super.key});

  @override
  State<MissionListScreen> createState() => _MissionListScreenState();
}

class _MissionListScreenState extends State<MissionListScreen> {
  final MissionRepository _repository = MissionRepository();

  List<Mission> _missions = const [];
  Set<String> _completedMissionIds = const {};
  bool _loading = true;
  String? _error;
  String? _workingMissionId;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final missions = await _repository.getActiveMissions();
      final completionMap = await _repository.getCurrentPeriodCompletionMap(missions);
      if (!mounted) return;

      setState(() {
        _missions = missions;
        _completedMissionIds = completionMap.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toSet();
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

  Future<void> _openCreateMission() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MissionFormScreen()),
    );

    if (changed == true && mounted) {
      await _loadMissions();
    }
  }

  Future<void> _openEditMission(Mission mission) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MissionFormScreen(mission: mission)),
    );

    if (changed == true && mounted) {
      await _loadMissions();
    }
  }

  Future<void> _openMissionDetail(Mission mission) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MissionDetailScreen(mission: mission)),
    );

    if (changed == true && mounted) {
      await _loadMissions();
    }
  }

  Future<void> _completeMission(Mission mission) async {
    if (_workingMissionId != null) return;

    setState(() {
      _workingMissionId = mission.id;
    });

    try {
      final result = await _repository.completeMission(mission);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.completed ? Icons.verified_rounded : Icons.info_outline_rounded,
                color: GameColors.textPrimary,
              ),
              const SizedBox(width: GameSpacing.xs),
              Expanded(child: Text(result.message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: result.completed ? GameColors.success : GameColors.surfaceRaised,
          action: result.completed
              ? SnackBarAction(
                  label: 'Desfazer',
                  textColor: GameColors.textPrimary,
                  onPressed: () => _undoMission(mission),
                )
              : null,
        ),
      );

      await _loadMissions();
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
      if (mounted) {
        setState(() {
          _workingMissionId = null;
        });
      }
    }
  }

  Future<void> _undoMission(Mission mission) async {
    if (_workingMissionId != null) return;

    setState(() {
      _workingMissionId = mission.id;
    });

    try {
      final result = await _repository.undoMissionCompletion(mission);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: result.completed ? GameColors.surfaceRaised : GameColors.danger,
        ),
      );

      await _loadMissions();
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
      if (mounted) {
        setState(() {
          _workingMissionId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missões'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loadMissions,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Nova missão',
            onPressed: _openCreateMission,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateMission,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova missão'),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ScrollPage(
        children: [
          GameEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Erro ao carregar missões',
            message: error,
            actionLabel: 'Tentar novamente',
            onAction: _loadMissions,
          ),
        ],
      );
    }

    if (_missions.isEmpty) {
      return _ScrollPage(
        children: [
          const GameHighlightCard(
            accentColor: GameColors.primary,
            child: _MissionHeader(
              title: 'Missões da jornada',
              subtitle: 'Crie rotinas recorrentes e desafios pontuais para transformar ações reais em XP, coins e atributos.',
              icon: Icons.flag_rounded,
            ),
          ),
          const SizedBox(height: GameSpacing.md),
          GameEmptyState(
            icon: Icons.flag_outlined,
            title: 'Nenhuma missão ativa ainda',
            message: 'Crie sua primeira missão diária, semanal, mensal ou especial.',
            actionLabel: 'Criar primeira missão',
            onAction: _openCreateMission,
          ),
        ],
      );
    }

    final completedCount = _completedMissionIds.length;

    return _ScrollPage(
      children: [
        GameHighlightCard(
          accentColor: GameColors.primary,
          child: _MissionHeader(
            title: _missions.length == 1 ? '1 missão ativa' : '${_missions.length} missões ativas',
            subtitle: '$completedCount concluída${completedCount == 1 ? '' : 's'} no período atual. Você pode desfazer conclusões acidentais no próprio card.',
            icon: Icons.flag_rounded,
          ),
        ),
        const SizedBox(height: GameSpacing.md),
        GameSectionHeader(
          title: 'Lista de missões',
          subtitle: 'Conclua, edite ou desfaça uma conclusão acidental.',
          icon: Icons.list_alt_rounded,
          actionLabel: 'Atualizar',
          onAction: _loadMissions,
        ),
        const SizedBox(height: GameSpacing.xs),
        for (final mission in _missions) ...[
          _MissionCard(
            mission: mission,
            completed: _completedMissionIds.contains(mission.id),
            busy: _workingMissionId == mission.id,
            onComplete: () => _completeMission(mission),
            onUndo: () => _undoMission(mission),
            onEdit: () => _openEditMission(mission),
            onDetails: () => _openMissionDetail(mission),
          ),
          const SizedBox(height: GameSpacing.sm),
        ],
        const SizedBox(height: 96),
      ],
    );
  }
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

class _MissionHeader extends StatelessWidget {
  const _MissionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: GameColors.primarySoft, size: 34),
        const SizedBox(height: GameSpacing.sm),
        Text(title, style: GameTextStyles.title),
        const SizedBox(height: GameSpacing.xs),
        Text(subtitle, style: GameTextStyles.body),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.completed,
    required this.busy,
    required this.onComplete,
    required this.onUndo,
    required this.onEdit,
    required this.onDetails,
  });

  final Mission mission;
  final bool completed;
  final bool busy;
  final VoidCallback onComplete;
  final VoidCallback onUndo;
  final VoidCallback onEdit;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final description = mission.description.trim();
    final area = mission.areaName.trim();
    final attribute = mission.attributeName.trim();
    final typeColor = _typeColor(mission.type);
    final contentOpacity = completed ? 0.72 : 1.0;

    return AnimatedOpacity(
      duration: GameMotion.fast,
      opacity: contentOpacity,
      child: GameCard(
        showShadow: !completed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed
                        ? GameColors.success.withValues(alpha: 0.14)
                        : typeColor.withValues(alpha: 0.17),
                  ),
                  child: Icon(
                    completed ? Icons.check_circle_rounded : Icons.flag_rounded,
                    color: completed ? GameColors.success : typeColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              mission.title.isEmpty ? 'Missão sem título' : mission.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GameTextStyles.cardTitle.copyWith(
                                decoration: completed ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Editar missão',
                            visualDensity: VisualDensity.compact,
                            onPressed: busy ? null : onEdit,
                            icon: const Icon(Icons.edit_rounded),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GameTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: GameSpacing.sm),
            Wrap(
              spacing: GameSpacing.xs,
              runSpacing: GameSpacing.xs,
              children: [
                if (completed)
                  const GameChip(
                    label: 'Concluída',
                    icon: Icons.verified_rounded,
                    color: GameColors.success,
                    selected: true,
                  ),
                if (mission.isCompound)
                  const GameChip(
                    label: 'Composta',
                    icon: Icons.checklist_rounded,
                    color: GameColors.primary,
                    selected: true,
                  ),
                GameChip(label: mission.typeLabel, icon: Icons.event_repeat_rounded, color: typeColor, selected: true),
                GameChip(label: mission.difficultyLabel, icon: Icons.speed_rounded, color: GameColors.reward, selected: true),
                if (area.isNotEmpty) GameChip(label: area, icon: Icons.category_rounded, color: GameColors.info),
                if (attribute.isNotEmpty) GameChip(label: attribute, icon: Icons.auto_graph_rounded, color: GameColors.success),
              ],
            ),
            const SizedBox(height: GameSpacing.sm),
            Container(
              padding: const EdgeInsets.all(GameSpacing.sm),
              decoration: BoxDecoration(
                color: GameColors.reward.withValues(alpha: 0.10),
                borderRadius: GameRadius.card,
                border: Border.all(color: GameColors.reward.withValues(alpha: 0.24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: GameColors.rewardSoft, size: 20),
                  const SizedBox(width: GameSpacing.xs),
                  Expanded(
                    child: Text(
                      '+${mission.xpReward} XP',
                      style: GameTextStyles.body.copyWith(color: GameColors.rewardSoft),
                    ),
                  ),
                  const Icon(Icons.monetization_on_rounded, color: GameColors.rewardSoft, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '+${mission.coinsReward}',
                    style: GameTextStyles.body.copyWith(color: GameColors.rewardSoft),
                  ),
                ],
              ),
            ),
            if (mission.isCompound) ...[
              const SizedBox(height: GameSpacing.sm),
              FutureBuilder<task_repo.MissionTaskStats>(
                future: task_repo.MissionTaskRepository().getStats(mission.id),
                builder: (context, snapshot) {
                  final stats = snapshot.data;
                  final progress = stats?.progress ?? 0.0;
                  final done = stats?.done ?? 0;
                  final total = stats?.total ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              total == 0 ? 'Checklist vazio' : '$done/$total subtarefas',
                              style: GameTextStyles.caption,
                            ),
                          ),
                          Text('${(progress * 100).round()}%', style: GameTextStyles.caption),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GameProgressBar(value: progress, color: GameColors.primary),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: GameSpacing.sm),
            if (busy)
              const LinearProgressIndicator(minHeight: 3)
            else if (completed) ...[
              const GamePrimaryButton(
                label: 'Concluído neste período',
                icon: Icons.check_circle_rounded,
                onPressed: null,
              ),
              const SizedBox(height: GameSpacing.xs),
              GameSecondaryButton(
                label: 'Desfazer conclusão',
                icon: Icons.undo_rounded,
                onPressed: onUndo,
              ),
              const SizedBox(height: GameSpacing.xs),
              GameSecondaryButton(
                label: mission.isCompound ? 'Abrir checklist' : 'Detalhes da missão',
                icon: mission.isCompound ? Icons.checklist_rounded : Icons.open_in_new_rounded,
                onPressed: onDetails,
              ),
            ] else ...[
              GamePrimaryButton(
                label: mission.isCompound ? 'Concluir missão composta' : 'Concluir missão',
                icon: Icons.check_circle_rounded,
                onPressed: onComplete,
              ),
              const SizedBox(height: GameSpacing.xs),
              GameSecondaryButton(
                label: mission.isCompound ? 'Abrir checklist' : 'Detalhes da missão',
                icon: mission.isCompound ? Icons.checklist_rounded : Icons.open_in_new_rounded,
                onPressed: onDetails,
              ),
              const SizedBox(height: GameSpacing.xs),
              GameSecondaryButton(
                label: 'Editar missão',
                icon: Icons.edit_rounded,
                onPressed: onEdit,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    return switch (type) {
      'daily' => GameColors.success,
      'weekly' => GameColors.primary,
      'monthly' => GameColors.reward,
      'special' => GameColors.info,
      _ => GameColors.primary,
    };
  }
}
