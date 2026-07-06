import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/session_repository.dart';
import '../../core/services/area_attribute_suggestion_service.dart';
import '../../core/services/reward_service.dart';
import '../../design_system/game_design_system.dart';
import '../../shared/widgets/attribute_multi_select_field.dart';

class SessionFormScreen extends StatefulWidget {
  const SessionFormScreen({super.key});

  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  final _repository = SessionRepository();
  final _areaSuggestionService = AreaAttributeSuggestionService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _notesController = TextEditingController();

  List<Map<String, Object?>> _areas = [];
  List<Map<String, Object?>> _attributes = [];

  String _sessionType = 'study';
  String? _areaId;
  final List<String> _attributeIds = [];
  SessionReward? _preview;
  bool _loading = true;
  bool _saving = false;
  String? _error;

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

  static const _durationPresets = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _durationController.addListener(_onDurationChanged);
  }

  @override
  void dispose() {
    _durationController.removeListener(_onDurationChanged);
    _titleController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onDurationChanged() {
    unawaited(_refreshPreview());
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
      final initialAreaId = _resolveAreaForSessionType(_sessionType, areas) ?? (areas.isNotEmpty ? readString(areas.first, 'id') : null);
      final suggestedAttributeIds = await _areaSuggestionService.suggestAttributeIds(initialAreaId);

      setState(() {
        _areas = areas;
        _attributes = attributes;
        _areaId = initialAreaId;
        if (_attributeIds.isEmpty) {
          if (suggestedAttributeIds.isNotEmpty) {
            _attributeIds.addAll(suggestedAttributeIds);
          } else if (_attributes.isNotEmpty) {
            final firstAttributeId = readString(_attributes.first, 'id');
            if (firstAttributeId.isNotEmpty) {
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
    final minutes = int.tryParse(_durationController.text.trim()) ?? 0;
    if (minutes <= 0) {
      if (mounted) {
        setState(() {
          _preview = null;
        });
      }
      return;
    }

    try {
      final reward = await _repository.previewReward(durationMinutes: minutes);
      if (!mounted) return;
      setState(() {
        _preview = reward;
      });
    } catch (_) {
      // Preview não pode bloquear o formulário.
    }
  }

  void _applyDurationPreset(int minutes) {
    _durationController.text = minutes.toString();
    _refreshPreview();
  }

  Future<void> _save() async {
    if (_saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _saving = true;
    });

    try {
      final minutes = int.parse(_durationController.text.trim());
      final result = await _repository.createSession(
        CreateSessionInput(
          title: _titleController.text,
          sessionType: _sessionType,
          areaId: _areaId,
          attributeIds: _attributeIds,
          durationMinutes: minutes,
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

      if (result.saved) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar sessão: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova sessão'),
      ),
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return SingleChildScrollView(
        padding: GameSpacing.screen,
        child: GameEmptyState(
          title: 'Erro ao carregar formulário',
          message: error,
          icon: Icons.warning_rounded,
          actionLabel: 'Tentar novamente',
          onAction: _loadOptions,
        ),
      );
    }

    final preview = _preview;
    final selectedType = _sessionTypes.firstWhere(
      (type) => type.id == _sessionType,
      orElse: () => _sessionTypes.last,
    );

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
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedType.color.withValues(alpha: 0.18),
                        ),
                        child: Icon(selectedType.icon, color: selectedType.color),
                      ),
                      const SizedBox(width: GameSpacing.sm),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Registrar esforço real', style: GameTextStyles.title),
                            SizedBox(height: 2),
                            Text('Sessões alimentam XP, coins, atributos e histórico.', style: GameTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GameSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: GameStatTile(
                          label: 'XP previsto',
                          value: '+${preview?.xp ?? 0}',
                          icon: Icons.bolt_rounded,
                          color: GameColors.primary,
                        ),
                      ),
                      const SizedBox(width: GameSpacing.sm),
                      Expanded(
                        child: GameStatTile(
                          label: 'Coins',
                          value: '+${preview?.coins ?? 0}',
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
              title: 'Tipo de sessão',
              subtitle: 'Escolha rapidamente o tipo de esforço registrado.',
              icon: Icons.category_rounded,
            ),
            Wrap(
              spacing: GameSpacing.xs,
              runSpacing: GameSpacing.xs,
              children: [
                for (final type in _sessionTypes)
                  GameChip(
                    label: type.label,
                    icon: type.icon,
                    color: type.color,
                    selected: _sessionType == type.id,
                    onTap: () {
                      setState(() {
                        _sessionType = type.id;
                      });
                      _applySessionTypeDefaults(type.id);
                    },
                  ),
              ],
            ),
            const SizedBox(height: GameSpacing.md),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Título da sessão',
                hintText: 'Ex: Estudo de Flutter',
                prefixIcon: Icon(Icons.edit_rounded),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Digite um título.';
                }
                return null;
              },
            ),
            const SizedBox(height: GameSpacing.sm),
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Duração em minutos',
                hintText: 'Ex: 30',
                prefixIcon: Icon(Icons.timer_rounded),
              ),
              validator: (value) {
                final minutes = int.tryParse((value ?? '').trim());
                if (minutes == null || minutes <= 0) {
                  return 'Digite uma duração válida.';
                }
                if (minutes > 720) {
                  return 'Use no máximo 720 minutos por sessão.';
                }
                return null;
              },
            ),
            const SizedBox(height: GameSpacing.sm),
            Wrap(
              spacing: GameSpacing.xs,
              runSpacing: GameSpacing.xs,
              children: [
                for (final minutes in _durationPresets)
                  GameChip(
                    label: _formatDuration(minutes),
                    icon: Icons.schedule_rounded,
                    color: GameColors.success,
                    selected: _durationController.text.trim() == minutes.toString(),
                    onTap: () => _applyDurationPreset(minutes),
                  ),
              ],
            ),
            const SizedBox(height: GameSpacing.md),
            DropdownButtonFormField<String?>(
              initialValue: _areaId,
              decoration: const InputDecoration(
                labelText: 'Área vinculada',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sem área'),
                ),
                ..._areas.map(
                  (area) => DropdownMenuItem<String?>(
                    value: readString(area, 'id'),
                    child: Text(readString(area, 'name')),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _areaId = value;
                });
                _applyAreaAttributes(value);
              },
            ),
            const SizedBox(height: GameSpacing.sm),
            AttributeMultiSelectField(
              attributes: _attributes,
              selectedIds: _attributeIds,
              title: 'Atributos da sessão',
              subtitle: 'O tipo/área da sessão sugere até 3 atributos. Você pode ajustar a ordem.',
              onChanged: (ids) {
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
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Notas opcionais',
                hintText: 'Ex: estudei widgets, refiz layout, treino leve...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: GameSpacing.md),
            GameCard(
              backgroundColor: GameColors.surfaceSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Prévia de recompensa', style: GameTextStyles.cardTitle),
                  const SizedBox(height: GameSpacing.xs),
                  Text(
                    preview == null
                        ? 'Digite uma duração válida para calcular recompensa.'
                        : 'Esta sessão renderá +${preview.xp} XP e +${preview.coins} coins. Os atributos escolhidos também receberão XP.',
                    style: GameTextStyles.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: GameSpacing.lg),
            GamePrimaryButton(
              label: _saving ? 'Salvando...' : 'Registrar sessão',
              icon: Icons.check_circle_rounded,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: GameSpacing.sm),
            GameSecondaryButton(
              label: 'Cancelar',
              icon: Icons.close_rounded,
              onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            ),
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
  final exists = areas.any((area) => readString(area, 'id') == preferredAreaId);
  return exists ? preferredAreaId : null;
}

class _SessionTypeOption {
  const _SessionTypeOption(this.id, this.label, this.icon, this.color);

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;

  if (hours <= 0) return '${minutes}min';
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}min';
}
