import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/models/game_models.dart';
import '../../core/repositories/system_repository.dart';
import '../../design_system/game_design_system.dart';
import '../achievements/achievements_screen.dart';
import '../campaign/campaign_screen.dart';
import '../checkins/checkin_screen.dart';
import '../habits/habit_form_screen.dart';
import '../habits/habit_list_screen.dart';
import '../health/health_screen.dart';
import '../history/history_screen.dart';
import '../missions/mission_form_screen.dart';
import '../missions/mission_list_screen.dart';
import '../objectives/objective_form_screen.dart';
import '../objectives/objective_list_screen.dart';
import '../projects/completed_projects_screen.dart';
import '../projects/project_form_screen.dart';
import '../projects/project_list_screen.dart';
import '../projects/project_tasks_screen.dart';
import '../sessions/session_form_screen.dart';
import '../sessions/session_list_screen.dart';
import '../sessions/session_timer_screen.dart';
import '../shop/shop_item_form_screen.dart';
import '../shop/shop_screen.dart';
import '../system/about_v1_screen.dart';
import '../system/system_report_screen.dart';
import '../vaults/vault_form_screen.dart';
import '../vaults/vault_screen.dart';

class V2ActionSpec {
  const V2ActionSpec({
    required this.label,
    required this.description,
    required this.icon,
    this.destination,
    this.onPressed,
    this.color = GameColors.primary,
  });

  final String label;
  final String description;
  final IconData icon;
  final Widget? destination;
  final VoidCallback? onPressed;
  final Color color;
}

class V2ActionHubPage extends StatelessWidget {
  const V2ActionHubPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actions,
    this.accentColor = GameColors.primary,
    this.note,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<V2ActionSpec> actions;
  final Color accentColor;
  final String? note;

  Future<void> _open(BuildContext context, V2ActionSpec action) async {
    final destination = action.destination;
    final onPressed = action.onPressed;

    if (destination != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => destination),
      );
      return;
    }

    onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: GameSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameHighlightCard(
              accentColor: accentColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: accentColor, size: 32),
                  const SizedBox(height: GameSpacing.sm),
                  Text(title, style: GameTextStyles.title),
                  const SizedBox(height: GameSpacing.xs),
                  Text(subtitle, style: GameTextStyles.body),
                ],
              ),
            ),
            const SizedBox(height: GameSpacing.md),
            const GameSectionHeader(
              title: 'Ações disponíveis',
              subtitle: 'Atalhos seguros para as principais ações do app.',
              icon: Icons.touch_app_rounded,
            ),
            for (final action in actions) ...[
              _V2ActionTile(
                action: action,
                onTap: () => _open(context, action),
              ),
              const SizedBox(height: GameSpacing.sm),
            ],
            if (note != null) ...[
              const SizedBox(height: GameSpacing.xs),
              GameCard(
                backgroundColor: GameColors.surfaceSoft,
                child: Text(note!, style: GameTextStyles.caption),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _V2ActionTile extends StatelessWidget {
  const _V2ActionTile({
    required this.action,
    required this.onTap,
  });

  final V2ActionSpec action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      onTap: onTap,
      padding: const EdgeInsets.all(GameSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: action.color.withValues(alpha: 0.16),
            ),
            child: Icon(action.icon, color: action.color, size: 22),
          ),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  action.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: GameSpacing.xs),
          const Icon(Icons.chevron_right_rounded, color: GameColors.textMuted),
        ],
      ),
    );
  }
}

