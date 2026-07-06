import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/models/game_models.dart';
import '../../core/repositories/mission_repository.dart';
import '../../core/services/area_attribute_suggestion_service.dart';
import '../../core/services/reward_service.dart';
import '../../shared/widgets/attribute_multi_select_field.dart';
import '../../shared/widgets/gl_card.dart';
import '../../shared/widgets/gl_primary_button.dart';

class MissionFormScreen extends StatefulWidget {
  const MissionFormScreen({super.key, this.mission});

  final Mission? mission;

  @override
  State<MissionFormScreen> createState() => _MissionFormScreenState();
}

class _MissionFormScreenState extends State<MissionFormScreen> {
  final _repository = MissionRepository();
  final _areaSuggestionService = AreaAttributeSuggestionService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _xpController = TextEditingController();

  String _type = 'daily';
  String _difficulty = 'normal';
  String? _areaId;
  final List<String> _attributeIds = [];
  bool _isCompound = false;
  bool _saving = false;
  bool _initialized = false;
  int _currentXpCap = 30;
  int _taskCount = 0;

  Future<_MissionFormData>? _future;

  bool get _editing => widget.mission != null;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  Future<_MissionFormData> _load() async {
    final areas = await _areaSuggestionService.loadActiveAreas();
    final attributes = await _repository.getAttributes();

    final mission = widget.mission;
    if (mission != null) {
      _taskCount = (await _repository.getMissionTaskStats(mission.id)).total;
    }

    if (!_initialized && mission != null) {
      _titleController.text = mission.title;
      _descriptionController.text = mission.description;
      _notesController.text = mission.notes;
      _isCompound = mission.isCompound || _taskCount > 0;
      _type = mission.type;
      _difficulty = mission.difficulty;
      _areaId = mission.areaId;
      _xpController.text = mission.xpReward.toString();

      final linkedAttributes = await _repository.getAttributeIdsForMission(mission.id);
      _attributeIds
        ..clear()
        ..addAll(linkedAttributes);

      if (_attributeIds.isEmpty && mission.attributeId != null) {
        _attributeIds.add(mission.attributeId!);
      }

      _initialized = true;
    }

    _areaId ??= areas.isNotEmpty ? areas.first['id']?.toString() : null;
    if (_attributeIds.isEmpty) {
      final suggestedAttributeIds = await _areaSuggestionService.suggestAttributeIds(_areaId);
      if (suggestedAttributeIds.isNotEmpty) {
        _attributeIds.addAll(suggestedAttributeIds);
      } else if (attributes.isNotEmpty) {
        final firstAttributeId = attributes.first['id']?.toString();
        if (firstAttributeId != null && firstAttributeId.isNotEmpty) {
          _attributeIds.add(firstAttributeId);
        }
      }
    }

    final xpCap = await _repository.getMissionXpCap(
      type: _type,
      difficulty: _difficulty,
    );
    _currentXpCap = xpCap;

    final reward = await _repository.previewReward(
      type: _type,
      difficulty: _difficulty,
    );

    if (_xpController.text.trim().isEmpty) {
      _xpController.text = reward.xp.toString();
    } else {
      _clampXpField(silent: true);
    }

    return _MissionFormData(
      areas: areas,
      attributes: attributes,
      reward: reward,
      xpCap: xpCap,
      taskCount: _taskCount,
    );
  }

