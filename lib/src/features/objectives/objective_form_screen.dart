import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/repositories/objective_repository.dart';
import '../../core/services/area_attribute_suggestion_service.dart';
import '../../core/services/reward_service.dart';
import '../../shared/widgets/attribute_multi_select_field.dart';
import '../../shared/widgets/gl_card.dart';
import '../../shared/widgets/gl_primary_button.dart';

class ObjectiveFormScreen extends StatefulWidget {
  const ObjectiveFormScreen({super.key});

  @override
  State<ObjectiveFormScreen> createState() => _ObjectiveFormScreenState();
}

class _ObjectiveFormScreenState extends State<ObjectiveFormScreen> {
  final _repository = ObjectiveRepository();
  final _areaSuggestionService = AreaAttributeSuggestionService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  final _xpController = TextEditingController();

  String _difficulty = 'normal';
  String _unit = 'vezes';
  String? _areaId;
  final List<String> _attributeIds = [];
  bool _saving = false;
  int _currentXpCap = 30;

  Future<_ObjectiveFormData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  Future<_ObjectiveFormData> _load() async {
    final areas = await _areaSuggestionService.loadActiveAreas();
    final attributes = await _repository.getAttributes();
    final xpCap = await _repository.getObjectiveXpCap(difficulty: _difficulty);
    _currentXpCap = xpCap;
    final reward = await _repository.previewReward(difficulty: _difficulty);

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

    if (_xpController.text.trim().isEmpty) {
      _xpController.text = reward.xp.toString();
    } else {
      _clampXpField(silent: true);
    }

    return _ObjectiveFormData(
      areas: areas,
      attributes: attributes,
      reward: reward,
      xpCap: xpCap,
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

    final targetValue = _parseDouble(_targetController.text);
    if (targetValue <= 0) return;

    _clampXpField(silent: true);
    setState(() => _saving = true);

    try {
      await _repository.createObjective(
        CreateObjectiveInput(
          title: _titleController.text,
          description: _descriptionController.text,
          areaId: _areaId,
          attributeIds: _attributeIds,
          targetValue: targetValue,
          unit: _unit,
          difficulty: _difficulty,
          xpReward: int.tryParse(_xpController.text.trim()) ?? _currentXpCap,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Objetivo criado com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar objetivo: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo objetivo'),
      ),
      body: FutureBuilder<_ObjectiveFormData>(
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
                        'Criar objetivo mensurável',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Objetivos têm meta numérica e entregam XP/coins quando a meta é concluída. Você escolhe o XP dentro do teto.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Título do objetivo',
                    hintText: 'Ex.: Ler 1 livro',
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
                    hintText: 'Ex.: Ler um livro de desenvolvimento pessoal ou programação.',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Meta numérica',
                    hintText: 'Ex.: 100',
                  ),
                  validator: (value) {
                    final number = _parseDouble(value ?? '');
                    if (number <= 0) return 'Digite uma meta maior que zero.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _unit,
                  decoration: const InputDecoration(labelText: 'Unidade'),
                  items: const [
                    DropdownMenuItem(value: 'vezes', child: Text('vezes')),
                    DropdownMenuItem(value: 'min', child: Text('minutos')),
                    DropdownMenuItem(value: 'horas', child: Text('horas')),
                    DropdownMenuItem(value: 'páginas', child: Text('páginas')),
                    DropdownMenuItem(value: 'dias', child: Text('dias')),
                    DropdownMenuItem(value: 'reais', child: Text('reais')),
                    DropdownMenuItem(value: 'tarefas', child: Text('tarefas')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _unit = value);
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
                    labelText: 'XP do objetivo',
                    helperText: 'Teto atual: até $xpCap XP. Ajuste os tetos em Sistema > Config.',
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
                  title: 'Atributos do objetivo',
                  subtitle: 'A área sugere até 3 atributos ligados à meta. Você pode trocar e reorganizar a ordem.',
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
                      const Icon(Icons.track_changes_rounded, color: AppTheme.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recompensa ao concluir', style: TextStyle(fontWeight: FontWeight.w900)),
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
                  label: _saving ? 'Salvando...' : 'Criar objetivo',
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

class _ObjectiveFormData {
  const _ObjectiveFormData({
    required this.areas,
    required this.attributes,
    required this.reward,
    required this.xpCap,
  });

  final List<Map<String, Object?>> areas;
  final List<Map<String, Object?>> attributes;
  final ObjectiveReward reward;
  final int xpCap;
}
