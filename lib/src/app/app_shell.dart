import 'package:flutter/material.dart';

import '../design_system/game_design_system.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/campaign/campaign_screen.dart';
import '../features/checkins/checkin_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/evolution/v2_evolution_pages.dart';
import '../features/focus/focus_screen.dart';
import '../features/habits/habit_list_screen.dart';
import '../features/health/health_screen.dart';
import '../features/history/history_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/system/about_v1_screen.dart';
import '../features/system/system_screen.dart';
import '../features/vaults/vault_screen.dart';
import '../features/v2_navigation/v2_group_pages.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PageController _pageController;

  int _selectedGroupIndex = 0;
  final Map<int, int> _localIndexes = <int, int>{};

  static const List<_ShellGroup> _groups = [
    _ShellGroup(
      title: 'Início',
      subtitle: 'Dashboard e ações rápidas',
      icon: Icons.dashboard_rounded,
      pages: [
        _ShellPage(
          title: 'Dashboard',
          shortLabel: 'Painel',
          icon: Icons.dashboard_rounded,
          child: DashboardScreen(),
        ),
        _ShellPage(
          title: 'Ações rápidas',
          shortLabel: 'Ações',
          icon: Icons.flash_on_rounded,
          child: V2QuickActionsPage(),
        ),
        _ShellPage(
          title: 'Ritmo diário',
          shortLabel: 'Ritmo',
          icon: Icons.local_fire_department_rounded,
          child: CheckInScreen(embedded: true),
        ),
      ],
    ),
    _ShellGroup(
      title: 'Jornada',
      subtitle: 'Missões, hábitos, saúde, objetivos e campanha',
      icon: Icons.flag_rounded,
      pages: [
        _ShellPage(
          title: 'Missões',
          shortLabel: 'Missões',
          icon: Icons.flag_rounded,
          child: V2MissionHubPage(),
        ),
        _ShellPage(
          title: 'Hábitos',
          shortLabel: 'Hábitos',
          icon: Icons.repeat_rounded,
          child: HabitListScreen(),
        ),
        _ShellPage(
          title: 'Saúde',
          shortLabel: 'Saúde',
          icon: Icons.health_and_safety_rounded,
          child: HealthScreen(),
        ),
        _ShellPage(
          title: 'Objetivos',
          shortLabel: 'Objetivos',
          icon: Icons.track_changes_rounded,
          child: V2ObjectiveHubPage(),
        ),
        _ShellPage(
          title: 'Campanha',
          shortLabel: 'Campanha',
          icon: Icons.auto_awesome_rounded,
          child: CampaignScreen(),
        ),
      ],
    ),
    _ShellGroup(
      title: 'Foco',
      subtitle: 'Sessões e resumo de foco',
      icon: Icons.timer_rounded,
      pages: [
        _ShellPage(
          title: 'Registrar sessão',
          shortLabel: 'Registrar',
          icon: Icons.add_rounded,
          child: V2FocusRegisterPage(),
        ),
        _ShellPage(
          title: 'Sessões recentes',
          shortLabel: 'Recentes',
          icon: Icons.history_rounded,
          child: V2SessionsRecentPage(),
        ),
        _ShellPage(
          title: 'Resumo de foco',
          shortLabel: 'Resumo',
          icon: Icons.insights_rounded,
          child: FocusScreen(),
        ),
      ],
    ),
    _ShellGroup(
      title: 'Finanças',
      subtitle: 'Cofres, loja, metas reais e reserva do reino',
      icon: Icons.savings_rounded,
      pages: [
        _ShellPage(
          title: 'Cofre do Reino',
          shortLabel: 'Cofre',
          icon: Icons.savings_rounded,
          child: VaultScreen(),
        ),
        _ShellPage(
          title: 'Loja do Reino',
          shortLabel: 'Loja',
          icon: Icons.storefront_rounded,
          child: ShopScreen(),
        ),
      ],
    ),
    _ShellGroup(
      title: 'Projetos',
      subtitle: 'Projetos, tarefas e conclusões',
      icon: Icons.folder_special_rounded,
      pages: [
        _ShellPage(
          title: 'Projetos ativos',
          shortLabel: 'Ativos',
          icon: Icons.folder_open_rounded,
          child: V2ProjectsActivePage(),
        ),
        _ShellPage(
          title: 'Tarefas',
          shortLabel: 'Tarefas',
          icon: Icons.checklist_rounded,
          child: V2ProjectTasksPage(),
        ),
        _ShellPage(
          title: 'Projetos concluídos',
          shortLabel: 'Concluídos',
          icon: Icons.verified_rounded,
          child: V2ProjectsCompletedPage(),
        ),
      ],
    ),
    _ShellGroup(
      title: 'Evolução',
      subtitle: 'Herói, áreas, atributos, conquistas e relatório',
      icon: Icons.auto_graph_rounded,
      pages: [
        _ShellPage(
          title: 'Herói',
          shortLabel: 'Herói',
          icon: Icons.shield_rounded,
          child: V2HeroOverviewPage(),
        ),
        _ShellPage(
          title: 'Áreas',
          shortLabel: 'Áreas',
          icon: Icons.public_rounded,
          child: V2AreasPage(),
        ),
        _ShellPage(
          title: 'Atributos',
          shortLabel: 'Atributos',
          icon: Icons.auto_graph_rounded,
          child: V2AttributesPage(),
        ),
        _ShellPage(
          title: 'Conquistas',
          shortLabel: 'Conquistas',
          icon: Icons.emoji_events_rounded,
          child: AchievementsScreen(),
        ),
        _ShellPage(
          title: 'Relatório',
          shortLabel: 'Relatório',
          icon: Icons.description_rounded,
          child: V2EvolutionReportPage(),
        ),
      ],
    ),
    _ShellGroup(
      title: 'Sistema',
      subtitle: 'Histórico, configurações e sobre',
      icon: Icons.settings_rounded,
      pages: [
        _ShellPage(
          title: 'Histórico',
          shortLabel: 'Histórico',
          icon: Icons.history_rounded,
          child: HistoryScreen(embedded: true),
        ),
        _ShellPage(
          title: 'Configurações',
          shortLabel: 'Config.',
          icon: Icons.tune_rounded,
          child: SystemScreen(),
        ),
        _ShellPage(
          title: 'Sobre',
          shortLabel: 'Sobre',
          icon: Icons.info_rounded,
          child: AboutV1Screen(embedded: true),
        ),
      ],
    ),
  ];

  _ShellGroup get _currentGroup => _groups[_selectedGroupIndex];

  int get _selectedLocalIndex {
    final current = _localIndexes[_selectedGroupIndex] ?? 0;
    final lastIndex = _currentGroup.pages.length - 1;
    if (current < 0) return 0;
    if (current > lastIndex) return lastIndex;
    return current;
  }

  _ShellPage get _currentPage => _currentGroup.pages[_selectedLocalIndex];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedLocalIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _closeDrawerIfNeeded() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _selectGroup(int index) {
    if (index < 0 || index >= _groups.length) return;

    if (_selectedGroupIndex != index) {
      final nextLocalIndex = _safeLocalIndex(index, _localIndexes[index] ?? 0);
      final oldController = _pageController;

      setState(() {
        _selectedGroupIndex = index;
        _localIndexes[index] = nextLocalIndex;
        _pageController = PageController(initialPage: nextLocalIndex);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController.dispose();
      });
    }

    _closeDrawerIfNeeded();
  }

  int _safeLocalIndex(int groupIndex, int localIndex) {
    final lastIndex = _groups[groupIndex].pages.length - 1;
    if (localIndex < 0) return 0;
    if (localIndex > lastIndex) return lastIndex;
    return localIndex;
  }

  Future<void> _selectLocalPage(int index) async {
    final safeIndex = _safeLocalIndex(_selectedGroupIndex, index);
    if (safeIndex == _selectedLocalIndex) return;

    setState(() {
      _localIndexes[_selectedGroupIndex] = safeIndex;
    });

    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        safeIndex,
        duration: GameMotion.normal,
        curve: GameMotion.curve,
      );
    }
  }

  void _handlePageChanged(int index) {
    if (index == _selectedLocalIndex) return;

    setState(() {
      _localIndexes[_selectedGroupIndex] = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final group = _currentGroup;
    final pages = group.pages;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Abrir navegação',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu_rounded),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.title),
            const SizedBox(height: 1),
            Text(
              _currentPage.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameTextStyles.caption.copyWith(color: GameColors.textMuted),
            ),
          ],
        ),
        actions: const [
          _ShellTopBadge(label: 'V4.4'),
          SizedBox(width: GameSpacing.sm),
        ],
      ),
      drawer: Drawer(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: GameColors.appBackgroundGradient),
          child: SafeArea(
            child: Column(
              children: [
                const _DrawerHeader(),
              const SizedBox(height: GameSpacing.xs),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: GameSpacing.sm),
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final item = _groups[index];
                    return _DrawerGroupItem(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                      selected: _selectedGroupIndex == index,
                      onTap: () => _selectGroup(index),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _DrawerFooter(),
              ),
            ],
          ),
        ),
      ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: GameColors.appBackgroundGradient),
        child: PageView(
          key: ValueKey<int>(_selectedGroupIndex),
          controller: _pageController,
          onPageChanged: _handlePageChanged,
          children: [
            for (final page in pages)
              KeyedSubtree(
                key: ValueKey<String>('${group.title}-${page.title}'),
                child: page.child,
              ),
          ],
        ),
      ),
      bottomNavigationBar: _LocalNavigationBar(
        pages: pages,
        selectedIndex: _selectedLocalIndex,
        onSelected: _selectLocalPage,
      ),
    );
  }
}

