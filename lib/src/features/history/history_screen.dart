import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/history_repository.dart';
import '../../design_system/game_design_system.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryRepository _repository = HistoryRepository();

  static const int _pageSize = 5;

  String _filter = 'all';
  int _page = 0;
  bool _loading = true;
  Object? _error;
  HistoryStats _stats = HistoryStats.empty();
  List<HistoryEvent> _events = const [];

  int get _pageCount {
    if (_events.isEmpty) return 1;
    return ((_events.length - 1) ~/ _pageSize) + 1;
  }

  List<HistoryEvent> get _pageEvents {
    final start = _page * _pageSize;
    if (start >= _events.length) return const [];

    final end = start + _pageSize;
    if (end > _events.length) return _events.sublist(start);
    return _events.sublist(start, end);
  }

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
      final stats = await _repository.getStats();
      final events = await _repository.getEvents(filter: _filter, limit: 160);
      if (!mounted) return;

      setState(() {
        _stats = stats;
        _events = events;
        if (_page >= _pageCount) _page = 0;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _changeFilter(String? filter) async {
    final selected = filter ?? 'all';
    if (_filter == selected) return;

    setState(() {
      _filter = selected;
      _page = 0;
    });

    await _load();
  }

  void _previousPage() {
    if (_page <= 0) return;
    setState(() => _page -= 1);
  }

  void _nextPage() {
    if (_page >= _pageCount - 1) return;
    setState(() => _page += 1);
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: SingleChildScrollView(
        padding: GameSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(stats: _stats, loading: _loading, onRefresh: _load),
            const SizedBox(height: GameSpacing.md),
            _StatsGrid(stats: _stats),
            const SizedBox(height: GameSpacing.md),
            GameSectionHeader(
              title: 'Linha do tempo',
              subtitle: 'Eventos registrados no banco local.',
              icon: Icons.timeline_rounded,
              actionLabel: _loading ? null : 'Atualizar',
              onAction: _loading ? null : _load,
            ),
            _FilterDropdown(
              selected: _filter,
              onChanged: _loading ? null : _changeFilter,
            ),
            const SizedBox(height: GameSpacing.sm),
            _buildEventArea(),
            const SizedBox(height: GameSpacing.sm),
            _PaginationBar(
              page: _page,
              pageCount: _pageCount,
              canPrevious: _page > 0,
              canNext: _page < _pageCount - 1,
              onPrevious: _previousPage,
              onNext: _nextPage,
            ),
            const SizedBox(height: GameSpacing.md),
          ],
        ),
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildEventArea() {
    if (_loading && _events.isEmpty) {
      return const GameEmptyState(
        icon: Icons.hourglass_empty_rounded,
        title: 'Carregando histórico...',
        message: 'Buscando seus eventos salvos no banco local.',
      );
    }

    if (_error != null && _events.isEmpty) {
      return GameEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Erro ao carregar histórico',
        message: _error.toString(),
        actionLabel: 'Tentar novamente',
        onAction: _load,
      );
    }

    final events = _pageEvents;

    if (events.isEmpty) {
      return const GameEmptyState(
        icon: Icons.history_toggle_off_rounded,
        title: 'Nenhum evento encontrado',
        message: 'Esse filtro ainda não tem eventos registrados.',
      );
    }

    return Column(
      children: [
        for (final event in events) ...[
          _EventTile(event: event),
          const SizedBox(height: GameSpacing.sm),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.stats,
    required this.loading,
    required this.onRefresh,
  });

  final HistoryStats stats;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return GameHighlightCard(
      accentColor: GameColors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameColors.info.withValues(alpha: 0.18),
                ),
                child: const Icon(Icons.timeline_rounded, color: GameColors.info),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Histórico', style: GameTextStyles.title),
                    const SizedBox(height: 2),
                    Text(
                      'Memória compacta da jornada Transformação 20–25.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.md),
          Text(
            'Período: ${stats.journeyPeriodText}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameTextStyles.caption,
          ),
          if (loading) ...[
            const SizedBox(height: GameSpacing.sm),
            const LinearProgressIndicator(minHeight: 4),
          ],
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final HistoryStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GameStatTile(
                label: 'Eventos',
                value: '${stats.totalEvents}',
                icon: Icons.event_note_rounded,
                color: GameColors.info,
              ),
            ),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: GameStatTile(
                label: 'XP',
                value: '${stats.totalXp}',
                icon: Icons.bolt_rounded,
                color: GameColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: GameSpacing.sm),
        Row(
          children: [
            Expanded(
              child: GameStatTile(
                label: 'Coins',
                value: '${stats.totalCoins}',
                icon: Icons.monetization_on_rounded,
                color: GameColors.reward,
              ),
            ),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: GameStatTile(
                label: 'Sessões',
                value: '${stats.sessionEvents}',
                icon: Icons.timer_rounded,
                color: GameColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({required this.selected, required this.onChanged});

  final String selected;
  final Future<void> Function(String? value)? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: const InputDecoration(
        labelText: 'Filtro do histórico',
        prefixIcon: Icon(Icons.filter_alt_rounded),
      ),
      items: HistoryRepository.filters
          .map(
            (filter) => DropdownMenuItem<String>(
              value: filter.id,
              child: Text(filter.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final HistoryEvent event;

  IconData get _icon {
    return switch (event.type) {
      'mission_completion' => Icons.flag_rounded,
      'objective_completion' => Icons.track_changes_rounded,
      'objective_progress' => Icons.add_chart_rounded,
      'manual_session' => Icons.timer_rounded,
      'project_completion' => Icons.folder_special_rounded,
      'system' => Icons.settings_rounded,
      _ => Icons.history_rounded,
    };
  }

  Color get _color {
    return switch (event.type) {
      'mission_completion' => GameColors.primary,
      'objective_completion' => GameColors.info,
      'objective_progress' => GameColors.info,
      'manual_session' => GameColors.success,
      'project_completion' => GameColors.reward,
      'system' => GameColors.textMuted,
      _ => GameColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GameCard(
      padding: const EdgeInsets.all(GameSpacing.md),
      backgroundColor: GameColors.surfaceSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withValues(alpha: 0.16),
            ),
            child: Icon(_icon, color: _color, size: 21),
          ),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.cardTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.typeLabel} • ${event.dateText}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.caption,
                ),
                if (event.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GameTextStyles.caption.copyWith(color: GameColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: GameSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 86),
            child: Text(
              event.rewardText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: GameTextStyles.caption.copyWith(
                color: event.xpDelta != 0 || event.coinsDelta != 0 ? GameColors.reward : GameColors.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.pageCount,
    required this.canPrevious,
    required this.canNext,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int pageCount;
  final bool canPrevious;
  final bool canNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      padding: const EdgeInsets.symmetric(horizontal: GameSpacing.sm, vertical: GameSpacing.xs),
      backgroundColor: GameColors.surfaceSoft,
      child: Row(
        children: [
          IconButton(
            onPressed: canPrevious ? onPrevious : null,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Anterior',
          ),
          Expanded(
            child: Text(
              'Página ${page + 1} de $pageCount',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameTextStyles.caption,
            ),
          ),
          IconButton(
            onPressed: canNext ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Próxima',
          ),
        ],
      ),
    );
  }
}
