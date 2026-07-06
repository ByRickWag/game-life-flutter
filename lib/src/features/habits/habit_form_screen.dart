import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/habit_repository.dart';
import '../../core/services/area_attribute_suggestion_service.dart';
import '../../design_system/game_design_system.dart';
import '../../shared/widgets/attribute_multi_select_field.dart';

class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({super.key, this.habit});

  final Habit? habit;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = HabitRepository();
  final _areaSuggestionService = AreaAttributeSuggestionService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController(text: '1');
  final _limitController = TextEditingController(text: '0');
  final _xpController = TextEditingController(text: '8');
  final _coinsController = TextEditingController(text: '0');

  List<Map<String, Object?>> _areas = const [];
  List<Map<String, Object?>> _attributes = const [];
  List<String> _selectedAttributeIds = const [];
  String? _areaId;
  String _type = 'build';
  String _frequency = 'daily';
  String _unit = 'check';
  bool _loading = true;
  bool _saving = false;
  Object? _error;

  bool get _editing => widget.habit != null;
  bool get _isReduction => _type == 'reduce' || _type == 'avoid';

  @override
  void initState() {
    super.initState();
    _hydrateFromHabit();
    _loadOptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _limitController.dispose();
    _xpController.dispose();
    _coinsController.dispose();
    super.dispose();
  }

  void _hydrateFromHabit() {
    final habit = widget.habit;
    if (habit == null) return;

    _titleController.text = habit.title;
    _descriptionController.text = habit.description;
    _targetController.text = formatNumber(habit.targetValue);
    _limitController.text = formatNumber(habit.limitValue);
    _xpController.text = habit.xpReward.toString();
    _coinsController.text = habit.coinsReward.toString();
    _areaId = habit.areaId;
    _type = habit.type;
    _frequency = habit.frequency;
    _unit = habit.unit;
  }

  Future<void> _loadOptions() async {
    try {
      final areas = await _areaSuggestionService.loadActiveAreas();
      final attributes = await _repository.getAttributes();
      var selected = widget.habit == null
          ? <String>[]
          : await _repository.getAttributeIdsForHabit(widget.habit!.id);
      _areaId ??= areas.isNotEmpty ? areas.first['id']?.toString() : null;
      if (selected.isEmpty) {
        selected = await _areaSuggestionService.suggestAttributeIds(_areaId);
      }
      if (selected.isEmpty && attributes.isNotEmpty) {
        final firstAttributeId = attributes.first['id']?.toString();
        if (firstAttributeId != null && firstAttributeId.isNotEmpty) {
          selected = [firstAttributeId];
        }
      }
      if (!mounted) return;
      setState(() {
        _areas = areas;
        _attributes = attributes;
        _selectedAttributeIds = selected;
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

  Future<void> _applyAreaAttributes(String? areaId) async {
    final suggestedAttributeIds = await _areaSuggestionService.suggestAttributeIds(areaId);
    if (!mounted || suggestedAttributeIds.isEmpty) return;

    setState(() {
      _selectedAttributeIds = suggestedAttributeIds;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final input = CreateHabitInput(
      title: _titleController.text,
      description: _descriptionController.text,
      type: _type,
      frequency: _frequency,
      unit: _unit,
      targetValue: _readDouble(_targetController.text, fallback: 1),
      limitValue: _type == 'avoid' ? 0 : _readDouble(_limitController.text, fallback: 0),
      areaId: _areaId,
      attributeIds: _selectedAttributeIds,
      xpReward: _readInt(_xpController.text, fallback: 8),
      coinsReward: _readInt(_coinsController.text, fallback: 0),
    );

    try {
      final habit = widget.habit;
      if (habit == null) {
        await _repository.createHabit(input);
      } else {
        await _repository.updateHabit(habitId: habit.id, input: input);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar hábito: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_editing ? 'Editar hábito' : 'Novo hábito')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_editing ? 'Editar hábito' : 'Novo hábito')),
        body: Center(child: Text('Erro ao carregar opções: $_error')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Editar hábito' : 'Novo hábito')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: GameSpacing.screen,
            children: [
              GameHighlightCard(
                accentColor: GameColors.success,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.repeat_rounded, color: GameColors.success, size: 34),
                    const SizedBox(height: GameSpacing.sm),
                    Text(_editing ? 'Ajustar hábito' : 'Criar hábito', style: GameTextStyles.title),
                    const SizedBox(height: GameSpacing.xs),
                    const Text(
                      'Use hábitos para construir constância ou reduzir comportamentos aos poucos, sem modo kamikaze.',
                      style: GameTextStyles.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GameSpacing.md),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nome do hábito',
                  prefixIcon: Icon(Icons.edit_rounded),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => (value ?? '').trim().isEmpty ? 'Informe o nome do hábito.' : null,
              ),
              const SizedBox(height: GameSpacing.sm),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição / intenção',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: GameSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo de hábito',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'build', child: Text('Construir')),
                  DropdownMenuItem(value: 'maintain', child: Text('Manter')),
                  DropdownMenuItem(value: 'reduce', child: Text('Reduzir')),
                  DropdownMenuItem(value: 'avoid', child: Text('Evitar')),
                ],
                onChanged: _saving ? null : (value) => setState(() => _type = value ?? 'build'),
              ),
              const SizedBox(height: GameSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequência',
                        prefixIcon: Icon(Icons.calendar_month_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Diário')),
                        DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                      ],
                      onChanged: _saving ? null : (value) => setState(() => _frequency = value ?? 'daily'),
                    ),
                  ),
                  const SizedBox(width: GameSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Unidade',
                        prefixIcon: Icon(Icons.straighten_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'check', child: Text('check')),
                        DropdownMenuItem(value: 'times', child: Text('vezes')),
                        DropdownMenuItem(value: 'ml', child: Text('ml')),
                        DropdownMenuItem(value: 'minutes', child: Text('minutos')),
                        DropdownMenuItem(value: 'pages', child: Text('páginas')),
                        DropdownMenuItem(value: 'reps', child: Text('repetições')),
                      ],
                      onChanged: _saving ? null : (value) => setState(() => _unit = value ?? 'check'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GameSpacing.sm),
              if (_isReduction)
                TextFormField(
                  controller: _limitController,
                  enabled: _type != 'avoid',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _type == 'avoid' ? 'Limite' : 'Limite por período',
                    helperText: _type == 'avoid' ? 'Evitar usa limite zero automaticamente.' : 'Ex.: refrigerante até 4 vezes por semana.',
                    prefixIcon: const Icon(Icons.speed_rounded),
                  ),
                  validator: (value) {
                    if (_type == 'avoid') return null;
                    final parsed = _readDouble(value ?? '', fallback: -1);
                    if (parsed < 0) return 'Informe um limite válido.';
                    return null;
                  },
                )
              else
                TextFormField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Meta por período',
                    helperText: 'Ex.: 1000 ml, 10 minutos, 1 check.',
                    prefixIcon: Icon(Icons.track_changes_rounded),
                  ),
                  validator: (value) {
                    final parsed = _readDouble(value ?? '', fallback: 0);
                    if (parsed <= 0) return 'A meta precisa ser maior que zero.';
                    return null;
                  },
                ),
              const SizedBox(height: GameSpacing.sm),
              DropdownButtonFormField<String?>(
                initialValue: _areaId,
                decoration: const InputDecoration(
                  labelText: 'Área',
                  prefixIcon: Icon(Icons.dashboard_customize_rounded),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Sem área')),
                  for (final area in _areas)
                    DropdownMenuItem<String?>(
                      value: area['id']?.toString(),
                      child: Text(area['name']?.toString() ?? 'Área'),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() => _areaId = value);
                        _applyAreaAttributes(value);
                      },
              ),
              const SizedBox(height: GameSpacing.sm),
              AttributeMultiSelectField(
                attributes: _attributes,
                selectedIds: _selectedAttributeIds,
                onChanged: _saving ? (_) {} : (ids) => setState(() => _selectedAttributeIds = ids),
                title: 'Atributos do hábito',
                subtitle: 'A área sugere até 3 atributos. Eles recebem XP quando o hábito gera recompensa.',
              ),
              const SizedBox(height: GameSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _xpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'XP',
                        prefixIcon: Icon(Icons.bolt_rounded),
                        helperText: '0 a 50',
                      ),
                      validator: (value) {
                        final parsed = _readInt(value ?? '', fallback: -1);
                        if (parsed < 0 || parsed > 50) return 'Use 0 a 50.';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: GameSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _coinsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Coins',
                        prefixIcon: Icon(Icons.monetization_on_rounded),
                        helperText: '0 a 20',
                      ),
                      validator: (value) {
                        final parsed = _readInt(value ?? '', fallback: -1);
                        if (parsed < 0 || parsed > 20) return 'Use 0 a 20.';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GameSpacing.md),
              GamePrimaryButton(
                label: _saving ? 'Salvando...' : _editing ? 'Salvar alterações' : 'Criar hábito',
                icon: Icons.save_rounded,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: GameSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  double _readDouble(String value, {required double fallback}) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
  }

  int _readInt(String value, {required int fallback}) {
    return int.tryParse(value.trim()) ?? fallback;
  }
}
