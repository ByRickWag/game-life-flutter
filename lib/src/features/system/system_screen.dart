import 'package:flutter/material.dart';

import '../../core/models/v3_commitment_models.dart';
import '../../core/repositories/system_repository.dart';
import '../../core/repositories/onboarding_repository.dart';
import '../../core/services/difficulty_service.dart';
import '../../core/services/notification_service.dart';
import '../../design_system/game_design_system.dart';
import '../onboarding/onboarding_screen.dart';
import 'system_report_screen.dart';

class SystemScreen extends StatefulWidget {
  const SystemScreen({super.key});

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  final SystemRepository _repository = const SystemRepository();
  final OnboardingRepository _onboardingRepository = const OnboardingRepository();
  final DifficultyService _difficultyService = DifficultyService();

  List<BalanceSetting> _settings = const [];
  SystemStats? _stats;
  String _databasePath = '';
  ReminderSettings _reminderSettings = ReminderSettings.defaults;
  ReminderSummary? _reminderSummary;
  List<DifficultyProfile> _difficultyProfiles = const [];
  DifficultyModeSummary? _difficultySummary;
  Object? _error;
  bool _loading = true;
  bool _working = false;

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
      final settings = await _repository.getSettings();
      final stats = await _repository.getStats();
      final path = await _repository.getDatabasePath();
      final reminderSettings = await NotificationService.instance.getReminderSettings();
      final reminderSummary = await NotificationService.instance.getTodaySummary();
      final difficultyProfiles = await _difficultyService.getProfiles();
      final difficultySummary = await _difficultyService.getSummary();

      if (!mounted) return;
      setState(() {
        _settings = settings;
        _stats = stats;
        _databasePath = path;
        _reminderSettings = reminderSettings;
        _reminderSummary = reminderSummary;
        _difficultyProfiles = difficultyProfiles;
        _difficultySummary = difficultySummary;
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

  Future<void> _editSetting(BalanceSetting setting) async {
    final controller = TextEditingController(text: setting.value);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(setting.label),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Novo valor',
              helperText: setting.valueType == 'double'
                  ? 'Aceita decimal. Exemplo: 1.2'
                  : 'Use número inteiro. Exemplo: 12',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (result == null) return;

    await _runAction(
      successMessage: 'Configuração atualizada.',
      action: () => _repository.updateSetting(setting: setting, rawValue: result),
    );
  }

  Future<void> _restoreDefaults() async {
    final confirmed = await _confirm(
      title: 'Restaurar balanceamento?',
      message:
          'Isso volta XP, coins e multiplicadores para os valores padrão. Seus dados de missões, objetivos, sessões e projetos não serão apagados.',
      confirmLabel: 'Restaurar',
    );

    if (!confirmed) return;

    await _runAction(
      successMessage: 'Balanceamento restaurado.',
      action: _repository.restoreDefaultSettings,
    );
  }

  Future<void> _changeDifficulty(String mode) async {
    final label = switch (mode) {
      'hard' => 'Difícil',
      'hardcore' => 'Hardcore',
      _ => 'Normal',
    };

    final confirmed = await _confirm(
      title: mode == 'hardcore' ? 'Ativar Hardcore?' : 'Alterar dificuldade?',
      message: mode == 'hardcore'
          ? 'Hardcore deixa a curva de nível mais pesada e aplica 100% de penalidade de XP para missões vencidas. É brutal de propósito. Ative só se estiver consciente.'
          : 'A dificuldade será alterada para $label. O nível do herói será recalculado pela curva deste modo.',
      confirmLabel: mode == 'hardcore' ? 'Ativar Hardcore' : 'Alterar',
      destructive: mode == 'hardcore',
    );

    if (!confirmed) return;

    await _runAction(
      successMessage: 'Dificuldade alterada para $label.',
      action: () => _difficultyService.setActiveMode(mode),
    );
  }

  Future<void> _applyPendingPenalties() async {
    if (_working) return;

    setState(() => _working = true);

    try {
      final result = await _difficultyService.applyPendingMissionPenalties();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), behavior: SnackBarBehavior.floating),
      );

      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $error'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _resetProgressData() async {
    final confirmed = await _confirm(
      title: 'Resetar dados de teste?',
      message:
          'Isso apaga missões, objetivos, sessões, projetos, tarefas e histórico. Também zera XP, coins e atributos. Áreas, atributos, campanha e configurações serão preservados.',
      confirmLabel: 'Resetar',
      destructive: true,
    );

    if (!confirmed) return;

    await _runAction(
      successMessage: 'Dados de teste resetados.',
      action: _repository.resetProgressData,
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: GameColors.danger,
                      foregroundColor: GameColors.textPrimary,
                    )
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  List<BalanceSetting> _settingsFor(List<String> keys) {
    final byKey = {for (final setting in _settings) setting.key: setting};
    return [
      for (final key in keys)
        if (byKey[key] != null) byKey[key]!,
    ];
  }

  Future<void> _runAction({
    required String successMessage,
    required Future<void> Function() action,
  }) async {
    if (_working) return;

    setState(() => _working = true);

    try {
      await action();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), behavior: SnackBarBehavior.floating),
      );