  Future<void> _refreshReward() async {
    _clampXpField(silent: true);
    setState(() {
      _future = _load();
    });
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

  void _clampXpField({bool silent = false}) {
    final value = int.tryParse(_xpController.text.trim()) ?? _currentXpCap;
    final clamped = RewardService.clampXpToCap(value: value, cap: _currentXpCap);
    if (clamped.toString() != _xpController.text.trim()) {
      _xpController.text = clamped.toString();
      _xpController.selection = TextSelection.collapsed(offset: _xpController.text.length);
    }
    if (!silent && mounted) setState(() {});
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _saving) return;

    final deleteTasksWhenConvertingToSimple = await _resolveChecklistConversion();
    if (deleteTasksWhenConvertingToSimple == null) return;

    _clampXpField(silent: true);
    setState(() => _saving = true);

    final input = CreateMissionInput(
      title: _titleController.text,
      description: _descriptionController.text,
      type: _type,
      difficulty: _difficulty,
      areaId: _areaId,
      attributeIds: _attributeIds,
      xpReward: int.tryParse(_xpController.text.trim()) ?? _currentXpCap,
      isCompound: _isCompound,
      notes: _notesController.text,
    );

    try {
      final mission = widget.mission;
      if (mission == null) {
        await _repository.createMission(input);
      } else {
        await _repository.updateMission(
          missionId: mission.id,
          input: input,
          deleteTasksWhenConvertingToSimple: deleteTasksWhenConvertingToSimple,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editing ? 'Missão atualizada com sucesso.' : 'Missão criada com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editing ? 'Erro ao editar missão: $error' : 'Erro ao criar missão: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  Future<bool?> _resolveChecklistConversion() async {
    final mission = widget.mission;
    if (mission == null || _isCompound) return false;

    final stats = await _repository.getMissionTaskStats(mission.id);
    if (stats.total == 0) return false;

    if (!mounted) return null;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover checklist?'),
        content: Text(
          'Esta missão possui ${stats.total} subtarefa(s). Para convertê-la em missão simples, o checklist será removido permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Remover checklist'),
          ),
        ],
      ),
    );

    return confirm == true ? true : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar missão' : 'Nova missão'),
      ),
      body: FutureBuilder<_MissionFormData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Erro ao carregar formulário',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(snapshot.error.toString(), style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            );
          }

          final data = snapshot.data!;
          final xpCap = data.xpCap;
          final areaValue = data.areas.any((area) => area['id']?.toString() == _areaId) ? _areaId : null;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editing ? 'Ajustar missão' : 'Criar missão',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _editing
                            ? 'Corrija título, descrição, tipo, dificuldade, XP, atributos e modo simples/composto.'
                            : 'Defina uma missão simples ou composta. Missões compostas podem ter checklist no detalhe.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Título da missão',
                    hintText: 'Ex.: Alongar por 10 minutos',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 3) return 'Digite um título com pelo menos 3 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex.: Mobilidade básica para reduzir rigidez.',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _isCompound,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Missão composta com checklist'),
                  subtitle: Text(
                    _editing && data.taskCount > 0
                        ? 'Esta missão possui ${data.taskCount} subtarefa(s). Desligar este modo removerá o checklist ao salvar.'
                        : 'Use para compras, planejamento, organização ou missões com várias etapas.',
                  ),
                  onChanged: (value) => setState(() => _isCompound = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas da missão',
                    hintText: 'Ex.: detalhes, lista-base, observações ou contexto da missão.',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Diária')),
                    DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                    DropdownMenuItem(value: 'monthly', child: Text('Mensal')),
                    DropdownMenuItem(value: 'special', child: Text('Especial')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _type = value);
                    _refreshReward();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _difficulty,
                  decoration: const InputDecoration(labelText: 'Dificuldade'),
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Fácil')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'medium', child: Text('Médio')),
                    DropdownMenuItem(value: 'hard', child: Text('Difícil')),
                    DropdownMenuItem(value: 'very_hard', child: Text('Muito difícil')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _difficulty = value);
                    _refreshReward();
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _xpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'XP da missão',
                    helperText: 'Teto atual: até $xpCap XP (${_difficultyLabel(_difficulty)}).',
                    suffixText: '/ $xpCap',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final xp = int.tryParse(value?.trim() ?? '');
                    if (xp == null || xp <= 0) return 'Digite um XP maior que zero.';
                    if (xp > xpCap) return 'O teto desta dificuldade é $xpCap XP.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: areaValue,
                  decoration: const InputDecoration(labelText: 'Área'),
                  items: data.areas.map((area) {
                    return DropdownMenuItem(
                      value: area['id']?.toString(),
                      child: Text(area['name']?.toString() ?? 'Área'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _areaId = value);
                    _applyAreaAttributes(value);
                  },
                ),
                const SizedBox(height: 12),
                AttributeMultiSelectField(
                  attributes: data.attributes,
                  selectedIds: _attributeIds,
                  title: 'Atributos da missão',
                  subtitle: 'A área sugere até 3 atributos. Você pode trocar e reorganizar a ordem manualmente.',
                  onChanged: (ids) {
                    setState(() {
                      _attributeIds
                        ..clear()
                        ..addAll(ids);
                    });
                  },
                ),
                const SizedBox(height: 16),
                GlCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppTheme.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recompensa configurada', style: TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(
                              '+${_xpController.text.trim().isEmpty ? data.reward.xp : _xpController.text.trim()} XP  •  +${data.reward.coins} coins',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GlPrimaryButton(
                  label: _saving ? 'Salvando...' : (_editing ? 'Salvar missão' : 'Criar missão'),
                  icon: Icons.save_rounded,
                  onPressed: _save,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _difficultyLabel(String difficulty) {
  return switch (difficulty) {
    'easy' => 'Fácil',
    'normal' => 'Normal',
    'medium' => 'Médio',
    'hard' => 'Difícil',
    'very_hard' => 'Muito difícil',
    _ => 'Normal',
  };
}

class _MissionFormData {
  const _MissionFormData({
    required this.areas,
    required this.attributes,
    required this.reward,
    required this.xpCap,
    required this.taskCount,
  });

  final List<Map<String, Object?>> areas;
  final List<Map<String, Object?>> attributes;
  final MissionReward reward;
  final int xpCap;
  final int taskCount;
}
