import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/project_repository.dart';
import '../../design_system/game_design_system.dart';
import 'project_detail_screen.dart';

class CompletedProjectsScreen extends StatefulWidget {
  const CompletedProjectsScreen({super.key});

  @override
  State<CompletedProjectsScreen> createState() => _CompletedProjectsScreenState();
}

class _CompletedProjectsScreenState extends State<CompletedProjectsScreen> {
  final ProjectRepository _repository = ProjectRepository();

  List<Project> _projects = const [];
  bool _loading = true;
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
      final projects = await _repository.getCompletedProjects();
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

  Future<void> _openProject(Project project) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: project.id)),
    );

    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: _buildBody());
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final error = _error;
    if (error != null) {
      return _CompletedScrollPage(
        children: [
          GameEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Erro ao carregar concluídos',
            message: error,
            actionLabel: 'Tentar novamente',
            onAction: _load,
          ),
        ],
      );
    }

    final totalXp = _projects.fold<int>(0, (sum, project) => sum + project.xpReward);
    final totalCoins = _projects.fold<int>(0, (sum, project) => sum + project.coinsReward);
    final totalTasks = _projects.fold<int>(0, (sum, project) => sum + project.taskCount);

    return _CompletedScrollPage(
      children: [
        GameHighlightCard(
          accentColor: GameColors.success,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_rounded, color: GameColors.success, size: 34),
              const SizedBox(height: GameSpacing.sm),
              Text('Projetos concluídos', style: GameTextStyles.title),
              const SizedBox(height: GameSpacing.xs),
              Text(
                'Memória das conquistas finalizadas na sua campanha. Cada projeto concluído representa uma entrega real.',
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
                label: 'projetos',
                value: '${_projects.length}',
                icon: Icons.folder_special_rounded,
                color: GameColors.success,
              ),
            ),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: GameStatTile(
                label: 'tarefas',
                value: '$totalTasks',
                icon: Icons.checklist_rounded,
                color: GameColors.discipline,
              ),
            ),
          ],
        ),
        const SizedBox(height: GameSpacing.sm),
        Row(
          children: [
            Expanded(
              child: GameStatTile(
                label: 'XP potencial',
                value: '$totalXp',
                icon: Icons.bolt_rounded,
                color: GameColors.primary,
              ),
            ),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: GameStatTile(
                label: 'coins',
                value: '$totalCoins',
                icon: Icons.monetization_on_rounded,
                color: GameColors.reward,
              ),
            ),
          ],
        ),
        const SizedBox(height: GameSpacing.lg),
        GameSectionHeader(
          title: 'Arquivo de conquistas',
          subtitle: 'Projetos finalizados aparecem aqui em ordem recente.',
          icon: Icons.emoji_events_rounded,
          actionLabel: 'Atualizar',
          onAction: _load,
        ),
        if (_projects.isEmpty)
          const GameEmptyState(
            icon: Icons.verified_rounded,
            title: 'Nenhum projeto concluído ainda',
            message: 'Quando você concluir projetos, eles aparecerão aqui como conquistas da jornada.',
          )
        else
          for (final project in _projects) ...[
            _CompletedProjectCard(
              project: project,
              onTap: () => _openProject(project),
            ),
            const SizedBox(height: GameSpacing.sm),
          ],
        const SizedBox(height: GameSpacing.xl),
      ],
    );
  }
}

class _CompletedScrollPage extends StatelessWidget {
  const _CompletedScrollPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: GameSpacing.screen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _CompletedProjectCard extends StatelessWidget {
  const _CompletedProjectCard({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = GameColors.areaById(project.areaId);
    final completedDate = _formatDate(project.completedAt.isEmpty ? project.updatedAt : project.completedAt);

    return GameCard(
      onTap: onTap,
      borderColor: GameColors.success.withValues(alpha: 0.28),
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
                  color: GameColors.success.withValues(alpha: 0.16),
                ),
                child: const Icon(Icons.verified_rounded, color: GameColors.success, size: 22),
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
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(value: 1, color: GameColors.success, showGlow: true),
          const SizedBox(height: GameSpacing.sm),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              GameChip(label: 'Concluído', icon: Icons.check_rounded, color: GameColors.success, selected: true),
              GameChip(label: completedDate, icon: Icons.event_rounded, color: GameColors.info),
              GameChip(label: '${project.doneTaskCount}/${project.taskCount} tarefas', icon: Icons.checklist_rounded, color: GameColors.discipline),
              GameChip(label: project.areaName, icon: Icons.category_rounded, color: accent),
              GameChip(label: '+${project.xpReward} XP', icon: Icons.bolt_rounded, color: GameColors.primary),
              GameChip(label: '+${project.coinsReward}', icon: Icons.monetization_on_rounded, color: GameColors.reward),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return 'Data indefinida';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }
}