      await _load();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $error'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }


  Future<void> _toggleReminders(bool enabled) async {
    await _runAction(
      successMessage: enabled ? 'Lembrete diário ativado.' : 'Lembrete diário desativado.',
      action: () => NotificationService.instance.setDailyReminderEnabled(enabled),
    );
  }

  Future<void> _setReminderTime(int hour, int minute) async {
    await _runAction(
      successMessage: 'Horário do lembrete atualizado.',
      action: () => NotificationService.instance.setDailyReminderTime(hour: hour, minute: minute),
    );
  }

  Future<void> _sendTestReminder() async {
    await _runAction(
      successMessage: 'Notificação de teste enviada.',
      action: NotificationService.instance.showTestReminder,
    );
  }

  Future<void> _openOnboarding() async {
    final confirmed = await _confirm(
      title: 'Refazer configuração inicial?',
      message:
          'Isso não apaga seus dados. Você poderá revisar nome do herói, dificuldade, foco inicial, meta de água e presets da campanha.',
      confirmLabel: 'Refazer',
    );

    if (!confirmed) return;

    await _onboardingRepository.reset();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(
          embeddedReset: true,
          onCompleted: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  Future<void> _openReport() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SystemReportScreen()),
    );

    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _settings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _settings.isEmpty) {
      return GameEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Erro ao carregar Sistema',
        message: _error.toString(),
        actionLabel: 'Tentar novamente',
        onAction: _load,
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: GameSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SystemHeader(loading: _loading || _working),
            const SizedBox(height: GameSpacing.md),
            GameSectionHeader(
              title: 'Resumo técnico',
              subtitle: 'Contadores principais do banco local.',
              icon: Icons.storage_rounded,
              actionLabel: _loading ? null : 'Atualizar',
              onAction: _loading ? null : _load,
            ),
            _StatsPanel(stats: _stats),
            const SizedBox(height: GameSpacing.md),
            const GameSectionHeader(
              title: 'Manutenção segura',
              subtitle: 'Relatório, restauração e reset controlado.',
              icon: Icons.build_circle_rounded,
            ),
            _MaintenancePanel(
              working: _working,
              databasePath: _databasePath,
              onReport: _openReport,
              onOnboarding: _openOnboarding,
              onRestore: _restoreDefaults,
              onReset: _resetProgressData,
            ),
            const SizedBox(height: GameSpacing.md),
            const GameSectionHeader(
              title: 'Dificuldade global',
              subtitle: 'Modo de jogo, curva de nível e penalidade de XP por falha.',
              icon: Icons.shield_rounded,
            ),
            _DifficultyPanel(
              profiles: _difficultyProfiles,
              summary: _difficultySummary,
              working: _working,
              onModeSelected: _changeDifficulty,
              onApplyPenalties: _applyPendingPenalties,
            ),
            const SizedBox(height: GameSpacing.md),
            const GameSectionHeader(
              title: 'Lembretes',
              subtitle: 'Notificações leves para lembrar de revisar sua jornada.',
              icon: Icons.notifications_active_rounded,
            ),
            _ReminderPanel(
              settings: _reminderSettings,
              summary: _reminderSummary,
              working: _working,
              onToggle: _toggleReminders,
              onTimeSelected: _setReminderTime,
              onTest: _sendTestReminder,
            ),
            const SizedBox(height: GameSpacing.md),
            const GameSectionHeader(
              title: 'Balanceamento Lite',
              subtitle: 'Toque em um item para editar recompensas e multiplicadores.',
              icon: Icons.tune_rounded,
            ),
            _SettingGroup(
              title: 'Tetos de XP — missões',
              icon: Icons.bolt_rounded,
              color: GameColors.primary,
              settings: _settingsFor(const [
                'xp_cap_mission_easy',
                'xp_cap_mission_normal',
                'xp_cap_mission_medium',
                'xp_cap_mission_hard',
                'xp_cap_mission_very_hard',
                'xp_cap_special_very_hard',
              ]),
              working: _working,
              onTap: _editSetting,
            ),
            const SizedBox(height: GameSpacing.sm),
            _SettingGroup(
              title: 'Tetos de XP — objetivos',
              icon: Icons.track_changes_rounded,
              color: GameColors.info,
              settings: _settingsFor(const [
                'xp_cap_objective_easy',
                'xp_cap_objective_normal',
                'xp_cap_objective_medium',
                'xp_cap_objective_hard',
                'xp_cap_objective_very_hard',
              ]),
              working: _working,
              onTap: _editSetting,
            ),
            const SizedBox(height: GameSpacing.sm),
            _SettingGroup(
              title: 'Sessões de foco',
              icon: Icons.timer_rounded,
              color: GameColors.success,
              settings: _settingsFor(const ['session_xp_per_15min', 'xp_cap_session']),
              working: _working,
              onTap: _editSetting,
            ),
            const SizedBox(height: GameSpacing.sm),
            _SettingGroup(
              title: 'Projetos',
              icon: Icons.folder_special_rounded,
              color: GameColors.discipline,
              settings: _settingsFor(const [
                'project_task_xp_default',
                'project_task_xp_cap',
                'project_completion_xp',
                'project_completion_coins',
              ]),
              working: _working,
              onTap: _editSetting,
            ),
            const SizedBox(height: GameSpacing.sm),
            _SettingGroup(
              title: 'Coins e multiplicadores',
              icon: Icons.monetization_on_rounded,
              color: GameColors.reward,
              settings: _settingsFor(const [
                'coins_easy',
                'coins_normal',
                'coins_medium',
                'coins_hard',
                'coins_very_hard',
                'objective_completion_multiplier',
              ]),
              working: _working,
              onTap: _editSetting,
            ),
            const SizedBox(height: GameSpacing.sm),
            _SettingGroup(
              title: 'Progressão do herói',
              icon: Icons.auto_graph_rounded,
              color: GameColors.faith,
              settings: _settingsFor(const [
                'level_curve_multiplier_normal',
                'level_curve_multiplier_hard',
                'level_curve_multiplier_hardcore',
                'hero_max_level',
              ]),
              working: _working,
              onTap: _editSetting,
            ),
            const SizedBox(height: GameSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _SystemHeader extends StatelessWidget {
  const _SystemHeader({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GameHighlightCard(
      accentColor: GameColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.settings_rounded, color: GameColors.primary, size: 34),
          const SizedBox(height: GameSpacing.sm),
          Text('Configurações', style: GameTextStyles.title),
          const SizedBox(height: GameSpacing.xs),
          Text(
            'Balanceamento editável, manutenção local e relatório técnico em modo seguro.',
            style: GameTextStyles.body,
          ),
          if (loading) ...[
            const SizedBox(height: GameSpacing.md),
            const LinearProgressIndicator(minHeight: 4),
          ],
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.stats});

  final SystemStats? stats;

  @override
  Widget build(BuildContext context) {
    final data = stats;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GameStatTile(
                label: 'Missões',
                value: '${data?.missions ?? 0}',
                icon: Icons.flag_rounded,
                color: GameColors.primary,
              ),
            ),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: GameStatTile(
                label: 'Objetivos',
                value: '${data?.objectives ?? 0}',
                icon: Icons.track_changes_rounded,
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
                label: 'Hábitos',
                value: '${data?.habits ?? 0}',
                icon: Icons.repeat_rounded,
                color: GameColors.vigor,
              ),
            ),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: GameStatTile(
                label: 'Sessões',
                value: '${data?.sessions ?? 0}',
                icon: Icons.timer_rounded,
                color: GameColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: GameSpacing.sm),
        GameCard(
          backgroundColor: GameColors.surfaceSoft,
          padding: const EdgeInsets.all(GameSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.timeline_rounded, color: GameColors.textMuted),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Text(
                  '${data?.projects ?? 0} projetos • ${data?.historyEvents ?? 0} eventos • ${data?.totalXpHistory ?? 0} XP • ${data?.totalCoinsHistory ?? 0} coins',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GameTextStyles.body,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaintenancePanel extends StatelessWidget {
  const _MaintenancePanel({
    required this.working,
    required this.databasePath,
    required this.onReport,
    required this.onOnboarding,
    required this.onRestore,
    required this.onReset,
  });

  final bool working;
  final String databasePath;
  final VoidCallback onReport;
  final VoidCallback onOnboarding;
  final VoidCallback onRestore;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      padding: const EdgeInsets.all(GameSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GamePrimaryButton(
            label: 'Gerar relatório simples',
            icon: Icons.description_rounded,
            onPressed: working ? null : onReport,
          ),
          const SizedBox(height: GameSpacing.sm),
          GameSecondaryButton(
            label: 'Refazer configuração inicial',
            icon: Icons.rocket_launch_rounded,
            onPressed: working ? null : onOnboarding,
          ),
          const SizedBox(height: GameSpacing.sm),
          GameSecondaryButton(
            label: 'Restaurar balanceamento padrão',
            icon: Icons.tune_rounded,
            onPressed: working ? null : onRestore,
          ),
          const SizedBox(height: GameSpacing.sm),
          GameDangerButton(
            label: 'Resetar dados de teste',
            icon: Icons.restart_alt_rounded,
            onPressed: working ? null : onReset,
          ),
          const SizedBox(height: GameSpacing.md),
          Text('Banco local', style: GameTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(
            databasePath.isEmpty ? 'Carregando caminho do banco...' : databasePath,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GameTextStyles.caption,
          ),
        ],
      ),
    );
  }
}


class _DifficultyPanel extends StatelessWidget {
  const _DifficultyPanel({
    required this.profiles,
    required this.summary,
    required this.working,
    required this.onModeSelected,
    required this.onApplyPenalties,
  });

  final List<DifficultyProfile> profiles;
  final DifficultyModeSummary? summary;
  final bool working;
  final ValueChanged<String> onModeSelected;
  final VoidCallback onApplyPenalties;

  @override
  Widget build(BuildContext context) {
    final data = summary;

    return GameCard(
      padding: const EdgeInsets.all(GameSpacing.md),
      backgroundColor: GameColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _modeColor(data?.activeMode ?? 'normal').withValues(alpha: 0.16),
                ),
                child: Icon(Icons.shield_rounded, color: _modeColor(data?.activeMode ?? 'normal')),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Modo ${data?.activeName ?? 'Normal'}', style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      data == null
                          ? 'Carregando dificuldade...'
                          : '${data.penaltyLabel} • ${data.curveLabel} • nível máx. ${data.maxLevel}',
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
          for (final profile in profiles) ...[
            _DifficultyModeTile(
              profile: profile,
              selected: profile.code == data?.activeMode,
              working: working,
              onTap: () => onModeSelected(profile.code),
            ),
            if (profile != profiles.last) const SizedBox(height: GameSpacing.xs),
          ],
          if (profiles.isEmpty)
            Text('Perfis de dificuldade ainda não carregados.', style: GameTextStyles.caption),
          const SizedBox(height: GameSpacing.sm),
          GameSecondaryButton(
            label: 'Aplicar penalidades pendentes',
            icon: Icons.gavel_rounded,
            onPressed: working ? null : onApplyPenalties,
          ),
          const SizedBox(height: GameSpacing.xs),
          Text(
            'V1 segura: as penalidades são aplicadas manualmente aqui e nunca removem coins. O modo Normal sempre fica sem dano de XP.',
            style: GameTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Color _modeColor(String mode) {
    return switch (mode) {
      'hard' => GameColors.warning,
      'hardcore' => GameColors.danger,
      _ => GameColors.success,
    };
  }
}

class _DifficultyModeTile extends StatelessWidget {
  const _DifficultyModeTile({
    required this.profile,
    required this.selected,
    required this.working,
    required this.onTap,
  });

  final DifficultyProfile profile;
  final bool selected;
  final bool working;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (profile.code) {
      'hard' => GameColors.warning,
      'hardcore' => GameColors.danger,
      _ => GameColors.success,
    };

    return Material(
      color: selected ? color.withValues(alpha: 0.16) : GameColors.surface,
      borderRadius: GameRadius.button,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: working || selected ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(GameSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: color),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(profile.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(width: GameSpacing.xs),
              GameChip(
                label: '${profile.penaltyPercent}% XP',
                color: color,
                selected: selected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ReminderPanel extends StatelessWidget {
  const _ReminderPanel({
    required this.settings,
    required this.summary,
    required this.working,
    required this.onToggle,
    required this.onTimeSelected,
    required this.onTest,
  });

  final ReminderSettings settings;
  final ReminderSummary? summary;
  final bool working;
  final ValueChanged<bool> onToggle;
  final void Function(int hour, int minute) onTimeSelected;
  final VoidCallback onTest;

  static const List<_ReminderTimeOption> _times = [
    _ReminderTimeOption(hour: 8, minute: 0, label: '08:00'),
    _ReminderTimeOption(hour: 12, minute: 0, label: '12:00'),
    _ReminderTimeOption(hour: 18, minute: 0, label: '18:00'),
    _ReminderTimeOption(hour: 20, minute: 0, label: '20:00'),
    _ReminderTimeOption(hour: 21, minute: 30, label: '21:30'),
  ];

  @override
  Widget build(BuildContext context) {
    final data = summary;

    return GameCard(
      padding: const EdgeInsets.all(GameSpacing.md),
      backgroundColor: GameColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameColors.primary.withValues(alpha: 0.16),
                ),
                child: const Icon(Icons.notifications_rounded, color: GameColors.primary),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lembrete diário', style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      settings.enabled
                          ? 'Ativo às ${settings.timeLabel}'
                          : 'Desativado. Ative quando quiser receber lembretes.',
                      style: GameTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Switch(
                value: settings.enabled,
                onChanged: working ? null : onToggle,
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameCard(
            backgroundColor: GameColors.surface,
            padding: const EdgeInsets.all(GameSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.today_rounded, color: GameColors.success, size: 20),
                const SizedBox(width: GameSpacing.xs),
                Expanded(
                  child: Text(
                    data?.shortText ?? 'Carregando resumo de hoje...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GameTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GameSpacing.sm),
          Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              for (final option in _times)
                GameChip(
                  label: option.label,
                  icon: Icons.schedule_rounded,
                  color: GameColors.primary,
                  selected: settings.hour == option.hour && settings.minute == option.minute,
                  onTap: working ? null : () => onTimeSelected(option.hour, option.minute),
                ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          GameSecondaryButton(
            label: 'Enviar teste agora',
            icon: Icons.notifications_active_rounded,
            onPressed: working ? null : onTest,
          ),
          const SizedBox(height: GameSpacing.xs),
          Text(
            'O lembrete é propositalmente simples: ele chama você para revisar missões, objetivos e tarefas pendentes. Na próxima grande versão dá para evoluir isso com sequências e regras mais inteligentes.',
            style: GameTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _ReminderTimeOption {
  const _ReminderTimeOption({
    required this.hour,
    required this.minute,
    required this.label,
  });

  final int hour;
  final int minute;
  final String label;
}

class _SettingGroup extends StatelessWidget {
  const _SettingGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.settings,
    required this.working,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<BalanceSetting> settings;
  final bool working;
  final ValueChanged<BalanceSetting> onTap;

  @override
  Widget build(BuildContext context) {
    if (settings.isEmpty) return const SizedBox.shrink();

    return GameCard(
      padding: const EdgeInsets.all(GameSpacing.md),
      backgroundColor: GameColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: GameSpacing.xs),
              Expanded(child: Text(title, style: GameTextStyles.cardTitle)),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          for (final setting in settings) ...[
            _SettingTile(
              setting: setting,
              color: color,
              onTap: working ? null : () => onTap(setting),
            ),
            if (setting != settings.last) const SizedBox(height: GameSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.setting,
    required this.color,
    required this.onTap,
  });

  final BalanceSetting setting;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GameColors.surface,
      borderRadius: GameRadius.button,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(GameSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(Icons.tune_rounded, color: color, size: 18),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(setting.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GameTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(setting.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GameTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(width: GameSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    setting.shortValue,
                    style: GameTextStyles.cardTitle.copyWith(color: GameColors.reward),
                  ),
                  const SizedBox(height: 2),
                  Text('editar', style: GameTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
