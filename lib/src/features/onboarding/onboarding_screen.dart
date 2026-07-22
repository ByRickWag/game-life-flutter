import 'package:flutter/material.dart';

import '../../core/repositories/onboarding_repository.dart';
import '../../core/services/difficulty_service.dart';
import '../../design_system/game_design_system.dart';

const int _totalPages = 8;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onCompleted,
    this.embeddedReset = false,
  });

  final VoidCallback onCompleted;
  final bool embeddedReset;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingRepository _repository = const OnboardingRepository();
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _campaignTitleController =
      TextEditingController();
  final TextEditingController _campaignDescriptionController =
      TextEditingController();
  final TextEditingController _campaignMainGoalController =
      TextEditingController();
  final TextEditingController _campaignLoreController = TextEditingController();
  final TextEditingController _campaignStartController =
      TextEditingController();
  final TextEditingController _campaignEndController = TextEditingController();

  int _pageIndex = 0;
  bool _loading = true;
  bool _saving = false;
  Object? _error;
  String _difficultyMode = 'normal';
  int _waterTargetMl = 1000;
  int _victoryMinimumPercent = 60;
  int _victoryGoodPercent = 75;
  int _victoryExcellentPercent = 90;
  bool _useStarterPresets = true;
  bool _useRecommendedSetup = true;
  HardcoreEligibility _hardcoreEligibility = const HardcoreEligibility(
    validCheckIns: 0,
    requiredCheckIns: DifficultyService.hardcoreRequiredCheckIns,
  );
  bool _canSelectHardcore = false;
  final Set<String> _selectedAreaIds = {
    'body_health',
    'mind_knowledge',
    'spirit_purpose',
    'projects_career',
    'finance_responsibility',
    'routine_order',
  };
  final Map<String, List<String>> _areaAttributes = {};

  static const List<_AreaOption> _areaOptions = [
    _AreaOption(
      id: 'body_health',
      title: 'Corpo e Saúde',
      description: 'Treino, água, alimentação, sono e energia física.',
      icon: Icons.fitness_center_rounded,
      color: GameColors.vigor,
    ),
    _AreaOption(
      id: 'mind_knowledge',
      title: 'Mente e Conhecimento',
      description: 'Estudo, leitura, inglês, programação e clareza mental.',
      icon: Icons.menu_book_rounded,
      color: GameColors.clarity,
    ),
    _AreaOption(
      id: 'spirit_purpose',
      title: 'Fé e Propósito',
      description: 'Vida espiritual, propósito, valores e presença.',
      icon: Icons.auto_awesome_rounded,
      color: GameColors.faith,
    ),
    _AreaOption(
      id: 'projects_career',
      title: 'Carreira e Projetos',
      description:
          'Trabalho, programação, portfólio e construção profissional.',
      icon: Icons.work_rounded,
      color: GameColors.primary,
    ),
    _AreaOption(
      id: 'creation_expression',
      title: 'Criação e Expressão',
      description: 'Design, conteúdo, escrita, arte, música e criatividade.',
      icon: Icons.brush_rounded,
      color: GameColors.creativity,
    ),
    _AreaOption(
      id: 'finance_responsibility',
      title: 'Finanças e Reino',
      description: 'Cofre, compras planejadas, maturidade e responsabilidade.',
      icon: Icons.savings_rounded,
      color: GameColors.reward,
    ),
    _AreaOption(
      id: 'routine_order',
      title: 'Rotina e Ordem',
      description: 'Organização, constância, ambiente e execução diária.',
      icon: Icons.checklist_rounded,
      color: GameColors.discipline,
    ),
  ];

  static const List<_AttributeOption> _attributeOptions = [
    _AttributeOption(
      id: 'strength',
      title: 'Força',
      icon: Icons.sports_martial_arts_rounded,
      color: GameColors.strength,
    ),
    _AttributeOption(
      id: 'vigor',
      title: 'Vigor',
      icon: Icons.bolt_rounded,
      color: GameColors.vigor,
    ),
    _AttributeOption(
      id: 'clarity',
      title: 'Clareza',
      icon: Icons.psychology_rounded,
      color: GameColors.clarity,
    ),
    _AttributeOption(
      id: 'focus',
      title: 'Foco',
      icon: Icons.center_focus_strong_rounded,
      color: GameColors.focus,
    ),
    _AttributeOption(
      id: 'creativity',
      title: 'Criatividade',
      icon: Icons.palette_rounded,
      color: GameColors.creativity,
    ),
    _AttributeOption(
      id: 'responsibility',
      title: 'Responsabilidade',
      icon: Icons.account_balance_wallet_rounded,
      color: GameColors.responsibility,
    ),
    _AttributeOption(
      id: 'discipline',
      title: 'Disciplina',
      icon: Icons.verified_rounded,
      color: GameColors.discipline,
    ),
    _AttributeOption(
      id: 'faith',
      title: 'Fé',
      icon: Icons.church_rounded,
      color: GameColors.faith,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _campaignTitleController.dispose();
    _campaignDescriptionController.dispose();
    _campaignMainGoalController.dispose();
    _campaignLoreController.dispose();
    _campaignStartController.dispose();
    _campaignEndController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final status = await _repository.getStatus();
      if (!mounted) return;
      setState(() {
        _nameController.text = status.heroName;
        _titleController.text = status.heroTitle;
        _campaignTitleController.text = status.campaignTitle;
        _campaignDescriptionController.text = status.campaignDescription;
        _campaignMainGoalController.text = status.campaignMainGoal;
        _campaignLoreController.text = status.campaignLore;
        _campaignStartController.text = status.campaignStartDate;
        _campaignEndController.text = status.campaignEndDate;
        _difficultyMode = status.difficultyMode;
        _waterTargetMl = status.waterTargetMl.clamp(500, 4000).toInt();
        _victoryMinimumPercent = status.victoryMinimumPercent
            .clamp(1, 100)
            .toInt();
        _victoryGoodPercent = status.victoryGoodPercent
            .clamp(_victoryMinimumPercent, 100)
            .toInt();
        _victoryExcellentPercent = status.victoryExcellentPercent
            .clamp(_victoryGoodPercent, 100)
            .toInt();
        _useStarterPresets = status.useStarterPresets;
        _useRecommendedSetup = status.useRecommendedSetup;
        _hardcoreEligibility = status.hardcoreEligibility;
        _canSelectHardcore = status.canSelectHardcore;
        _selectedAreaIds
          ..clear()
          ..addAll(
            status.activeAreaIds.isEmpty
                ? _defaultAreaIds
                : status.activeAreaIds,
          );
        _areaAttributes
          ..clear()
          ..addAll({
            for (final area in _areaOptions)
              area.id:
                  status.areaAttributeIds[area.id] ??
                  _defaultAttributesForArea(area.id),
          });
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

  Future<void> _next() async {
    if (!_validateCurrentStep()) return;

    if (_pageIndex >= _totalPages - 1) {
      await _finish();
      return;
    }

    await _goTo(_pageIndex + 1);
  }

  bool _validateCurrentStep() {
    if (_pageIndex == 0 && _nameController.text.trim().isEmpty) {
      _showMessage('Dê um nome para o herói antes de continuar.');
      return false;
    }
    if (_pageIndex == 1 &&
        _difficultyMode == 'hardcore' &&
        !_canSelectHardcore) {
      _showMessage(
        'Hardcore exige ${_hardcoreEligibility.requiredCheckIns} check-ins '
        'v\u00e1lidos. Progresso: ${_hardcoreEligibility.progressLabel}.',
      );
      setState(() => _difficultyMode = 'normal');
      return false;
    }
    if (_pageIndex == 3 && _campaignTitleController.text.trim().isEmpty) {
      _showMessage('Dê um nome para a campanha.');
      return false;
    }
    if (_pageIndex == 5 && _selectedAreaIds.isEmpty) {
      _showMessage('Escolha pelo menos uma área de vida.');
      return false;
    }
    if (_pageIndex == 6) {
      for (final areaId in _selectedAreaIds) {
        if ((_areaAttributes[areaId] ?? const <String>[]).isEmpty) {
          _showMessage(
            'Cada área ativa precisa ter pelo menos um atributo vinculado.',
          );
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _back() async {
    if (_pageIndex <= 0) return;
    await _goTo(_pageIndex - 1);
  }

  Future<void> _goTo(int index) async {
    await _pageController.animateToPage(
      index,
      duration: GameMotion.normal,
      curve: GameMotion.curve,
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    if (_difficultyMode == 'hardcore' && !_canSelectHardcore) {
      _showMessage(
        'Hardcore ainda est\u00e1 bloqueado: '
        '${_hardcoreEligibility.progressLabel}.',
      );
      await _goTo(1);
      return;
    }

    setState(() => _saving = true);

    try {
      await _repository.complete(
        OnboardingSetup(
          heroName: _nameController.text,
          heroTitle: _titleController.text,
          difficultyMode: _difficultyMode,
          focusAreas: _focusAreasFromSelectedAreas(),
          waterTargetMl: _waterTargetMl,
          useStarterPresets: _useStarterPresets,
          useRecommendedSetup: _useRecommendedSetup,
          campaignTitle: _campaignTitleController.text,
          campaignDescription: _campaignDescriptionController.text,
          campaignMainGoal: _campaignMainGoalController.text,
          campaignLore: _campaignLoreController.text,
          campaignStartDate: _campaignStartController.text,
          campaignEndDate: _campaignEndController.text,
          victoryMinimumPercent: _victoryMinimumPercent,
          victoryGoodPercent: _victoryGoodPercent,
          victoryExcellentPercent: _victoryExcellentPercent,
          activeAreaIds: _orderedSelectedAreaIds,
          areaAttributeIds: {
            for (final entry in _areaAttributes.entries) entry.key: entry.value,
          },
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campanha preparada. Bora começar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onCompleted();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _toggleArea(String id) {
    setState(() {
      if (_selectedAreaIds.contains(id)) {
        if (_selectedAreaIds.length > 1) _selectedAreaIds.remove(id);
      } else {
        _selectedAreaIds.add(id);
        _areaAttributes.putIfAbsent(id, () => _defaultAttributesForArea(id));
      }
    });
  }

  void _toggleAreaAttribute(String areaId, String attributeId) {
    setState(() {
      final selected = List<String>.from(
        _areaAttributes[areaId] ?? _defaultAttributesForArea(areaId),
      );
      if (selected.contains(attributeId)) {
        if (selected.length > 1) selected.remove(attributeId);
      } else if (selected.length < 3) {
        selected.add(attributeId);
      } else {
        selected
          ..removeAt(0)
          ..add(attributeId);
      }
      _areaAttributes[areaId] = selected;
    });
  }

  void _setRecommendedSetup(bool value) {
    setState(() {
      _useRecommendedSetup = value;
      if (value) {
        _selectedAreaIds
          ..clear()
          ..addAll(_defaultAreaIds);
        for (final area in _areaOptions) {
          _areaAttributes[area.id] = _defaultAttributesForArea(area.id);
        }
        _victoryMinimumPercent = 60;
        _victoryGoodPercent = 75;
        _victoryExcellentPercent = 90;
        _waterTargetMl = 1000;
        _useStarterPresets = true;
      }
    });
  }

  void _setDurationMonths(int months) {
    final start =
        DateTime.tryParse(_campaignStartController.text.trim()) ??
        DateTime.now();
    final end = DateTime(start.year, start.month + months, start.day);
    setState(() => _campaignEndController.text = _dateKey(end));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: GameColors.appBackgroundGradient),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: GameSpacing.screen,
            child: GameEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Erro ao carregar configuração inicial',
              message: _error.toString(),
              actionLabel: 'Tentar novamente',
              onAction: _load,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: GameColors.appBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(pageIndex: _pageIndex, saving: _saving),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  children: [
                    _HeroStep(
                      nameController: _nameController,
                      titleController: _titleController,
                    ),
                    _DifficultyStep(
                      selectedMode: _difficultyMode,
                      hardcoreEligibility: _hardcoreEligibility,
                      canSelectHardcore: _canSelectHardcore,
                      onChanged: (mode) =>
                          setState(() => _difficultyMode = mode),
                      onLockedHardcoreTap: () => _showMessage(
                        '${_hardcoreEligibility.progressLabel}. Complete '
                        '${_hardcoreEligibility.requiredCheckIns} check-ins '
                        'v\u00e1lidos para liberar o Hardcore.',
                      ),
                    ),
                    _ConfigModeStep(
                      useRecommendedSetup: _useRecommendedSetup,
                      onChanged: _setRecommendedSetup,
                    ),
                    _CampaignStep(
                      titleController: _campaignTitleController,
                      descriptionController: _campaignDescriptionController,
                      mainGoalController: _campaignMainGoalController,
                      loreController: _campaignLoreController,
                      startController: _campaignStartController,
                      endController: _campaignEndController,
                      onDurationSelected: _setDurationMonths,
                    ),
                    _VictoryStep(
                      minimumPercent: _victoryMinimumPercent,
                      goodPercent: _victoryGoodPercent,
                      excellentPercent: _victoryExcellentPercent,
                      onMinimumChanged: (value) => setState(() {
                        _victoryMinimumPercent = value.round();
                        if (_victoryGoodPercent < _victoryMinimumPercent) {
                          _victoryGoodPercent = _victoryMinimumPercent;
                        }
                        if (_victoryExcellentPercent < _victoryGoodPercent) {
                          _victoryExcellentPercent = _victoryGoodPercent;
                        }
                      }),
                      onGoodChanged: (value) => setState(() {
                        _victoryGoodPercent = value
                            .round()
                            .clamp(_victoryMinimumPercent, 100)
                            .toInt();
                        if (_victoryExcellentPercent < _victoryGoodPercent) {
                          _victoryExcellentPercent = _victoryGoodPercent;
                        }
                      }),
                      onExcellentChanged: (value) => setState(() {
                        _victoryExcellentPercent = value
                            .round()
                            .clamp(_victoryGoodPercent, 100)
                            .toInt();
                      }),
                    ),
                    _AreasStep(
                      options: _areaOptions,
                      selectedAreaIds: _selectedAreaIds,
                      onToggle: _toggleArea,
                    ),
                    _AreaAttributesStep(
                      areas: _areaOptions
                          .where((area) => _selectedAreaIds.contains(area.id))
                          .toList(),
                      attributes: _attributeOptions,
                      areaAttributes: _areaAttributes,
                      onToggleAttribute: _toggleAreaAttribute,
                    ),
                    _FinalStep(
                      waterTargetMl: _waterTargetMl,
                      useStarterPresets: _useStarterPresets,
                      useRecommendedSetup: _useRecommendedSetup,
                      difficultyLabel: _difficultyLabel(_difficultyMode),
                      campaignTitle: _campaignTitleController.text,
                      selectedAreaLabels: _selectedAreaLabels,
                      victorySummary:
                          '$_victoryMinimumPercent% / $_victoryGoodPercent% / $_victoryExcellentPercent%',
                      onWaterChanged: (value) =>
                          setState(() => _waterTargetMl = value.round()),
                      onPresetChanged: (value) =>
                          setState(() => _useStarterPresets = value),
                    ),
                  ],
                ),
              ),
              _Footer(
                pageIndex: _pageIndex,
                saving: _saving,
                onBack: _pageIndex == 0 ? null : _back,
                onNext: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> get _orderedSelectedAreaIds {
    return [
      for (final area in _areaOptions)
        if (_selectedAreaIds.contains(area.id)) area.id,
    ];
  }

  List<String> get _selectedAreaLabels {
    return [
      for (final area in _areaOptions)
        if (_selectedAreaIds.contains(area.id)) area.title,
    ];
  }

  List<String> _focusAreasFromSelectedAreas() {
    final focus = <String>{};
    if (_selectedAreaIds.contains('body_health')) focus.add('health');
    if (_selectedAreaIds.contains('mind_knowledge') ||
        _selectedAreaIds.contains('projects_career')) {
      focus.add('study');
    }
    if (_selectedAreaIds.contains('spirit_purpose')) focus.add('faith');
    if (_selectedAreaIds.contains('finance_responsibility')) {
      focus.add('finance');
    }
    if (_selectedAreaIds.contains('routine_order')) focus.add('discipline');
    if (focus.isEmpty) focus.addAll(const ['health', 'discipline']);
    return focus.toList();
  }

  String _difficultyLabel(String mode) {
    return switch (mode) {
      'hard' => 'Difícil',
      'hardcore' => 'Hardcore',
      _ => 'Normal',
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.pageIndex, required this.saving});

  final int pageIndex;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final progress = (pageIndex + 1) / _totalPages;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GameSpacing.md,
        GameSpacing.md,
        GameSpacing.md,
        0,
      ),
      child: GameHighlightCard(
        accentColor: GameColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.rocket_launch_rounded,
                  color: GameColors.rewardSoft,
                  size: 32,
                ),
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: Text(
                    'Início da Campanha',
                    style: GameTextStyles.title,
                  ),
                ),
                GameChip(
                  label: '${pageIndex + 1}/$_totalPages',
                  icon: Icons.flag_rounded,
                  color: GameColors.primary,
                  selected: true,
                ),
              ],
            ),
            const SizedBox(height: GameSpacing.xs),
            Text(
              'Configure herói, campanha, áreas e presets. O app começa mais inteligente sem virar formulário infinito.',
              style: GameTextStyles.body,
            ),
            const SizedBox(height: GameSpacing.md),
            GameProgressBar(
              value: progress,
              height: 8,
              color: GameColors.reward,
              showGlow: true,
            ),
            if (saving) ...[
              const SizedBox(height: GameSpacing.sm),
              const LinearProgressIndicator(minHeight: 3),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroStep extends StatelessWidget {
  const _HeroStep({
    required this.nameController,
    required this.titleController,
  });

  final TextEditingController nameController;
  final TextEditingController titleController;

  @override
  Widget build(BuildContext context) {
    return _StepBody(
      icon: Icons.shield_rounded,
      title: 'Quem está entrando nessa jornada?',
      subtitle:
          'Nome e título aparecem no perfil do herói. Depois a gente evolui isso para ranks e títulos por conquista.',
      children: [
        TextField(
          controller: nameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Nome do herói',
            hintText: 'Ex.: Rick',
            prefixIcon: Icon(Icons.person_rounded),
          ),
        ),
        const SizedBox(height: GameSpacing.sm),
        TextField(
          controller: titleController,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Título inicial',
            hintText: 'Ex.: Iniciante da Transformação',
            prefixIcon: Icon(Icons.military_tech_rounded),
          ),
        ),
      ],
    );
  }
}

class _DifficultyStep extends StatelessWidget {
  const _DifficultyStep({
    required this.selectedMode,
    required this.hardcoreEligibility,
    required this.canSelectHardcore,
    required this.onChanged,
    required this.onLockedHardcoreTap,
  });

  final String selectedMode;
  final HardcoreEligibility hardcoreEligibility;
  final bool canSelectHardcore;
  final ValueChanged<String> onChanged;
  final VoidCallback onLockedHardcoreTap;

  @override
  Widget build(BuildContext context) {
    final hardcoreDescription = !canSelectHardcore
        ? '${hardcoreEligibility.progressLabel}. Complete '
              '${hardcoreEligibility.requiredCheckIns} check-ins '
              'v\u00e1lidos para desbloquear.'
        : !hardcoreEligibility.isUnlocked
        ? 'Hardcore j\u00e1 ativo. ${hardcoreEligibility.progressLabel}; '
              'o estado existente ser\u00e1 preservado.'
        : '${hardcoreEligibility.progressLabel}. Penalidade de 100% do XP.';

    return _StepBody(
      icon: Icons.shield_moon_rounded,
      title: 'Escolha o modo de jogo',
      subtitle:
          'Hardcore exige ${hardcoreEligibility.requiredCheckIns} check-ins '
          'v\u00e1lidos. Primeiro consist\u00eancia, depois pancadaria.',
      children: [
        _DifficultyCard(
          title: 'Normal',
          description: 'Sem penalidade. Se falhar, só deixa de ganhar XP.',
          icon: Icons.self_improvement_rounded,
          color: GameColors.success,
          selected: selectedMode == 'normal',
          onTap: () => onChanged('normal'),
        ),
        const SizedBox(height: GameSpacing.sm),
        _DifficultyCard(
          title: 'Difícil',
          description:
              'Penalidade de 50% do XP da missão vencida. Mais exigente, ainda justo.',
          icon: Icons.local_fire_department_rounded,
          color: GameColors.warning,
          selected: selectedMode == 'hard',
          onTap: () => onChanged('hard'),
        ),
        const SizedBox(height: GameSpacing.sm),
        _DifficultyCard(
          title: canSelectHardcore ? 'Hardcore' : 'Hardcore bloqueado',
          description: hardcoreDescription,
          icon: canSelectHardcore ? Icons.whatshot_rounded : Icons.lock_rounded,
          color: GameColors.danger,
          selected: selectedMode == 'hardcore',
          locked: !canSelectHardcore,
          onTap: canSelectHardcore
              ? () => onChanged('hardcore')
              : onLockedHardcoreTap,
        ),
      ],
    );
  }
}

class _ConfigModeStep extends StatelessWidget {
  const _ConfigModeStep({
    required this.useRecommendedSetup,
    required this.onChanged,
  });

  final bool useRecommendedSetup;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepBody(
      icon: Icons.tune_rounded,
      title: 'Como quer configurar?',
      subtitle:
          'O recomendado já vem pronto. O personalizado libera ajustes de campanha, áreas, atributos e vitória sem precisar caçar configuração depois.',
      children: [
        _ChoiceCard(
          title: 'Usar configuração recomendada',
          description:
              'Transformação dos 20 aos 25, áreas principais e atributos já sugeridos.',
          icon: Icons.auto_awesome_rounded,
          color: GameColors.reward,
          selected: useRecommendedSetup,
          onTap: () => onChanged(true),
        ),
        const SizedBox(height: GameSpacing.sm),
        _ChoiceCard(
          title: 'Personalizar minha campanha',
          description:
              'Você revisa campanha, áreas e atributos logo no início.',
          icon: Icons.construction_rounded,
          color: GameColors.primary,
          selected: !useRecommendedSetup,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _CampaignStep extends StatelessWidget {
  const _CampaignStep({
    required this.titleController,
    required this.descriptionController,
    required this.mainGoalController,
    required this.loreController,
    required this.startController,
    required this.endController,
    required this.onDurationSelected,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController mainGoalController;
  final TextEditingController loreController;
  final TextEditingController startController;
  final TextEditingController endController;
  final ValueChanged<int> onDurationSelected;

  @override
  Widget build(BuildContext context) {
    return _StepBody(
      icon: Icons.map_rounded,
      title: 'Configure a campanha',
      subtitle:
          'A campanha é a trajetória principal. Missões, hábitos e objetivos vão começar a apontar para ela com mais inteligência nos próximos sprints.',
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Nome da campanha',
            hintText: 'Ex.: Transformação dos 20 aos 25',
            prefixIcon: Icon(Icons.flag_rounded),
          ),
        ),
        const SizedBox(height: GameSpacing.sm),
        TextField(
          controller: descriptionController,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Descrição',
            hintText: 'Resumo da jornada.',
            prefixIcon: Icon(Icons.description_rounded),
          ),
        ),
        const SizedBox(height: GameSpacing.sm),
        TextField(
          controller: mainGoalController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Objetivo principal',
            hintText:
                'O que precisa ser verdade quando a campanha for vencida?',
            prefixIcon: Icon(Icons.gps_fixed_rounded),
          ),
        ),
        const SizedBox(height: GameSpacing.sm),
        TextField(
          controller: loreController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Lore / declaração da campanha',
            hintText: 'Uma frase narrativa para dar peso à jornada.',
            prefixIcon: Icon(Icons.auto_stories_rounded),
          ),
        ),
        const SizedBox(height: GameSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: startController,
                decoration: const InputDecoration(
                  labelText: 'Início',
                  hintText: 'AAAA-MM-DD',
                  prefixIcon: Icon(Icons.event_available_rounded),
                ),
              ),
            ),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: TextField(
                controller: endController,
                decoration: const InputDecoration(
                  labelText: 'Fim',
                  hintText: 'AAAA-MM-DD',
                  prefixIcon: Icon(Icons.event_rounded),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: GameSpacing.sm),
        Wrap(
          spacing: GameSpacing.xs,
          runSpacing: GameSpacing.xs,
          children: [
            GameChip(
              label: '3 meses',
              icon: Icons.schedule_rounded,
              onTap: () => onDurationSelected(3),
            ),
            GameChip(
              label: '6 meses',
              icon: Icons.schedule_rounded,
              onTap: () => onDurationSelected(6),
            ),
            GameChip(
              label: '1 ano',
              icon: Icons.schedule_rounded,
              onTap: () => onDurationSelected(12),
            ),
            GameChip(
              label: '5 anos',
              icon: Icons.schedule_rounded,
              selected: true,
              onTap: () => onDurationSelected(60),
            ),
          ],
        ),
      ],
    );
  }
}

class _VictoryStep extends StatelessWidget {
  const _VictoryStep({
    required this.minimumPercent,
    required this.goodPercent,
    required this.excellentPercent,
    required this.onMinimumChanged,
    required this.onGoodChanged,
    required this.onExcellentChanged,
  });

  final int minimumPercent;
  final int goodPercent;
  final int excellentPercent;
  final ValueChanged<double> onMinimumChanged;
  final ValueChanged<double> onGoodChanged;
  final ValueChanged<double> onExcellentChanged;

  @override
  Widget build(BuildContext context) {
    return _StepBody(
      icon: Icons.emoji_events_rounded,
      title: 'Padrões de vitória',
      subtitle:
          'Esses valores definem como a campanha interpreta progresso: vitória mínima, boa ou excelente.',
      children: [
        _SliderCard(
          title: 'Vitória mínima',
          valueLabel: '$minimumPercent%',
          description:
              'A campanha avançou o suficiente para ser considerada vencida no básico.',
          color: GameColors.success,
          value: minimumPercent.toDouble(),
          min: 40,
          max: 80,
          onChanged: onMinimumChanged,
        ),
        const SizedBox(height: GameSpacing.sm),
        _SliderCard(
          title: 'Vitória boa',
          valueLabel: '$goodPercent%',
          description: 'Um resultado sólido, acima do mínimo esperado.',
          color: GameColors.reward,
          value: goodPercent.toDouble(),
          min: minimumPercent.toDouble(),
          max: 95,
          onChanged: onGoodChanged,
        ),
        const SizedBox(height: GameSpacing.sm),
        _SliderCard(
          title: 'Vitória excelente',
          valueLabel: '$excellentPercent%',
          description: 'O alvo alto: campanha muito bem executada.',
          color: GameColors.primary,
          value: excellentPercent.toDouble(),
          min: goodPercent.toDouble(),
          max: 100,
          onChanged: onExcellentChanged,
        ),
      ],
    );
  }
}

class _AreasStep extends StatelessWidget {
  const _AreasStep({
    required this.options,
    required this.selectedAreaIds,
    required this.onToggle,
  });

  final List<_AreaOption> options;
  final Set<String> selectedAreaIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return _StepBody(
      icon: Icons.grid_view_rounded,
      title: 'Áreas da vida',
      subtitle:
          'Essas áreas serão usadas para sugerir atributos e, depois, alimentar capítulos da campanha automaticamente.',
      children: [
        for (final option in options) ...[
          _AreaCard(
            option: option,
            selected: selectedAreaIds.contains(option.id),
            onTap: () => onToggle(option.id),
          ),
          const SizedBox(height: GameSpacing.sm),
        ],
      ],
    );
  }
}

class _AreaAttributesStep extends StatelessWidget {
  const _AreaAttributesStep({
    required this.areas,
    required this.attributes,
    required this.areaAttributes,
    required this.onToggleAttribute,
  });

  final List<_AreaOption> areas;
  final List<_AttributeOption> attributes;
  final Map<String, List<String>> areaAttributes;
  final void Function(String areaId, String attributeId) onToggleAttribute;

  @override
  Widget build(BuildContext context) {
    return _StepBody(
      icon: Icons.account_tree_rounded,
      title: 'Atributos por área',
      subtitle:
          'Escolha até 3 atributos por área. A ordem importa: primeiro recebe mais peso, depois vem o segundo e terceiro.',
      children: [
        for (final area in areas) ...[
          GameCard(
            backgroundColor: GameColors.surfaceSoft,
            borderColor: area.color.withValues(alpha: 0.45),
            accentColor: area.color,
            padding: const EdgeInsets.all(GameSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(area.icon, color: area.color),
                    const SizedBox(width: GameSpacing.xs),
                    Expanded(
                      child: Text(area.title, style: GameTextStyles.cardTitle),
                    ),
                  ],
                ),
                const SizedBox(height: GameSpacing.sm),
                Wrap(
                  spacing: GameSpacing.xs,
                  runSpacing: GameSpacing.xs,
                  children: [
                    for (final attribute in attributes)
                      GameChip(
                        label: _chipLabel(
                          areaAttributes[area.id] ?? const <String>[],
                          attribute,
                        ),
                        icon: attribute.icon,
                        color: attribute.color,
                        selected: (areaAttributes[area.id] ?? const <String>[])
                            .contains(attribute.id),
                        onTap: () => onToggleAttribute(area.id, attribute.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: GameSpacing.sm),
        ],
      ],
    );
  }

  String _chipLabel(List<String> selected, _AttributeOption attribute) {
    final index = selected.indexOf(attribute.id);
    if (index < 0) return attribute.title;
    return '${index + 1}. ${attribute.title}';
  }
}

class _FinalStep extends StatelessWidget {
  const _FinalStep({
    required this.waterTargetMl,
    required this.useStarterPresets,
    required this.useRecommendedSetup,
    required this.difficultyLabel,
    required this.campaignTitle,
    required this.selectedAreaLabels,
    required this.victorySummary,
    required this.onWaterChanged,
    required this.onPresetChanged,
  });

  final int waterTargetMl;
  final bool useStarterPresets;
  final bool useRecommendedSetup;
  final String difficultyLabel;
  final String campaignTitle;
  final List<String> selectedAreaLabels;
  final String victorySummary;
  final ValueChanged<double> onWaterChanged;
  final ValueChanged<bool> onPresetChanged;

  @override
  Widget build(BuildContext context) {
    return _StepBody(
      icon: Icons.fact_check_rounded,
      title: 'Revisão final',
      subtitle:
          'Últimos ajustes antes de iniciar. Isso evita começar perdido e ter que configurar tudo no susto.',
      children: [
        GameCard(
          backgroundColor: GameColors.surfaceSoft,
          padding: const EdgeInsets.all(GameSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_drop_rounded, color: GameColors.info),
                  const SizedBox(width: GameSpacing.sm),
                  Expanded(
                    child: Text(
                      'Meta inicial de água',
                      style: GameTextStyles.cardTitle,
                    ),
                  ),
                  Text('$waterTargetMl ml', style: GameTextStyles.statValue),
                ],
              ),
              Slider(
                value: waterTargetMl.toDouble(),
                min: 500,
                max: 4000,
                divisions: 14,
                label: '$waterTargetMl ml',
                onChanged: onWaterChanged,
              ),
              Text(
                'Começa simples. Dá pra ajustar depois na tela de Saúde.',
                style: GameTextStyles.caption,
              ),
            ],
          ),
        ),
        const SizedBox(height: GameSpacing.sm),
        GameCard(
          backgroundColor: GameColors.surfaceSoft,
          padding: const EdgeInsets.all(GameSpacing.md),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: useStarterPresets,
            onChanged: onPresetChanged,
            title: Text(
              'Ativar hábitos/presets iniciais',
              style: GameTextStyles.cardTitle,
            ),
            subtitle: Text(
              'Reforça hábitos essenciais e cria presets leves conforme as áreas escolhidas.',
              style: GameTextStyles.caption,
            ),
          ),
        ),
        const SizedBox(height: GameSpacing.sm),
        GameCard(
          backgroundColor: GameColors.surfaceRaised,
          padding: const EdgeInsets.all(GameSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumo', style: GameTextStyles.cardTitle),
              const SizedBox(height: GameSpacing.sm),
              _SummaryLine(
                icon: Icons.shield_moon_rounded,
                label: 'Dificuldade',
                value: difficultyLabel,
              ),
              _SummaryLine(
                icon: Icons.map_rounded,
                label: 'Campanha',
                value: campaignTitle.trim().isEmpty
                    ? 'Transformação dos 20 aos 25'
                    : campaignTitle.trim(),
              ),
              _SummaryLine(
                icon: Icons.grid_view_rounded,
                label: 'Áreas',
                value: selectedAreaLabels.join(', '),
              ),
              _SummaryLine(
                icon: Icons.emoji_events_rounded,
                label: 'Vitórias',
                value: victorySummary,
              ),
              _SummaryLine(
                icon: Icons.water_drop_rounded,
                label: 'Água',
                value: '$waterTargetMl ml por dia',
              ),
              _SummaryLine(
                icon: Icons.auto_awesome_rounded,
                label: 'Modo',
                value: useRecommendedSetup ? 'Recomendado' : 'Personalizado',
              ),
              _SummaryLine(
                icon: Icons.inventory_2_rounded,
                label: 'Presets',
                value: useStarterPresets ? 'Ativos' : 'Não aplicar agora',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: GameSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameColors.primary.withValues(alpha: 0.16),
                ),
                child: Icon(icon, color: GameColors.primary, size: 24),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GameTextStyles.title),
                    const SizedBox(height: GameSpacing.xs),
                    Text(subtitle, style: GameTextStyles.body),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.lg),
          ...children,
          const SizedBox(height: GameSpacing.lg),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = locked ? GameColors.textMuted : color;
    return GameCard(
      onTap: onTap,
      backgroundColor: selected
          ? effectiveColor.withValues(alpha: 0.16)
          : GameColors.surfaceSoft,
      borderColor: selected ? effectiveColor : GameColors.border,
      padding: const EdgeInsets.all(GameSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor, size: 28),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GameTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(description, style: GameTextStyles.caption),
              ],
            ),
          ),
          Icon(
            locked
                ? Icons.lock_rounded
                : selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? effectiveColor : GameColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      onTap: onTap,
      backgroundColor: selected
          ? color.withValues(alpha: 0.16)
          : GameColors.surfaceSoft,
      borderColor: selected ? color : GameColors.border,
      padding: const EdgeInsets.all(GameSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GameTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(description, style: GameTextStyles.caption),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected ? color : GameColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _AreaOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      onTap: onTap,
      backgroundColor: selected
          ? option.color.withValues(alpha: 0.16)
          : GameColors.surfaceSoft,
      borderColor: selected ? option.color : GameColors.border,
      accentColor: selected ? option.color : null,
      padding: const EdgeInsets.all(GameSpacing.md),
      child: Row(
        children: [
          Icon(option.icon, color: option.color, size: 28),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option.title, style: GameTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(option.description, style: GameTextStyles.caption),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected ? option.color : GameColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.title,
    required this.valueLabel,
    required this.description,
    required this.color,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final String valueLabel;
  final String description;
  final Color color;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeMax = max <= min ? min + 1 : max;
    final safeValue = value.clamp(min, safeMax).toDouble();
    return GameCard(
      backgroundColor: GameColors.surfaceSoft,
      borderColor: color.withValues(alpha: 0.40),
      accentColor: color,
      padding: const EdgeInsets.all(GameSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: GameTextStyles.cardTitle)),
              Text(
                valueLabel,
                style: GameTextStyles.statValue.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.xs),
          Text(description, style: GameTextStyles.caption),
          Slider(
            value: safeValue,
            min: min,
            max: safeMax,
            divisions: (safeMax - min).round(),
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GameSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: GameColors.textMuted),
          const SizedBox(width: GameSpacing.xs),
          Text(
            '$label: ',
            style: GameTextStyles.caption.copyWith(
              color: GameColors.textSecondary,
            ),
          ),
          Expanded(child: Text(value, style: GameTextStyles.caption)),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.pageIndex,
    required this.saving,
    required this.onBack,
    required this.onNext,
  });

  final int pageIndex;
  final bool saving;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GameSpacing.md,
          GameSpacing.sm,
          GameSpacing.md,
          GameSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: GameSecondaryButton(
                label: 'Voltar',
                icon: Icons.arrow_back_rounded,
                onPressed: saving ? null : onBack,
              ),
            ),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: GamePrimaryButton(
                label: pageIndex >= _totalPages - 1
                    ? 'Iniciar campanha'
                    : 'Continuar',
                icon: pageIndex >= _totalPages - 1
                    ? Icons.rocket_launch_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: saving ? null : onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaOption {
  const _AreaOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

class _AttributeOption {
  const _AttributeOption({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;
}

const List<String> _defaultAreaIds = [
  'body_health',
  'mind_knowledge',
  'spirit_purpose',
  'projects_career',
  'finance_responsibility',
  'routine_order',
];

List<String> _defaultAttributesForArea(String areaId) {
  return switch (areaId) {
    'body_health' => const ['vigor', 'strength', 'discipline'],
    'mind_knowledge' => const ['clarity', 'focus', 'discipline'],
    'spirit_purpose' => const ['faith', 'clarity', 'discipline'],
    'projects_career' => const ['focus', 'responsibility', 'clarity'],
    'creation_expression' => const ['creativity', 'focus', 'clarity'],
    'finance_responsibility' => const [
      'responsibility',
      'discipline',
      'clarity',
    ],
    'routine_order' => const ['discipline', 'responsibility', 'clarity'],
    _ => const ['discipline', 'focus', 'clarity'],
  };
}

String _dateKey(DateTime date) {
  final local = date.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
