import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../design_system/game_design_system.dart';
import '../sessions/session_list_screen.dart';
import '../sessions/session_timer_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late Future<_FocusData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FocusData> _load() async {
    final db = await AppDatabase.instance.database;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final totalSessions = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM sessions;',
    );
    final todaySessions = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM sessions WHERE created_at >= ? AND created_at < ?;',
      [today.toIso8601String(), tomorrow.toIso8601String()],
    );
    final todayMinutes = await db.rawQuery(
      'SELECT COALESCE(SUM(duration_minutes), 0) AS total FROM sessions WHERE created_at >= ? AND created_at < ?;',
      [today.toIso8601String(), tomorrow.toIso8601String()],
    );
    final weekMinutes = await db.rawQuery(
      'SELECT COALESCE(SUM(duration_minutes), 0) AS total FROM sessions WHERE created_at >= ?;',
      [weekStart.toIso8601String()],
    );
    final totalMinutes = await db.rawQuery(
      'SELECT COALESCE(SUM(duration_minutes), 0) AS total FROM sessions;',
    );
    final totalXp = await db.rawQuery(
      'SELECT COALESCE(SUM(xp_gained), 0) AS total FROM sessions;',
    );
    final recent = await db.rawQuery('''
      SELECT sessions.*, areas.name AS area_name, attributes.name AS attribute_name
      FROM sessions
      LEFT JOIN areas ON areas.id = sessions.area_id
      LEFT JOIN attributes ON attributes.id = sessions.attribute_id
      ORDER BY sessions.created_at DESC
      LIMIT 4;
    ''');
    final byType = await db.rawQuery('''
      SELECT COALESCE(session_type, 'general') AS session_type,
             COUNT(*) AS total,
             COALESCE(SUM(duration_minutes), 0) AS minutes
      FROM sessions
      GROUP BY COALESCE(session_type, 'general')
      ORDER BY minutes DESC
      LIMIT 4;
    ''');

    return _FocusData(
      totalSessions: _readInt(totalSessions.first, 'total'),
      todaySessions: _readInt(todaySessions.first, 'total'),
      todayMinutes: _readInt(todayMinutes.first, 'total'),
      weekMinutes: _readInt(weekMinutes.first, 'total'),
      totalMinutes: _readInt(totalMinutes.first, 'total'),
      totalXp: _readInt(totalXp.first, 'total'),
      recentSessions: recent,
      typeSummaries: byType,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openSessionList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SessionListScreen()),
    );

    if (mounted) _reload();
  }

  Future<void> _openSessionTimer() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SessionTimerScreen()),
    );

    if (created == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FocusData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final error = snapshot.error;
        if (error != null) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: GameSpacing.screen,
              child: GameEmptyState(
                title: 'Erro ao carregar foco',
                message: '$error',
                icon: Icons.warning_rounded,
                actionLabel: 'Tentar novamente',
                onAction: _reload,
              ),
            ),
          );
        }

        final data = snapshot.data ?? _FocusData.empty();
        final todayTarget = 60;
        final todayProgress = (data.todayMinutes / todayTarget).clamp(0.0, 1.0);

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _reload(),
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
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: GameColors.success.withValues(alpha: 0.18),
                              ),
                              child: const Icon(
                                Icons.timer_rounded,
                                color: GameColors.success,
                              ),
                            ),
                            const SizedBox(width: GameSpacing.sm),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Resumo de foco', style: GameTextStyles.title),
                                  SizedBox(height: 2),
                                  Text('Tempo real transformado em progresso.', style: GameTextStyles.caption),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: GameSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_formatDuration(data.todayMinutes), style: GameTextStyles.display),
                            const SizedBox(width: GameSpacing.xs),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 5),
                              child: Text('hoje', style: GameTextStyles.caption),
                            ),
                          ],
                        ),
                        const SizedBox(height: GameSpacing.sm),
                        GameProgressBar(
                          value: todayProgress,
                          color: GameColors.success,
                          showGlow: true,
                        ),
                        const SizedBox(height: GameSpacing.xs),
                        Text(
                          'Meta visual do dia: ${_formatDuration(todayTarget)} de foco registrado.',
                          style: GameTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GameSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: GameStatTile(
                          label: 'Sessões hoje',
                          value: '${data.todaySessions}',
                          icon: Icons.today_rounded,
                          color: GameColors.success,
                        ),
                      ),
                      const SizedBox(width: GameSpacing.sm),
                      Expanded(
                        child: GameStatTile(
                          label: 'Semana',
                          value: _formatDuration(data.weekMinutes),
                          icon: Icons.calendar_month_rounded,
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
                          label: 'Total focado',
                          value: _formatDuration(data.totalMinutes),
                          icon: Icons.hourglass_bottom_rounded,
                          color: GameColors.primary,
                        ),
                      ),
                      const SizedBox(width: GameSpacing.sm),
                      Expanded(
                        child: GameStatTile(
                          label: 'XP por foco',
                          value: '${data.totalXp}',
                          icon: Icons.bolt_rounded,
                          color: GameColors.reward,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GameSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: GamePrimaryButton(
                          label: 'Iniciar foco',
                          icon: Icons.play_arrow_rounded,
                          onPressed: _openSessionTimer,
                        ),
                      ),
                      const SizedBox(width: GameSpacing.sm),
                      Expanded(
                        child: GameSecondaryButton(
                          label: 'Ver sessões',
                          icon: Icons.list_alt_rounded,
                          onPressed: _openSessionList,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GameSpacing.lg),
                  const GameSectionHeader(
                    title: 'Tipos mais usados',
                    subtitle: 'Onde seu tempo focado tem sido investido.',
                    icon: Icons.category_rounded,
                  ),
                  if (data.typeSummaries.isEmpty)
                    const GameEmptyState(
                      title: 'Ainda sem padrão de foco',
                      message: 'Registre algumas sessões para ver seus tipos mais usados.',
                      icon: Icons.pie_chart_rounded,
                    )
                  else
                    GameCard(
                      child: Wrap(
                        spacing: GameSpacing.xs,
                        runSpacing: GameSpacing.xs,
                        children: [
                          for (final item in data.typeSummaries)
                            GameChip(
                              label: '${_typeLabel(_readString(item, 'session_type'))} • ${_formatDuration(_readInt(item, 'minutes'))}',
                              icon: _typeIcon(_readString(item, 'session_type')),
                              color: _typeColor(_readString(item, 'session_type')),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: GameSpacing.lg),
                  const GameSectionHeader(
                    title: 'Sessões recentes',
                    subtitle: 'Últimos blocos registrados na jornada.',
                    icon: Icons.history_rounded,
                  ),
                  if (data.recentSessions.isEmpty)
                    GameEmptyState(
                      title: 'Nenhuma sessão registrada ainda',
                      message: 'Crie seu primeiro bloco de foco para começar a alimentar sua evolução.',
                      icon: Icons.timer_off_rounded,
                      actionLabel: 'Iniciar foco',
                      onAction: _openSessionTimer,
                    )
                  else
                    for (final session in data.recentSessions) ...[
                      _RecentSessionCard(session: session),
                      const SizedBox(height: GameSpacing.sm),
                    ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecentSessionCard extends StatelessWidget {
  const _RecentSessionCard({required this.session});

  final Map<String, Object?> session;

  @override
  Widget build(BuildContext context) {
    final type = _readString(session, 'session_type', fallback: 'general');
    final color = _typeColor(type);

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
              color: color.withValues(alpha: 0.16),
            ),
            child: Icon(_typeIcon(type), color: color, size: 21),
          ),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _readString(session, 'title', fallback: 'Sessão'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.cardTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDuration(_readInt(session, 'duration_minutes'))} • ${_readString(session, 'area_name', fallback: 'Sem área')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.caption,
                ),
                const SizedBox(height: GameSpacing.xs),
                Wrap(
                  spacing: GameSpacing.xs,
                  runSpacing: GameSpacing.xs,
                  children: [
                    GameChip(
                      label: _typeLabel(type),
                      icon: _typeIcon(type),
                      color: color,
                    ),
                    GameChip(
                      label: '+${_readInt(session, 'coins_gained')} coins',
                      icon: Icons.monetization_on_rounded,
                      color: GameColors.reward,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: GameSpacing.xs),
          Text(
            '+${_readInt(session, 'xp_gained')} XP',
            style: GameTextStyles.cardTitle.copyWith(color: GameColors.reward),
          ),
        ],
      ),
    );
  }
}

class _FocusData {
  const _FocusData({
    required this.totalSessions,
    required this.todaySessions,
    required this.todayMinutes,
    required this.weekMinutes,
    required this.totalMinutes,
    required this.totalXp,
    required this.recentSessions,
    required this.typeSummaries,
  });

  factory _FocusData.empty() {
    return const _FocusData(
      totalSessions: 0,
      todaySessions: 0,
      todayMinutes: 0,
      weekMinutes: 0,
      totalMinutes: 0,
      totalXp: 0,
      recentSessions: [],
      typeSummaries: [],
    );
  }

  final int totalSessions;
  final int todaySessions;
  final int todayMinutes;
  final int weekMinutes;
  final int totalMinutes;
  final int totalXp;
  final List<Map<String, Object?>> recentSessions;
  final List<Map<String, Object?>> typeSummaries;
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;

  if (hours <= 0) return '${minutes}min';
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}min';
}

String _readString(Map<String, Object?> map, String key, {String fallback = ''}) {
  final value = map[key];
  if (value == null) return fallback;
  final text = value.toString();
  if (text.trim().isEmpty) return fallback;
  return text;
}

int _readInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _typeLabel(String type) {
  return switch (type) {
    'training' => 'Treino',
    'study' => 'Estudo',
    'devotional' => 'Devocional',
    'programming' => 'Programação',
    'project' => 'Projeto',
    'organization' => 'Organização',
    'reading' => 'Leitura',
    'finance' => 'Finanças',
    _ => 'Geral',
  };
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