class V2QuickActionsPage extends StatelessWidget {
  const V2QuickActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const V2ActionHubPage(
      title: 'Ações rápidas',
      subtitle: 'Centralize aqui as ações de execução: criar, concluir, registrar e atualizar progresso.',
      icon: Icons.flash_on_rounded,
      accentColor: GameColors.reward,
      note: 'O Dashboard agora fica mais limpo. As ações de execução ficam reunidas nesta tela.',
      actions: [
        V2ActionSpec(
          label: 'Check-in diário',
          description: 'Registre presença hoje e mantenha sua sequência ativa.',
          icon: Icons.local_fire_department_rounded,
          destination: CheckInScreen(),
          color: GameColors.reward,
        ),
        V2ActionSpec(
          label: 'Criar missão',
          description: 'Crie uma missão diária, semanal, mensal ou especial.',
          icon: Icons.flag_rounded,
          destination: MissionFormScreen(),
          color: GameColors.success,
        ),
        V2ActionSpec(
          label: 'Registrar hábito',
          description: 'Abra hábitos para registrar água, treino, leitura ou consumo.',
          icon: Icons.repeat_rounded,
          destination: HabitListScreen(),
          color: GameColors.vigor,
        ),
        V2ActionSpec(
          label: 'Água e alimentação',
          description: 'Registre água e controle limites de refrigerante, doces e ultraprocessados.',
          icon: Icons.health_and_safety_rounded,
          destination: HealthScreen(),
          color: GameColors.info,
        ),
        V2ActionSpec(
          label: 'Conquistas',
          description: 'Veja brasões desbloqueados e sincronize seu progresso automático.',
          icon: Icons.emoji_events_rounded,
          destination: AchievementsScreen(),
          color: GameColors.reward,
        ),
        V2ActionSpec(
          label: 'Campanha principal',
          description: 'Veja os marcos automáticos da Transformação dos 20 aos 25.',
          icon: Icons.map_rounded,
          destination: CampaignScreen(),
          color: GameColors.faith,
        ),
        V2ActionSpec(
          label: 'Criar hábito',
          description: 'Configure um hábito de construção, redução, manutenção ou evitação.',
          icon: Icons.add_task_rounded,
          destination: HabitFormScreen(),
          color: GameColors.success,
        ),
        V2ActionSpec(
          label: 'Concluir missão',
          description: 'Abra a lista de missões ativas para concluir uma ação.',
          icon: Icons.check_circle_rounded,
          destination: MissionListScreen(),
          color: GameColors.successSoft,
        ),
        V2ActionSpec(
          label: 'Criar objetivo',
          description: 'Crie uma meta mensurável com progresso numérico.',
          icon: Icons.track_changes_rounded,
          destination: ObjectiveFormScreen(),
          color: GameColors.info,
        ),
        V2ActionSpec(
          label: 'Atualizar objetivo',
          description: 'Abra seus objetivos para registrar avanço ou concluir metas.',
          icon: Icons.add_chart_rounded,
          destination: ObjectiveListScreen(),
          color: GameColors.clarity,
        ),
        V2ActionSpec(
          label: 'Iniciar sessão com contador',
          description: 'Abra o contador de foco com check-in de presença e teto de XP.',
          icon: Icons.play_circle_fill_rounded,
          destination: SessionTimerScreen(),
          color: GameColors.primary,
        ),
        V2ActionSpec(
          label: 'Registrar sessão manual',
          description: 'Informe uma duração manualmente quando já souber o tempo dedicado.',
          icon: Icons.edit_calendar_rounded,
          destination: SessionFormScreen(),
          color: GameColors.info,
        ),
        V2ActionSpec(
          label: 'Cofre do Reino',
          description: 'Registre depósitos, retiradas e metas financeiras reais.',
          icon: Icons.savings_rounded,
          destination: VaultScreen(),
          color: GameColors.reward,
        ),
        V2ActionSpec(
          label: 'Loja do Reino',
          description: 'Compre recompensas com coins e libere compras reais planejadas.',
          icon: Icons.storefront_rounded,
          destination: ShopScreen(),
          color: GameColors.primary,
        ),
        V2ActionSpec(
          label: 'Criar item da loja',
          description: 'Configure um voucher, recompensa ou compra real com cofre vinculado.',
          icon: Icons.add_shopping_cart_rounded,
          destination: ShopItemFormScreen(),
          color: GameColors.success,
        ),
        V2ActionSpec(
          label: 'Criar cofre',
          description: 'Abra uma reserva, meta de compra ou caixinha do reino.',
          icon: Icons.account_balance_wallet_rounded,
          destination: VaultFormScreen(),
          color: GameColors.responsibility,
        ),
        V2ActionSpec(
          label: 'Novo projeto',
          description: 'Crie um projeto com tarefas e progresso.',
          icon: Icons.create_new_folder_rounded,
          destination: ProjectFormScreen(),
          color: GameColors.reward,
        ),
        V2ActionSpec(
          label: 'Projetos e tarefas',
          description: 'Abra seus projetos ativos para acompanhar tarefas.',
          icon: Icons.folder_special_rounded,
          destination: ProjectListScreen(),
          color: GameColors.reward,
        ),
      ],
    );
  }
}