class _ShellGroup {
  const _ShellGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.pages,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<_ShellPage> pages;
}

class _ShellPage {
  const _ShellPage({
    required this.title,
    required this.shortLabel,
    required this.icon,
    required this.child,
  });

  final String title;
  final String shortLabel;
  final IconData icon;
  final Widget child;
}

class _ShellTopBadge extends StatelessWidget {
  const _ShellTopBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: GameSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: GameSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameColors.reward.withValues(alpha: 0.24),
            GameColors.primary.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: GameRadius.chip,
        border: Border.all(color: GameColors.reward.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: GameColors.rewardSoft, size: 15),
          const SizedBox(width: 5),
          Text(label, style: GameTextStyles.caption.copyWith(color: GameColors.textPrimary)),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(GameSpacing.md),
      padding: const EdgeInsets.all(GameSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: GameRadius.cardLarge,
        gradient: GameColors.premiumGradient(accent: GameColors.primary),
        border: Border.all(color: GameColors.primaryGlow),
        boxShadow: GameShadows.softGlow(GameColors.primary),
      ),
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
                  border: Border.all(color: GameColors.rewardSoft.withValues(alpha: 0.38)),
                ),
                child: const Icon(Icons.shield_rounded, size: 28, color: GameColors.rewardSoft),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Game Life', style: GameTextStyles.title),
                    const SizedBox(height: 3),
                    Text(
                      'Edição Capítulos V4.4',
                      style: GameTextStyles.caption.copyWith(color: GameColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.md),
          Text(
            'Transforme esforço real em XP, foco e progresso visível.',
            style: GameTextStyles.body.copyWith(color: GameColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _DrawerGroupItem extends StatelessWidget {
  const _DrawerGroupItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? GameColors.primary : GameColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: GameSpacing.xs),
      child: Material(
        color: Colors.transparent,
        borderRadius: GameRadius.button,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: GameColors.primary.withValues(alpha: 0.10),
          highlightColor: GameColors.primary.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: GameMotion.fast,
            curve: GameMotion.curve,
            padding: const EdgeInsets.symmetric(
              horizontal: GameSpacing.sm,
              vertical: GameSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected ? GameColors.primary.withValues(alpha: 0.16) : Colors.transparent,
              borderRadius: GameRadius.button,
              border: Border.all(
                color: selected ? GameColors.primary.withValues(alpha: 0.32) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 23),
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GameTextStyles.cardTitle.copyWith(
                          color: selected ? GameColors.textPrimary : GameColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GameTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GameSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GameColors.surfaceRaised.withValues(alpha: 0.88),
            GameColors.surfaceSoft.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: GameRadius.card,
        border: Border.all(color: GameColors.borderPremium),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: GameColors.textMuted),
          SizedBox(width: GameSpacing.xs),
          Expanded(
            child: Text(
              'Release Premium V4.4 • local-first',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GameTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalNavigationBar extends StatelessWidget {
  const _LocalNavigationBar({
    required this.pages,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ShellPage> pages;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          GameSpacing.md,
          0,
          GameSpacing.md,
          GameSpacing.sm,
        ),
        padding: const EdgeInsets.all(GameSpacing.xs),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GameColors.surfaceRaised.withValues(alpha: 0.96),
              GameColors.surface.withValues(alpha: 0.98),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: GameRadius.cardLarge,
          border: Border.all(color: GameColors.borderPremium),
          boxShadow: GameShadows.elevated,
        ),
        child: Row(
          children: [
            for (var index = 0; index < pages.length; index++)
              Expanded(
                child: _LocalNavigationItem(
                  page: pages[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LocalNavigationItem extends StatelessWidget {
  const _LocalNavigationItem({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final _ShellPage page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? GameColors.textPrimary : GameColors.textMuted;
    final background = selected ? GameColors.primary.withValues(alpha: 0.22) : Colors.transparent;

    return Material(
      color: Colors.transparent,
      borderRadius: GameRadius.button,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: GameRadius.button,
        splashColor: GameColors.primary.withValues(alpha: 0.10),
        highlightColor: GameColors.primary.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: GameMotion.fast,
          curve: GameMotion.curve,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: GameRadius.button,
            border: Border.all(
              color: selected ? GameColors.primary.withValues(alpha: 0.30) : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: GameMotion.fast,
                curve: GameMotion.curve,
                scale: selected ? 1.08 : 1.0,
                child: Icon(
                  page.icon,
                  color: selected ? GameColors.primary : color,
                  size: selected ? 22 : 20,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                page.shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
