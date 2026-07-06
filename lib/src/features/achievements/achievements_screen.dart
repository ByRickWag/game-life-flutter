import 'package:flutter/material.dart';

import '../../core/models/v3_commitment_models.dart';
import '../../core/repositories/achievement_repository.dart';
import '../../design_system/game_design_system.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _repository = AchievementRepository();
  late Future<_AchievementsData> _future;
  String _filter = 'all';
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AchievementsData> _load() async {
    final items = await _repository.getAchievements();
    final summary = await _repository.getSummary();
    return _AchievementsData(items: items, summary: summary);
  }

  Future<void> _refresh({bool showMessage = false}) async {
    if (_syncing) return;
    setState(() => _syncing = true);

    try {
      final result = await _repository.refreshAutomaticAchievements();
      if (!mounted) return;
      setState(() => _future = _load());
      await _future;

      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao sincronizar conquistas: $error')));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(showMessage: true),
          child: FutureBuilder<_AchievementsData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError && !snapshot.hasData) {
                return ListView(
                  padding: GameSpacing.screen,
                  children: [
                    GameEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Erro ao carregar conquistas',
                      message: '${snapshot.error}',
                      actionLabel: 'Tentar novamente',
                      onAction: () => setState(() => _future = _load()),
                    ),
                  ],
                );
              }

              final data = snapshot.data ?? const _AchievementsData.empty();
              final filtered = _filtered(data.items);

              return ListView(
                padding: GameSpacing.screen,
                children: [
                  _HeaderCard(
                    summary: data.summary,
                    syncing: _syncing,
                    onSync: () => _refresh(showMessage: true),
                  ),
                  const SizedBox(height: GameSpacing.md),
                  _CategoryFilters(
                    selected: _filter,
                    items: data.items,
                    onSelected: (value) => setState(() => _filter = value),
                  ),
                  const SizedBox(height: GameSpacing.md),
                  GameSectionHeader(
                    title: 'Conquistas',
                    subtitle: '${filtered.length} item(ns) nesta visão.',
                    icon: Icons.emoji_events_rounded,
                  ),
                  const SizedBox(height: GameSpacing.sm),
                  if (filtered.isEmpty)
                    const GameEmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: 'Nenhuma conquista nesta categoria',
                      message: 'Troque o filtro ou sincronize novamente depois de avançar na jornada.',
                    )
                  else
                    for (final item in filtered) ...[
                      _AchievementCard(item: item),
                      const SizedBox(height: GameSpacing.sm),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<HeroAchievementProgress> _filtered(List<HeroAchievementProgress> items) {
    if (_filter == 'all') return items;
    if (_filter == 'unlocked') return items.where((item) => item.isUnlocked).toList();
    if (_filter == 'locked') return items.where((item) => !item.isUnlocked).toList();
    return items.where((item) => item.achievement.category == _filter).toList();
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.summary,
    required this.syncing,
    required this.onSync,
  });

  final AchievementSummary summary;
  final bool syncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final progressPercent = (summary.progress * 100).round();

    return GameHighlightCard(
      accentColor: GameColors.reward,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameColors.reward.withValues(alpha: 0.18),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: GameColors.reward, size: 28),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Conquistas', style: GameTextStyles.title),
                    const SizedBox(height: 2),
                    Text(
                      'Marcos automáticos que reconhecem sua evolução real.',
                      style: GameTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.md),
          GameProgressBar(value: summary.progress, color: GameColors.reward, showGlow: true),
          const SizedBox(height: GameSpacing.xs),
          Text(
            '${summary.unlocked}/${summary.total} desbloqueadas • $progressPercent%',
            style: GameTextStyles.body,
          ),
          const SizedBox(height: GameSpacing.md),
          Row(
            children: [
              Expanded(
                child: GameStatTile(
                  label: 'XP em brasões',
                  value: '${summary.totalXpUnlocked}/${summary.totalXpAvailable}',
                  icon: Icons.bolt_rounded,
                  color: GameColors.info,
                ),
              ),
              const SizedBox(width: GameSpacing.xs),
              Expanded(
                child: GameStatTile(
                  label: 'Bloqueadas',
                  value: '${summary.locked}',
                  icon: Icons.lock_outline_rounded,
                  color: GameColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.md),
          GameSecondaryButton(
            label: syncing ? 'Sincronizando...' : 'Sincronizar conquistas',
            icon: Icons.sync_rounded,
            onPressed: syncing ? null : onSync,
          ),
        ],
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.selected,
    required this.items,
    required this.onSelected,
  });

  final String selected;
  final List<HeroAchievementProgress> items;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = <String>{for (final item in items) item.achievement.category}.toList()
      ..sort((a, b) => _categoryLabel(a).compareTo(_categoryLabel(b)));

    return Wrap(
      spacing: GameSpacing.xs,
      runSpacing: GameSpacing.xs,
      children: [
        GameChip(
          label: 'Todas ${items.length}',
          icon: Icons.apps_rounded,
          color: GameColors.primary,
          selected: selected == 'all',
          onTap: () => onSelected('all'),
        ),
        GameChip(
          label: 'Desbloqueadas ${items.where((item) => item.isUnlocked).length}',
          icon: Icons.lock_open_rounded,
          color: GameColors.success,
          selected: selected == 'unlocked',
          onTap: () => onSelected('unlocked'),
        ),
        GameChip(
          label: 'Bloqueadas ${items.where((item) => !item.isUnlocked).length}',
          icon: Icons.lock_outline_rounded,
          color: GameColors.textMuted,
          selected: selected == 'locked',
          onTap: () => onSelected('locked'),
        ),
        for (final category in categories)
          GameChip(
            label: _categoryLabel(category),
            icon: _categoryIcon(category),
            color: _categoryColor(category),
            selected: selected == category,
            onTap: () => onSelected(category),
          ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});

  final HeroAchievementProgress item;

  @override
  Widget build(BuildContext context) {
    final achievement = item.achievement;
    final progress = achievement.targetValue <= 0
        ? 0.0
        : (item.progressValue / achievement.targetValue).clamp(0.0, 1.0).toDouble();
    final color = item.isUnlocked ? GameColors.reward : _categoryColor(achievement.category);
    final icon = _iconFromKey(achievement.icon);

    return GameCard(
      backgroundColor: item.isUnlocked ? GameColors.surfaceRaised : GameColors.surface,
      borderColor: item.isUnlocked ? GameColors.reward.withValues(alpha: 0.45) : GameColors.borderSoft,
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
                  color: color.withValues(alpha: item.isUnlocked ? 0.22 : 0.14),
                ),
                child: Icon(item.isUnlocked ? Icons.emoji_events_rounded : icon, color: color, size: 24),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GameTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameProgressBar(
            value: progress,
            color: item.isUnlocked ? GameColors.reward : _categoryColor(achievement.category),
            height: 8,
            showGlow: item.isUnlocked,
          ),
          const SizedBox(height: GameSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.isUnlocked
                      ? _unlockedLabel(item.unlockedAt)
                      : '${item.progressValue}/${achievement.targetValue}',
                  style: GameTextStyles.caption,
                ),
              ),
              GameChip(
                label: '+${achievement.xpReward} XP',
                icon: Icons.bolt_rounded,
                color: GameColors.info,
                selected: item.isUnlocked,
              ),
              const SizedBox(width: GameSpacing.xs),
              GameChip(
                label: _categoryLabel(achievement.category),
                icon: _categoryIcon(achievement.category),
                color: _categoryColor(achievement.category),
                selected: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _unlockedLabel(String unlockedAt) {
    if (unlockedAt.trim().isEmpty) return 'Desbloqueada';
    final parsed = DateTime.tryParse(unlockedAt)?.toLocal();
    if (parsed == null) return 'Desbloqueada';
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return 'Desbloqueada em $day/$month/${parsed.year}';
  }
}

class _AchievementsData {
  const _AchievementsData({required this.items, required this.summary});

  const _AchievementsData.empty()
      : items = const [],
        summary = const AchievementSummary(
          total: 0,
          unlocked: 0,
          totalXpAvailable: 0,
          totalXpUnlocked: 0,
        );

  final List<HeroAchievementProgress> items;
  final AchievementSummary summary;
}

String _categoryLabel(String category) {
  return switch (category) {
    'checkin' => 'Check-in',
    'mission' => 'Missões',
    'objective' => 'Objetivos',
    'session' => 'Foco',
    'habit' => 'Hábitos',
    'health' => 'Saúde',
    'project' => 'Projetos',
    'finance' => 'Finanças',
    'campaign' => 'Campanha',
    _ => 'Geral',
  };
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'checkin' => Icons.local_fire_department_rounded,
    'mission' => Icons.flag_rounded,
    'objective' => Icons.track_changes_rounded,
    'session' => Icons.timer_rounded,
    'habit' => Icons.repeat_rounded,
    'health' => Icons.health_and_safety_rounded,
    'project' => Icons.folder_special_rounded,
    'finance' => Icons.savings_rounded,
    'campaign' => Icons.auto_awesome_rounded,
    _ => Icons.emoji_events_rounded,
  };
}

Color _categoryColor(String category) {
  return switch (category) {
    'checkin' => GameColors.reward,
    'mission' => GameColors.success,
    'objective' => GameColors.info,
    'session' => GameColors.primary,
    'habit' => GameColors.discipline,
    'health' => GameColors.vigor,
    'project' => GameColors.responsibility,
    'finance' => GameColors.reward,
    'campaign' => GameColors.faith,
    _ => GameColors.primary,
  };
}

IconData _iconFromKey(String key) {
  return switch (key) {
    'account_balance_wallet' => Icons.account_balance_wallet_rounded,
    'add_chart' => Icons.add_chart_rounded,
    'checklist' => Icons.checklist_rounded,
    'construction' => Icons.construction_rounded,
    'emoji_events' => Icons.emoji_events_rounded,
    'flag' => Icons.flag_rounded,
    'folder_special' => Icons.folder_special_rounded,
    'hourglass_bottom' => Icons.hourglass_bottom_rounded,
    'local_fire_department' => Icons.local_fire_department_rounded,
    'military_tech' => Icons.military_tech_rounded,
    'payments' => Icons.payments_rounded,
    'repeat' => Icons.repeat_rounded,
    'restaurant' => Icons.restaurant_rounded,
    'savings' => Icons.savings_rounded,
    'task_alt' => Icons.task_alt_rounded,
    'timer' => Icons.timer_rounded,
    'today' => Icons.today_rounded,
    'track_changes' => Icons.track_changes_rounded,
    'verified' => Icons.verified_rounded,
    'water_drop' => Icons.water_drop_rounded,
    'workspace_premium' => Icons.workspace_premium_rounded,
    _ => Icons.emoji_events_rounded,
  };
}
