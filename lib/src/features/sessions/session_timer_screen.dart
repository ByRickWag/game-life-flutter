import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/repositories/session_repository.dart';
import '../../core/services/area_attribute_suggestion_service.dart';
import '../../core/services/reward_service.dart';
import '../../design_system/game_design_system.dart';
import '../../shared/widgets/attribute_multi_select_field.dart';

class SessionTimerScreen extends StatefulWidget {
  const SessionTimerScreen({super.key});

  @override
  State<SessionTimerScreen> createState() => _SessionTimerScreenState();
}

class _SessionTimerScreenState extends State<SessionTimerScreen> {
  final _repository = SessionRepository();
  final _areaSuggestionService = AreaAttributeSuggestionService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Sessão de foco');
  final _notesController = TextEditingController();

  Timer? _timer;
  List<Map<String, Object?>> _areas = [];
  List<Map<String, Object?>> _attributes = [];

  String _sessionType = 'study';
  String? _areaId;
  final List<String> _attributeIds = [];
  int _elapsedSeconds = 0;
  int _secondsSincePresence = 0;
  int _presenceLimitMinutes = 25;
  bool _loading = true;
  bool _running = false;
  bool _lockedForPresence = false;
  bool _saving = false;
  String? _error;
  SessionReward? _preview;

  static const _sessionTypes = [
    _SessionTypeOption('training', 'Treino', Icons.fitness_center_rounded, GameColors.strength),
    _SessionTypeOption('study', 'Estudo', Icons.school_rounded, GameColors.clarity),
    _SessionTypeOption('devotional', 'Devocional', Icons.auto_awesome_rounded, GameColors.faith),
    _SessionTypeOption('programming', 'Programação', Icons.code_rounded, GameColors.focus),
    _SessionTypeOption('project', 'Projeto', Icons.folder_special_rounded, GameColors.reward),
    _SessionTypeOption('organization', 'Organização', Icons.checklist_rounded, GameColors.discipline),
    _SessionTypeOption('reading', 'Leitura', Icons.menu_book_rounded, GameColors.info),
    _SessionTypeOption('finance', 'Finanças', Icons.savings_rounded, GameColors.responsibility),
    _SessionTypeOption('general', 'Geral', Icons.timer_rounded, GameColors.success),
  ];

  static const _presenceOptions = [15, 25, 40, 60];