class V2MissionHubPage extends StatelessWidget {
  const V2MissionHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const V2ActionHubPage(
      title: 'Missões',
      subtitle: 'Rotinas recorrentes e desafios pontuais que geram XP, coins e atributos.',
      icon: Icons.flag_rounded,
      actions: [
        V2ActionSpec(
          label: 'Ver missões',
          description: 'Abra a lista de missões ativas e conclua ações.',
          icon: Icons.list_alt_rounded,
          destination: MissionListScreen(),
        ),
        V2ActionSpec(
          label: 'Criar missão',
          description: 'Adicione uma missão diária, semanal, mensal ou especial.',
          icon: Icons.add_circle_rounded,
          destination: MissionFormScreen(),
          color: GameColors.success,
        ),
        V2ActionSpec(
          label: 'Ver hábitos',
          description: 'Acompanhe hábitos de construção e redução gradual.',
          icon: Icons.repeat_rounded,
          destination: HabitListScreen(),
          color: GameColors.vigor,
        ),
        V2ActionSpec(
          label: 'Saúde prática',
          description: 'Abra água e alimentação para registrar hidratação e limites semanais.',
          icon: Icons.health_and_safety_rounded,
          destination: HealthScreen(),
          color: GameColors.info,
        ),
        V2ActionSpec(
          label: 'Criar hábito',
          description: 'Crie metas de água, treino, leitura ou limites de consumo.',
          icon: Icons.add_task_rounded,
          destination: HabitFormScreen(),
          color: GameColors.success,
        ),
      ],
    );
  }
}

class V2ObjectiveHubPage extends StatelessWidget {
  const V2ObjectiveHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const V2ActionHubPage(
      title: 'Objetivos',
      subtitle: 'Metas mensuráveis para acompanhar avanço real até a conclusão.',
      icon: Icons.track_changes_rounded,
      accentColor: GameColors.info,
      actions: [
        V2ActionSpec(
          label: 'Ver objetivos',
          description: 'Abra objetivos ativos, registre progresso e conclua metas.',
          icon: Icons.list_alt_rounded,
          destination: ObjectiveListScreen(),
          color: GameColors.info,
        ),
        V2ActionSpec(
          label: 'Criar objetivo',
          description: 'Defina uma meta com unidade, alvo e recompensa.',
          icon: Icons.add_circle_rounded,
          destination: ObjectiveFormScreen(),
          color: GameColors.success,
        ),
      ],
    );
  }
}

class V2CampaignPage extends StatelessWidget {
  const V2CampaignPage({super.key});

