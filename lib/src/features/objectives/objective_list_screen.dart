import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/objective_repository.dart';
import '../../design_system/game_design_system.dart';
import 'objective_form_screen.dart';

class ObjectiveListScreen extends StatefulWidget {
  const ObjectiveListScreen({super.key});

  @override
  State<ObjectiveListScreen> createState() => _ObjectiveListScreenState();
}

class _ObjectiveListScreenState extends State<ObjectiveListScreen> {
  final ObjectiveRepository _repository = ObjectiveRepository();

  List<Objective> _objectives = const [];
  bool _loading = true;
  String? _error;
  String? _workingObjectiveId;

  @override
  void initState() {
    super.initState();
    _loadObjectives();
  }

  Future<void> _loadObjectives() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final objectives = await _repository.getActiveObjectives();
      if (!mounted) return;

      setState(() {
        _objectives = objectives;
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

  Future<void> _openCreateObjective() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ObjectiveFormScreen()),
    );

    if (created == true && mounted) {
      await _loadObjectives();
    }
  }

  Future<void> _addProgress(Objective objective) async {
    if (_workingObjectiveId != null) return;

    final result = await showDialog<_ProgressDialogResult>(
      context: context,
      builder: (_) => _AddProgressDialog(objective: objective),
    );

    if (!mounted || result == null) return;

    setState(() {
      _workingObjectiveId = objective.id;
    });

    try {
      final saveResult = await _repository.addProgress(
        objective: objective,
        valueDelta: result.valueDelta,
        notes: result.notes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                saveResult.completedNow ? Icons.verified_rounded : Icons.add_chart_rounded,
                color: GameColors.textPrimary,
              ),
              const SizedBox(width: GameSpacing.xs),
              Expanded(child: Text(saveResult.message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: saveResult.completedNow ? GameColors.success : GameColors.surfaceRaised,
        ),
      );

      await _loadObjectives();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar progresso: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: GameColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingObjectiveId = null;
        });
      }
    }
  }

  Future<void> _archiveObjective(Objective objective) async {
    if (_workingObjectiveId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Arquivar objetivo?'),
          content: Text('O objetivo "${objective.title}" vai sair da lista ativa.'),
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

    if (!mounted || confirmed != true) return;

    setState(() {
      _workingObjectiveId = objective.id;
    });

    try {
      await _repository.archiveObjective(objective.id);
      if (mounted) await _loadObjectives();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao arquivar objetivo: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: GameColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingObjectiveId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetivos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loadObjectives,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Novo objetivo',
            onPressed: _openCreateObjective,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateObjective,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo objetivo'),
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
            title: 'Erro ao carregar objetivos',
            message: error,
            actionLabel: 'Tentar novamente',
            onAction: _loadObjectives,
          ),
        ],
      );
    }

    if (_objectives.isEmpty) {
      return _ScrollPage(
        children: [
          const GameHighlightCard(
            accentColor: GameColors.info,
            child: _ObjectiveHeader(
              title: 'Objetivos mensuráveis',
              subtitle: 'Defina metas com alvo numérico, avance em partes e receba recompensa ao concluir.',
              icon: Icons.track_changes_rounded,
            ),
          ),
          const SizedBox(height: GameSpacing.md),
          GameEmptyState(
            icon: Icons.track_changes_rounded,
            title: 'Nenhum objetivo ativo ainda',
            message: 'Crie um objetivo com meta clara para acompanhar progresso real.',
            actionLabel: 'Criar primeiro objetivo',
            onAction: _openCreateObjective,
          ),
        ],
      );
    }

    return _ScrollPage(
      children: [
        GameHighlightCard(
          accentColor: GameColors.info,
          child: _ObjectiveHeader(
            title: '${_objectives.length} objetivo${_objectives.length == 1 ? '' : 's'} ativo${_objectives.length == 1 ? '' : 's'}',
            subtitle: 'Registre avanço parcial e deixe o Game Life concluir automaticamente quando bater a meta.',
            icon: Icons.track_changes_rounded,
          ),
        ),
        const SizedBox(height: GameSpacing.md),
        GameSectionHeader(
          title: 'Metas em andamento',
          subtitle: 'Barras animadas e progresso legível para uso diário.',
          icon: Icons.show_chart_rounded,
          actionLabel: 'Atualizar',
          onAction: _loadObjectives,
        ),
        const SizedBox(height: GameSpacing.xs),
        for (final objective in _objectives) ...[
          _ObjectiveCard(
            objective: objective,
            busy: _workingObjectiveId == objective.id,
            onAddProgress: () => _addProgress(objective),
            onArchive: () => _archiveObjective(objective),
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

class _ObjectiveHeader extends StatelessWidget {
  const _ObjectiveHeader({
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
        Icon(icon, color: GameColors.info, size: 34),
        const SizedBox(height: GameSpacing.sm),
        Text(title, style: GameTextStyles.title),
        const SizedBox(height: GameSpacing.xs),
        Text(subtitle, style: GameTextStyles.body),
      ],
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({
    required this.objective,
    required this.busy,
    required this.onAddProgress,
    required this.onArchive,
  });

  final Objective objective;
  final bool busy;
  final VoidCallback onAddProgress;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final description = objective.description.trim();
    final area = objective.areaName.trim();
    final attribute = objective.attributeName.trim();
    final percent = (objective.progressPercent * 100).round();

    return GameCard(
      showShadow: true,
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
                  color: GameColors.info.withValues(alpha: 0.17),
                ),
                child: const Icon(Icons.track_changes_rounded, color: GameColors.info, size: 23),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      objective.title.isEmpty ? 'Objetivo sem título' : objective.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.cardTitle,
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
              const SizedBox(width: GameSpacing.xs),
              Text(
                '$percent%',
                style: GameTextStyles.cardTitle.copyWith(color: GameColors.rewardSoft),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(
            value: objective.progressPercent,
            color: GameColors.success,
            showGlow: objective.progressPercent >= 0.95,
          ),
          const SizedBox(height: GameSpacing.xs),
          Text(
            objective.progressText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameTextStyles.caption.copyWith(color: GameColors.textSecondary),
          ),
          const SizedBox(height: GameSpacing.sm),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              if (area.isNotEmpty) GameChip(label: area, icon: Icons.category_rounded, color: GameColors.info),
              if (attribute.isNotEmpty) GameChip(label: attribute, icon: Icons.auto_graph_rounded, color: GameColors.success),
              GameChip(label: '+${objective.xpReward} XP', icon: Icons.bolt_rounded, color: GameColors.reward, selected: true),
              GameChip(label: '+${objective.coinsReward} coins', icon: Icons.monetization_on_rounded, color: GameColors.reward, selected: true),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          if (busy)
            const LinearProgressIndicator(minHeight: 3)
          else ...[
            GamePrimaryButton(
              label: 'Adicionar progresso',
              icon: Icons.add_chart_rounded,
              onPressed: onAddProgress,
            ),
            const SizedBox(height: GameSpacing.xs),
            GameSecondaryButton(
              label: 'Arquivar objetivo',
              icon: Icons.archive_outlined,
              onPressed: onArchive,
            ),
          ],
        ],
      ),
    );
  }
}

class _AddProgressDialog extends StatefulWidget {
  const _AddProgressDialog({required this.objective});

  final Objective objective;

  @override
  State<_AddProgressDialog> createState() => _AddProgressDialogState();
}

class _AddProgressDialogState extends State<_AddProgressDialog> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  void _submit() {
    final value = _parseDouble(_valueController.text);
    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um valor maior que zero.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _ProgressDialogResult(
        valueDelta: value,
        notes: _notesController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar progresso'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.objective.title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: GameSpacing.xs),
            Text('Atual: ${widget.objective.progressText}'),
            const SizedBox(height: GameSpacing.sm),
            GameProgressBar(value: widget.objective.progressPercent, color: GameColors.success),
            const SizedBox(height: GameSpacing.md),
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quanto avançou?',
                hintText: 'Ex.: 10 ${widget.objective.unit}',
              ),
            ),
            const SizedBox(height: GameSpacing.sm),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Observação opcional'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _ProgressDialogResult {
  const _ProgressDialogResult({
    required this.valueDelta,
    required this.notes,
  });

  final double valueDelta;
  final String notes;
}