  int get _elapsedMinutesForReward => math.max(1, (_elapsedSeconds + 59) ~/ 60);

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        _areaSuggestionService.loadActiveAreas(),
        _repository.getAttributes(),
      ]);

      if (!mounted) return;
      final areas = results[0];
      final attributes = results[1];
      final initialAreaId = _resolveAreaForSessionType(_sessionType, areas) ?? (areas.isNotEmpty ? areas.first['id']?.toString() : null);
      final suggestedAttributeIds = await _areaSuggestionService.suggestAttributeIds(initialAreaId);

      setState(() {
        _areas = areas;
        _attributes = attributes;
        _areaId = initialAreaId;
        if (_attributeIds.isEmpty) {
          if (suggestedAttributeIds.isNotEmpty) {
            _attributeIds.addAll(suggestedAttributeIds);
          } else if (_attributes.isNotEmpty) {
            final firstAttributeId = _attributes.first['id']?.toString();
            if (firstAttributeId != null && firstAttributeId.isNotEmpty) {
              _attributeIds.add(firstAttributeId);
            }
          }
        }
        _loading = false;
      });
      await _refreshPreview();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _applyAreaAttributes(String? areaId) async {
    final suggestedAttributeIds = await _areaSuggestionService.suggestAttributeIds(areaId);
    if (!mounted || suggestedAttributeIds.isEmpty) return;

    setState(() {
      _attributeIds
        ..clear()
        ..addAll(suggestedAttributeIds);
    });
  }

  Future<void> _applySessionTypeDefaults(String sessionType) async {
    final suggestedAreaId = _resolveAreaForSessionType(sessionType, _areas);
    if (suggestedAreaId == null) return;

    setState(() => _areaId = suggestedAreaId);
    await _applyAreaAttributes(suggestedAreaId);
  }

  Future<void> _refreshPreview() async {
    try {
      final reward = await _repository.previewReward(durationMinutes: _elapsedMinutesForReward);
      if (!mounted) return;
      setState(() => _preview = reward);
    } catch (_) {
      // Preview não pode travar a sessão.
    }
  }

  void _startOrResume() {
    if (_lockedForPresence || _saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    _timer?.cancel();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running || _lockedForPresence) return;
      setState(() {
        _elapsedSeconds++;
        _secondsSincePresence++;
        if (_secondsSincePresence >= _presenceLimitMinutes * 60) {
          _running = false;
          _lockedForPresence = true;
        }
      });
      if (_elapsedSeconds % 15 == 0) {
        unawaited(_refreshPreview());
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
    unawaited(_refreshPreview());
  }

  void _confirmPresence() {
    setState(() {
      _lockedForPresence = false;
      _secondsSincePresence = 0;
    });
    _startOrResume();
  }

  Future<void> _finish() async {
    if (_saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    _timer?.cancel();
    setState(() {
      _running = false;
      _saving = true;
    });

    try {
      final result = await _repository.createSession(
        CreateSessionInput(
          title: _titleController.text,
          sessionType: _sessionType,
          areaId: _areaId,
          attributeIds: _attributeIds,
          durationMinutes: _elapsedMinutesForReward,
          notes: _notesController.text,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (result.saved) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao finalizar sessão: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessão com contador'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final error = _error;
    if (error != null) {
      return SingleChildScrollView(
        padding: GameSpacing.screen,
        child: GameEmptyState(
          title: 'Erro ao carregar contador',
          message: error,
          icon: Icons.warning_rounded,
          actionLabel: 'Tentar novamente',
          onAction: _loadOptions,
        ),
      );
    }

    final selectedType = _sessionTypes.firstWhere(
      (type) => type.id == _sessionType,
      orElse: () => _sessionTypes.last,
    );
    final reward = _preview;
    final xpLabel = reward == null ? '0' : '${reward.xp}';
    final capLabel = reward?.reachedCap == true
        ? 'Teto atingido'
        : 'Teto ${reward?.xpCap ?? RewardService.sessionXpCap} XP';
    final areaValue = _areas.any((area) => area['id']?.toString() == _areaId) ? _areaId : null;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: GameSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameHighlightCard(
              accentColor: selectedType.color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(selectedType.icon, color: selectedType.color, size: 34),
                      const SizedBox(width: GameSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Foco em andamento', style: GameTextStyles.title),
                            Text(
                              _lockedForPresence
                                  ? 'Confirme presença para continuar contando.'
                                  : 'Use o contador para não precisar lembrar quando começou.',
                              style: GameTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GameSpacing.lg),
                  Center(
                    child: Text(
                      _formatTimer(_elapsedSeconds),
                      style: GameTextStyles.display.copyWith(fontSize: 42),
                    ),
                  ),
                  const SizedBox(height: GameSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: GameStatTile(
                          label: 'XP previsto',
                          value: '+$xpLabel',
                          icon: Icons.bolt_rounded,
                          color: GameColors.primary,
                        ),
                      ),
                      const SizedBox(width: GameSpacing.sm),
                      Expanded(
                        child: GameStatTile(
                          label: 'Limite',
                          value: capLabel,
                          icon: Icons.lock_clock_rounded,
                          color: GameColors.reward,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: GameSpacing.md),
            if (_lockedForPresence) ...[
              GameCard(
                backgroundColor: GameColors.reward.withValues(alpha: 0.12),
                child: const Text(
                  'Check-in de presença necessário. O contador foi pausado para evitar XP acumulado por sessão esquecida aberta.',
                  style: GameTextStyles.body,
                ),
              ),
              const SizedBox(height: GameSpacing.sm),
              GamePrimaryButton(
                label: 'Confirmar presença e continuar',
                icon: Icons.touch_app_rounded,
                onPressed: _confirmPresence,
              ),
              const SizedBox(height: GameSpacing.md),
            ],
            Row(
              children: [
                Expanded(
                  child: GamePrimaryButton(
                    label: _running ? 'Pausar' : (_elapsedSeconds == 0 ? 'Iniciar' : 'Continuar'),
                    icon: _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    onPressed: _running ? _pause : _startOrResume,
                  ),
                ),
                const SizedBox(width: GameSpacing.sm),
                Expanded(
                  child: GameSecondaryButton(
                    label: _saving ? 'Salvando...' : 'Finalizar',
                    icon: Icons.stop_circle_rounded,
                    onPressed: _elapsedSeconds <= 0 ? null : _finish,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GameSpacing.lg),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título da sessão'),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 3) return 'Digite um título com pelo menos 3 caracteres.';
                return null;
              },
            ),
            const SizedBox(height: GameSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _sessionType,
              decoration: const InputDecoration(labelText: 'Tipo de sessão'),
              items: _sessionTypes
                  .map((type) => DropdownMenuItem(value: type.id, child: Text(type.label)))
                  .toList(),
              onChanged: _running
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _sessionType = value);
                      _applySessionTypeDefaults(value);
                    },
            ),
            const SizedBox(height: GameSpacing.sm),
            DropdownButtonFormField<int>(
              initialValue: _presenceLimitMinutes,
              decoration: const InputDecoration(labelText: 'Check-in de presença'),
              items: _presenceOptions
                  .map((minutes) => DropdownMenuItem(value: minutes, child: Text('A cada $minutes minutos')))
                  .toList(),
              onChanged: _running
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _presenceLimitMinutes = value);
                    },
            ),
            const SizedBox(height: GameSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: areaValue,
              decoration: const InputDecoration(labelText: 'Área'),
              items: _areas
                  .map((area) => DropdownMenuItem(value: area['id']?.toString(), child: Text(area['name']?.toString() ?? 'Área')))
                  .toList(),
              onChanged: _running
                  ? null
                  : (value) {
                      setState(() => _areaId = value);
                      _applyAreaAttributes(value);
                    },
            ),
            const SizedBox(height: GameSpacing.sm),
            AttributeMultiSelectField(
              attributes: _attributes,
              selectedIds: _attributeIds,
              title: 'Atributos da sessão',
              subtitle: 'O tipo/área da sessão sugere até 3 atributos. Você pode ajustar a ordem.',
              onChanged: _running
                  ? (_) {}
                  : (ids) {
                      setState(() {
                        _attributeIds
                          ..clear()
                          ..addAll(ids);
                      });
                    },
            ),
            const SizedBox(height: GameSpacing.sm),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas',
                hintText: 'Ex.: O que você pretende fazer nesta sessão?',
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}


String? _resolveAreaForSessionType(String sessionType, List<Map<String, Object?>> areas) {
  final preferredAreaId = switch (sessionType) {
    'training' => 'body_health',
    'study' => 'mind_knowledge',
    'reading' => 'mind_knowledge',
    'devotional' => 'spirit_purpose',
    'programming' => 'projects_career',
    'project' => 'projects_career',
    'finance' => 'finance_responsibility',
    'organization' => 'routine_order',
    _ => null,
  };

  if (preferredAreaId == null) return null;
  final exists = areas.any((area) => area['id']?.toString() == preferredAreaId);
  return exists ? preferredAreaId : null;
}

class _SessionTypeOption {
  const _SessionTypeOption(this.id, this.label, this.icon, this.color);

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

String _formatTimer(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;

  final minuteText = minutes.toString().padLeft(2, '0');
  final secondText = secs.toString().padLeft(2, '0');
  if (hours <= 0) return '$minuteText:$secondText';
  return '${hours.toString().padLeft(2, '0')}:$minuteText:$secondText';
}