  Future<_CampaignData> _loadCampaignData() async {
    final db = await AppDatabase.instance.database;
    final campaignRows = await db.query(
      'campaigns',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    final heroRows = await db.query('hero_profiles', limit: 1);
    final stats = await const SystemRepository().getStats();

    return _CampaignData(
      campaign: campaignRows.isEmpty ? null : campaignRows.first,
      hero: heroRows.isEmpty ? null : heroRows.first,
      stats: stats,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CampaignData>(
      future: _loadCampaignData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final campaign = data?.campaign ?? const <String, Object?>{};
        final hero = data?.hero ?? const <String, Object?>{};
        final stats = data?.stats;
        final title = readString(campaign, 'title', fallback: 'Transformação 20–25');
        final description = readString(
          campaign,
          'description',
          fallback: 'Campanha principal de evolução pessoal do Game Life.',
        );
        final level = (hero.isEmpty ? 1 : readInt(hero, 'level'));
        final xp = readInt(hero, 'xp');
        final coins = readInt(hero, 'coins');

        return SafeArea(
          child: SingleChildScrollView(
            padding: GameSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameHighlightCard(
                  accentColor: GameColors.faith,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: GameColors.faith, size: 34),
                      const SizedBox(height: GameSpacing.sm),
                      Text(title, style: GameTextStyles.title),
                      const SizedBox(height: GameSpacing.xs),
                      Text(description, style: GameTextStyles.body),
                    ],
                  ),
                ),
                const SizedBox(height: GameSpacing.md),
                const GameSectionHeader(
                  title: 'Resumo da campanha',
                  subtitle: 'Estado geral da jornada ativa.',
                  icon: Icons.map_rounded,
                ),
                GameStatTile(
                  label: 'Nível do herói',
                  value: '$level',
                  icon: Icons.star_rounded,
                  color: GameColors.primary,
                ),
                const SizedBox(height: GameSpacing.sm),
                GameStatTile(
                  label: 'XP acumulado',
                  value: '$xp',
                  icon: Icons.bolt_rounded,
                  color: GameColors.info,
                ),
                const SizedBox(height: GameSpacing.sm),
                GameStatTile(
                  label: 'Coins disponíveis',
                  value: '$coins',
                  icon: Icons.monetization_on_rounded,
                  color: GameColors.reward,
                ),
                const SizedBox(height: GameSpacing.sm),
                GameStatTile(
                  label: 'Eventos no histórico',
                  value: '${stats?.historyEvents ?? 0}',
                  icon: Icons.history_rounded,
                  color: GameColors.success,
                ),
                const SizedBox(height: GameSpacing.md),
                const GameSectionHeader(
                  title: 'Estrutura da Jornada',
                  subtitle: 'A campanha conecta missões, objetivos e progresso pessoal.',
                  icon: Icons.account_tree_rounded,
                ),
                const GameCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fase atual', style: GameTextStyles.cardTitle),
                      SizedBox(height: GameSpacing.xs),
                      Text(
                        'Visual premium, navegação por grupos e telas refinadas sobre a base estável do app.',
                        style: GameTextStyles.body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GameSpacing.sm),
                GameCard(
                  backgroundColor: GameColors.surfaceSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Marcadores da jornada', style: GameTextStyles.cardTitle),
                      const SizedBox(height: GameSpacing.sm),
                      Wrap(
                        spacing: GameSpacing.xs,
                        runSpacing: GameSpacing.xs,
                        children: [
                          GameChip(label: '${stats?.missions ?? 0} missões', icon: Icons.flag_rounded, color: GameColors.primary),
                          GameChip(label: '${stats?.habits ?? 0} hábitos', icon: Icons.repeat_rounded, color: GameColors.vigor),
                          GameChip(label: '${stats?.objectives ?? 0} objetivos', icon: Icons.track_changes_rounded, color: GameColors.info),
                          GameChip(label: '${stats?.sessions ?? 0} sessões', icon: Icons.timer_rounded, color: GameColors.success),
                          GameChip(label: '${stats?.projects ?? 0} projetos', icon: Icons.folder_special_rounded, color: GameColors.reward),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CampaignData {
  const _CampaignData({
    required this.campaign,
    required this.hero,
    required this.stats,
  });

  final Map<String, Object?>? campaign;
  final Map<String, Object?>? hero;
  final SystemStats stats;
}

class V2FocusRegisterPage extends StatelessWidget {
  const V2FocusRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: GameSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GameHighlightCard(
              accentColor: GameColors.success,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.timer_rounded, color: GameColors.success, size: 34),
                  SizedBox(height: GameSpacing.sm),
                  Text('Sessão com contador', style: GameTextStyles.title),
                  SizedBox(height: GameSpacing.xs),
                  Text(
                    'Inicie um bloco de foco com contador, check-in de presença, teto de XP e histórico.',
                    style: GameTextStyles.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: GameSpacing.md),
            const GameSectionHeader(
              title: 'Atalhos de foco',
              subtitle: 'Tipos principais da Transformação 20–25.',
              icon: Icons.flash_on_rounded,
            ),
            const _FocusTypeGrid(),
            const SizedBox(height: GameSpacing.md),
            GamePrimaryButton(
              label: 'Iniciar contador',
              icon: Icons.play_circle_fill_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SessionTimerScreen()),
              ),
            ),
            const SizedBox(height: GameSpacing.sm),
            GameSecondaryButton(
              label: 'Registrar manualmente',
              icon: Icons.edit_calendar_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SessionFormScreen()),
              ),
            ),
            const SizedBox(height: GameSpacing.sm),
            GameSecondaryButton(
              label: 'Ver sessões registradas',
              icon: Icons.history_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SessionListScreen()),
              ),
            ),
            const SizedBox(height: GameSpacing.md),
            const GameCard(
              backgroundColor: GameColors.surfaceSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Como usar', style: GameTextStyles.cardTitle),
                  SizedBox(height: GameSpacing.xs),
                  Text(
                    'Registre sessões quando fizer treino, estudo, devocional, programação, leitura, organização ou projetos. Sessões são ideais para esforços que não são missões recorrentes nem objetivos mensuráveis.',
                    style: GameTextStyles.body,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusTypeGrid extends StatelessWidget {
  const _FocusTypeGrid();

  static const _items = [
    _FocusTypeItem('Treino', Icons.fitness_center_rounded, GameColors.strength),
    _FocusTypeItem('Estudo', Icons.school_rounded, GameColors.clarity),
    _FocusTypeItem('Devocional', Icons.auto_awesome_rounded, GameColors.faith),
    _FocusTypeItem('Programação', Icons.code_rounded, GameColors.focus),
    _FocusTypeItem('Projeto', Icons.folder_special_rounded, GameColors.reward),
    _FocusTypeItem('Organização', Icons.checklist_rounded, GameColors.discipline),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < _items.length; index += 2) ...[
          Row(
            children: [
              Expanded(child: _FocusTypeCard(item: _items[index])),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: index + 1 < _items.length
                    ? _FocusTypeCard(item: _items[index + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
        ],
      ],
    );
  }
}

class _FocusTypeCard extends StatelessWidget {
  const _FocusTypeCard({required this.item});

  final _FocusTypeItem item;

  @override
  Widget build(BuildContext context) {
    return GameCompactCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SessionTimerScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color),
          const SizedBox(height: GameSpacing.xs),
          Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
          const SizedBox(height: 2),
          Text('Iniciar timer', maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
        ],
      ),
    );
  }
}

class _FocusTypeItem {
  const _FocusTypeItem(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class V2SessionsRecentPage extends StatelessWidget {
  const V2SessionsRecentPage({super.key});

  Future<List<Map<String, Object?>>> _loadRecent() async {
    final db = await AppDatabase.instance.database;
    return db.rawQuery('''
      SELECT sessions.*, areas.name AS area_name, attributes.name AS attribute_name
      FROM sessions
      LEFT JOIN areas ON areas.id = sessions.area_id
      LEFT JOIN attributes ON attributes.id = sessions.attribute_id
      ORDER BY sessions.created_at DESC
      LIMIT 5;
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: _loadRecent(),
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <Map<String, Object?>>[];

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: GameSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const GameHighlightCard(
                  accentColor: GameColors.info,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.history_rounded, color: GameColors.info, size: 34),
                      SizedBox(height: GameSpacing.sm),
                      Text('Sessões recentes', style: GameTextStyles.title),
                      SizedBox(height: GameSpacing.xs),
                      Text('Revise seus últimos blocos de foco sem sair do grupo Foco.', style: GameTextStyles.body),
                    ],
                  ),
                ),
                const SizedBox(height: GameSpacing.md),
                if (sessions.isEmpty)
                  GameEmptyState(
                    title: 'Nenhuma sessão registrada',
                    message: 'Registre sua primeira sessão para começar a alimentar este painel.',
                    icon: Icons.timer_off_rounded,
                    actionLabel: 'Iniciar contador',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SessionTimerScreen()),
                    ),
                  )
                else
                  for (final session in sessions) ...[
                    _V2RecentSessionTile(session: session),
                    const SizedBox(height: GameSpacing.sm),
                  ],
                const SizedBox(height: GameSpacing.md),
                GamePrimaryButton(
                  label: 'Iniciar contador',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SessionTimerScreen()),
                  ),
                ),
                const SizedBox(height: GameSpacing.sm),
                GameSecondaryButton(
                  label: 'Abrir lista completa',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SessionListScreen()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _V2RecentSessionTile extends StatelessWidget {
  const _V2RecentSessionTile({required this.session});

  final Map<String, Object?> session;

  @override
  Widget build(BuildContext context) {
    final type = _readString(session, 'session_type', fallback: 'general');
    final color = _sessionTypeColor(type);

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
            child: Icon(_sessionTypeIcon(type), color: color, size: 21),
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
                  '${_readInt(session, 'duration_minutes')}min • ${_readString(session, 'area_name', fallback: 'Sem área')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.caption,
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

IconData _sessionTypeIcon(String type) {
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

Color _sessionTypeColor(String type) {
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

class V2ProjectsActivePage extends StatelessWidget {
  const V2ProjectsActivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProjectListScreen(embedded: true);
  }
}

class V2ProjectTasksPage extends StatelessWidget {
  const V2ProjectTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProjectTasksScreen();
  }
}

class V2ProjectsCompletedPage extends StatelessWidget {
  const V2ProjectsCompletedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompletedProjectsScreen();
  }
}

class V2HeroPage extends StatelessWidget {
  const V2HeroPage({super.key});

  Future<Map<String, Object?>?> _loadHero() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('hero_profiles', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Object?>?>(
      future: _loadHero(),
      builder: (context, snapshot) {
        final hero = snapshot.data;
        final level = hero == null ? 1 : readInt(hero, 'level');
        final xp = readInt(hero ?? const <String, Object?>{}, 'xp');
        final coins = readInt(hero ?? const <String, Object?>{}, 'coins');
        final name = readString(hero ?? const <String, Object?>{}, 'name', fallback: 'Herói da Jornada');
        final title = readString(hero ?? const <String, Object?>{}, 'title', fallback: 'Iniciante da Transformação');

        return SafeArea(
          child: SingleChildScrollView(
            padding: GameSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameHighlightCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_rounded, color: GameColors.rewardSoft, size: 36),
                      const SizedBox(height: GameSpacing.sm),
                      Text(name, style: GameTextStyles.title),
                      const SizedBox(height: GameSpacing.xs),
                      Text(title, style: GameTextStyles.body),
                    ],
                  ),
                ),
                const SizedBox(height: GameSpacing.md),
                GameStatTile(
                  label: 'Nível atual',
                  value: '$level',
                  icon: Icons.star_rounded,
                  color: GameColors.primary,
                ),
                const SizedBox(height: GameSpacing.sm),
                GameStatTile(
                  label: 'XP acumulado',
                  value: '$xp',
                  icon: Icons.bolt_rounded,
                  color: GameColors.info,
                ),
                const SizedBox(height: GameSpacing.sm),
                GameStatTile(
                  label: 'Coins',
                  value: '$coins',
                  icon: Icons.monetization_on_rounded,
                  color: GameColors.reward,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class V2ReportPage extends StatelessWidget {
  const V2ReportPage({super.key});

  Future<SystemStats> _loadStats() {
    return const SystemRepository().getStats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SystemStats>(
      future: _loadStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data;

        return SafeArea(
          child: SingleChildScrollView(
            padding: GameSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const GameHighlightCard(
                  accentColor: GameColors.info,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description_rounded, color: GameColors.info, size: 34),
                      SizedBox(height: GameSpacing.sm),
                      Text('Relatório', style: GameTextStyles.title),
                      SizedBox(height: GameSpacing.xs),
                      Text(
                        'Resumo simples da jornada atual. O relatório completo continua disponível em Sistema.',
                        style: GameTextStyles.body,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GameSpacing.md),
                GameStatTile(
                  label: 'Missões',
                  value: '${stats?.missions ?? 0}',
                  icon: Icons.flag_rounded,
                ),
                const SizedBox(height: GameSpacing.sm),
                GameStatTile(
                  label: 'Objetivos',
                  value: '${stats?.objectives ?? 0}',
                  icon: Icons.track_changes_rounded,
                  color: GameColors.info,
                ),
                const SizedBox(height: GameSpacing.sm),
                GameStatTile(
                  label: 'Hábitos',
                  value: '${stats?.habits ?? 0}',
                  icon: Icons.repeat_rounded,
                  color: GameColors.vigor,
                ),
                const SizedBox(height: GameSpacing.sm),
                GameStatTile(
                  label: 'Sessões',
                  value: '${stats?.sessions ?? 0}',
                  icon: Icons.timer_rounded,
                  color: GameColors.success,
                ),
                const SizedBox(height: GameSpacing.sm),
                GameStatTile(
                  label: 'Projetos',
                  value: '${stats?.projects ?? 0}',
                  icon: Icons.folder_special_rounded,
                  color: GameColors.reward,
                ),
                const SizedBox(height: GameSpacing.md),
                GameSecondaryButton(
                  label: 'Abrir relatório completo',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SystemReportScreen()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class V2HistoryHubPage extends StatelessWidget {
  const V2HistoryHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const V2ActionHubPage(
      title: 'Histórico',
      subtitle: 'Linha do tempo da sua jornada, recompensas e eventos importantes.',
      icon: Icons.history_rounded,
      accentColor: GameColors.info,
      actions: [
        V2ActionSpec(
          label: 'Abrir histórico completo',
          description: 'Veja eventos com filtros e paginação segura.',
          icon: Icons.timeline_rounded,
          destination: HistoryScreen(),
          color: GameColors.info,
        ),
      ],
    );
  }
}

class V2AboutPage extends StatelessWidget {
  const V2AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const V2ActionHubPage(
      title: 'Sobre',
      subtitle: 'Informações do aplicativo, versão e base local.',
      icon: Icons.info_rounded,
      accentColor: GameColors.primary,
      actions: [
        V2ActionSpec(
          label: 'Abrir Sobre o app',
          description: 'Veja informações da versão instalada.',
          icon: Icons.shield_rounded,
          destination: AboutV1Screen(),
          color: GameColors.primary,
        ),
      ],
      note:
          'A versão instalada mantém a base local estável e os dados salvos no aparelho.',
    );
  }
}
