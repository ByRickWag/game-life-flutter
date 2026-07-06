import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../../app/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/game_models.dart';
import '../../../core/repositories/history_repository.dart';
import '../../history/history_screen.dart';

class EvolutionScreen extends StatefulWidget {
  const EvolutionScreen({super.key});

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen> {
  final HistoryRepository _historyRepository = HistoryRepository();

  bool _loading = true;
  Object? _error;
  _EvolutionData? _data;

  @override
  void initState() {
    super.initState();
    _loadEvolution();
  }

  Future<void> _loadEvolution() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _load();
      if (!mounted) return;

      setState(() {
        _data = data;
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

  Future<_EvolutionData> _load() async {
    final Database db = await AppDatabase.instance.database;

    final heroRows = await db.query('hero_profiles', limit: 1);
    final attributeRows = await db.rawQuery('''
      SELECT
        attributes.id,
        attributes.name,
        attributes.description,
        hero_attributes.points,
        hero_attributes.xp
      FROM hero_attributes
      INNER JOIN attributes ON attributes.id = hero_attributes.attribute_id
      ORDER BY attributes.sort_order;
    ''');

    final stats = await _historyRepository.getStats();
    final recentRewards = await _historyRepository.getRecentRewardEvents(limit: 6);

    final attributes = attributeRows.map(AttributeEvolution.fromMap).toList();
    attributes.sort((a, b) => b.xp.compareTo(a.xp));

    return _EvolutionData(
      hero: heroRows.isEmpty ? null : heroRows.first,
      attributes: attributes,
      stats: stats,
      recentRewards: recentRewards,
    );
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );

    if (!mounted) return;
    await _loadEvolution();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _data == null) {
      return _EvolutionError(
        error: _error.toString(),
        onRetry: _loadEvolution,
      );
    }

    final data = _data;
    if (data == null) {
      return _EvolutionError(
        error: 'Evolução sem dados carregados.',
        onRetry: _loadEvolution,
      );
    }

    final hero = data.hero;
    final level = hero == null ? 1 : readInt(hero, 'level');
    final xp = hero == null ? 0 : readInt(hero, 'xp');
    final coins = hero == null ? 0 : readInt(hero, 'coins');
    final strongest = data.attributes.isEmpty ? null : data.attributes.first;
    final totalAttributeXp = data.attributes.fold<int>(0, (sum, item) => sum + item.xp);
    final totalAttributePoints = data.attributes.fold<int>(0, (sum, item) => sum + item.points);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EvolutionPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evolução do herói',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Resumo dos ganhos acumulados em XP, coins, atributos e histórico da jornada.',
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 14),
                  _InfoLine(label: 'Nível atual', value: '$level'),
                  _InfoLine(label: 'XP total do herói', value: '$xp'),
                  _InfoLine(label: 'Coins acumuladas', value: '$coins'),
                  _InfoLine(label: 'XP em atributos', value: '$totalAttributeXp'),
                  _InfoLine(label: 'Pontos de atributo', value: '$totalAttributePoints'),
                  _InfoLine(
                    label: 'Atributo mais treinado',
                    value: strongest == null ? 'Nenhum ainda' : strongest.name,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _openHistory,
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('Abrir histórico completo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionHeader(
              title: 'Resumo do histórico',
              actionLabel: _loading ? 'Atualizando...' : 'Atualizar',
              onPressed: _loading ? null : _loadEvolution,
            ),
            _EvolutionPanel(
              child: Column(
                children: [
                  _InfoLine(label: 'Eventos registrados', value: '${data.stats.totalEvents}'),
                  _InfoLine(label: 'XP pelo histórico', value: '${data.stats.totalXp}'),
                  _InfoLine(label: 'Coins pelo histórico', value: '${data.stats.totalCoins}'),
                  _InfoLine(label: 'Período', value: data.stats.journeyPeriodText),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _SectionHeader(title: 'Atributos'),
            if (data.attributes.isEmpty)
              const _EvolutionPanel(
                child: Text(
                  'Nenhum atributo carregado.',
                  style: TextStyle(color: Colors.white60),
                ),
              )
            else
              for (final attribute in data.attributes) ...[
                _AttributeCard(attribute: attribute),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 4),
            const _SectionHeader(title: 'Recompensas recentes'),
            if (data.recentRewards.isEmpty)
              const _EvolutionPanel(
                child: Text(
                  'Nenhuma recompensa recente ainda.',
                  style: TextStyle(color: Colors.white60),
                ),
              )
            else
              for (final event in data.recentRewards) ...[
                _RewardEventCard(event: event),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _AttributeCard extends StatelessWidget {
  const _AttributeCard({required this.attribute});

  final AttributeEvolution attribute;

  @override
  Widget build(BuildContext context) {
    return _EvolutionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_graph_rounded, color: AppTheme.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attribute.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    if (attribute.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        attribute.description,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${attribute.points} pts',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${attribute.xp} XP',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: attribute.progressToNextPoint,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            attribute.nextPointText,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RewardEventCard extends StatelessWidget {
  const _RewardEventCard({required this.event});

  final HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    return _EvolutionPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star_rounded, color: AppTheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.dateText} • ${event.rewardText}',
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionPanel extends StatelessWidget {
  const _EvolutionPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onPressed,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onPressed,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionError extends StatelessWidget {
  const _EvolutionError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _EvolutionPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
              const SizedBox(height: 10),
              const Text(
                'Erro ao carregar evolução',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(error, style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvolutionData {
  const _EvolutionData({
    required this.hero,
    required this.attributes,
    required this.stats,
    required this.recentRewards,
  });

  final Map<String, Object?>? hero;
  final List<AttributeEvolution> attributes;
  final HistoryStats stats;
  final List<HistoryEvent> recentRewards;
}
