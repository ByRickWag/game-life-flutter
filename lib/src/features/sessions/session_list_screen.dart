import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/session_repository.dart';
import '../../design_system/game_design_system.dart';
import 'session_form_screen.dart';

class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  final _repository = SessionRepository();

  bool _loading = true;
  String? _error;
  List<ManualSession> _sessions = [];
  String _filter = 'all';

  static const _filters = [
    _SessionFilter('all', 'Todas'),
    _SessionFilter('training', 'Treino'),
    _SessionFilter('study', 'Estudo'),
    _SessionFilter('devotional', 'Devocional'),
    _SessionFilter('programming', 'Programação'),
    _SessionFilter('project', 'Projeto'),
    _SessionFilter('organization', 'Organização'),
    _SessionFilter('reading', 'Leitura'),
    _SessionFilter('finance', 'Finanças'),
    _SessionFilter('general', 'Geral'),
  ];

  List<ManualSession> get _visibleSessions {
    if (_filter == 'all') return _sessions;
    return _sessions.where((session) => session.sessionType == _filter).toList();
  }

  int get _totalMinutes {
    return _visibleSessions.fold(0, (total, session) => total + session.durationMinutes);
  }

  int get _totalXp {
    return _visibleSessions.fold(0, (total, session) => total + session.xpGained);
  }

  int get _totalCoins {
    return _visibleSessions.fold(0, (total, session) => total + session.coinsGained);
  }

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sessions = await _repository.getRecentSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
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

  Future<void> _openCreateSession() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SessionFormScreen()),
    );

    if (created == true && mounted) {
      await _loadSessions();
    }
  }

  Future<void> _deleteSession(ManualSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Apagar sessão?'),
          content: Text('A sessão "${session.title}" será excluída e o XP/coins recebidos serão revertidos. Use isso para testes ou registros feitos por engano.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _repository.deleteSession(session);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sessão excluída e recompensas revertidas.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessões'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loadSessions,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSession,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Sessão'),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return SingleChildScrollView(
        padding: GameSpacing.screen,
        child: GameEmptyState(
          title: 'Erro ao carregar sessões',
          message: error,
          icon: Icons.warning_rounded,
          actionLabel: 'Tentar novamente',
          onAction: _loadSessions,
        ),
      );
    }

    final visible = _visibleSessions;

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: GameSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameHighlightCard(
              accentColor: GameColors.success,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.timer_rounded, color: GameColors.success, size: 34),
                  const SizedBox(height: GameSpacing.sm),
                  const Text('Sessões recentes', style: GameTextStyles.title),
                  const SizedBox(height: GameSpacing.xs),
                  const Text(
                    'Blocos de treino, estudo, devocional, programação e projetos registrados na jornada.',
                    style: GameTextStyles.body,
                  ),
                  const SizedBox(height: GameSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: GameStatTile(
                          label: 'Sessões',
                          value: '${visible.length}',
                          icon: Icons.list_alt_rounded,
                          color: GameColors.success,
                        ),
                      ),
                      const SizedBox(width: GameSpacing.sm),
                      Expanded(
                        child: GameStatTile(
                          label: 'Tempo',
                          value: _formatDuration(_totalMinutes),
                          icon: Icons.hourglass_bottom_rounded,
                          color: GameColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GameSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: GameStatTile(
                          label: 'XP',
                          value: '$_totalXp',
                          icon: Icons.bolt_rounded,
                          color: GameColors.primary,
                        ),
                      ),
                      const SizedBox(width: GameSpacing.sm),
                      Expanded(
                        child: GameStatTile(
                          label: 'Coins',
                          value: '$_totalCoins',
                          icon: Icons.monetization_on_rounded,
                          color: GameColors.reward,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: GameSpacing.md),
            const GameSectionHeader(
              title: 'Filtro',
              subtitle: 'Veja sessões por tipo sem usar lista horizontal longa.',
              icon: Icons.filter_alt_rounded,
            ),
            DropdownButtonFormField<String>(
              initialValue: _filter,
              decoration: const InputDecoration(labelText: 'Tipo de sessão'),
              items: _filters
                  .map(
                    (filter) => DropdownMenuItem(
                      value: filter.id,
                      child: Text(filter.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _filter = value);
              },
            ),
            const SizedBox(height: GameSpacing.md),
            if (visible.isEmpty)
              GameEmptyState(
                title: 'Nenhuma sessão encontrada',
                message: _filter == 'all'
                    ? 'Registre uma sessão manual para começar a transformar esforço em progresso.'
                    : 'Nenhuma sessão deste tipo foi registrada ainda.',
                icon: Icons.timer_off_rounded,
                actionLabel: 'Nova sessão',
                onAction: _openCreateSession,
              )
            else
              for (final session in visible) ...[
                _SessionCard(
                  session: session,
                  onDelete: () => _deleteSession(session),
                ),
                const SizedBox(height: GameSpacing.sm),
              ],
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onDelete});

  final ManualSession session;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(session.sessionType);

    return GameCard(
      padding: const EdgeInsets.all(GameSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                ),
                child: Icon(_typeIcon(session.sessionType), color: color, size: 22),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${session.typeLabel} • ${session.durationText}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Apagar sessão',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: GameColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              GameChip(label: session.areaName, icon: Icons.category_rounded, color: GameColors.areaById(session.areaId)),
              GameChip(label: session.attributeName, icon: Icons.auto_awesome_rounded, color: GameColors.attributeById(session.attributeId)),
              GameChip(label: '+${session.xpGained} XP', icon: Icons.bolt_rounded, color: GameColors.primary),
              GameChip(label: '+${session.coinsGained} coins', icon: Icons.monetization_on_rounded, color: GameColors.reward),
              GameChip(label: _formatCreatedAt(session.createdAt), icon: Icons.schedule_rounded, color: GameColors.info),
            ],
          ),
          if (session.notes.trim().isNotEmpty) ...[
            const SizedBox(height: GameSpacing.sm),
            Text(
              session.notes,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GameTextStyles.body,
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionFilter {
  const _SessionFilter(this.id, this.label);

  final String id;
  final String label;
}

String _formatCreatedAt(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return 'Recente';

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');

  return '$day/$month • $hour:$minute';
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;

  if (hours <= 0) return '${minutes}min';
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}min';
}

IconData _typeIcon(String type) {
  return switch (type) {
    'training' => Icons.fitness_center_rounded,
    'study' => Icons.school_rounded,
    'devotional' => Icons.auto_awesome_rounded,
    'programming' => Icons.code_rounded,
    'project' => Icons.folder_special_rounded,
    'organization' => Icons.checklist_rounded,
    'reading' => Icons.menu_book_rounded,
    'finance' => Icons.savings_rounded,
    _ => Icons.timer_rounded,
  };
}

Color _typeColor(String type) {
  return switch (type) {
    'training' => GameColors.strength,
    'study' => GameColors.clarity,
    'devotional' => GameColors.faith,
    'programming' => GameColors.focus,
    'project' => GameColors.reward,
    'organization' => GameColors.discipline,
    'reading' => GameColors.info,
    'finance' => GameColors.responsibility,
    _ => GameColors.success,
  };
}
