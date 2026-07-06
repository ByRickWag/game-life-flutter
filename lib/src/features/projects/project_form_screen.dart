import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/repositories/project_repository.dart';
import '../../core/services/area_attribute_suggestion_service.dart';
import '../../core/services/reward_service.dart';
import '../../shared/widgets/gl_card.dart';
import '../../shared/widgets/gl_primary_button.dart';
import '../../shared/widgets/attribute_multi_select_field.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final ProjectRepository _repository = ProjectRepository();
  final AreaAttributeSuggestionService _areaSuggestionService = AreaAttributeSuggestionService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late Future<_ProjectFormData> _future;

  String _difficulty = 'normal';
  String? _areaId;
  final List<String> _attributeIds = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<_ProjectFormData> _load() async {
    final areas = await _areaSuggestionService.loadActiveAreas();
    final attributes = await _repository.getAttributes();
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

    return _ProjectFormData(
      areas: areas,
      attributes: attributes,
      reward: reward,
    );
  }

  void _refreshReward() {
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

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _saving) return;

    setState(() => _saving = true);

    try {
      await _repository.createProject(
        CreateProjectInput(
          title: _titleController.text,
          description: _descriptionController.text,
          areaId: _areaId,
          attributeIds: _attributeIds,
          difficulty: _difficulty,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Projeto criado com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar projeto: $error'),
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
        title: const Text('Novo projeto'),
      ),
      body: FutureBuilder<_ProjectFormData>(
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          final data = snapshot.data!;
          final areaValue = data.areas.any((area) => area['id']?.toString() == _areaId)
              ? _areaId
              : null;

          return Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              children: [
                GlCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Criar projeto estruturado',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Projetos agora funcionam em marcos e tarefas. As tarefas dão XP pequeno durante o caminho; a recompensa final vem só na conclusão do projeto.',
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
                    labelText: 'Título do projeto',
                    hintText: 'Ex.: Organizar estudos de programação',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 3) {
                      return 'Digite um título com pelo menos 3 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Ex.: Fechar a primeira versão usável do app.',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _difficulty,
                  decoration: const InputDecoration(labelText: 'Dificuldade'),
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Fácil')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'hard', child: Text('Difícil')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _difficulty = value);
                    _refreshReward();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: areaValue,
                  decoration: const InputDecoration(labelText: 'Área principal'),
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
                  title: 'Atributos do projeto',
                  subtitle: 'A área sugere até 3 atributos ligados ao projeto. Você pode ajustar a ordem.',
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
                      const Icon(Icons.folder_special_rounded, color: AppTheme.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recompensa final do projeto',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+${data.reward.xp} XP • +${data.reward.coins} coins',
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
                  label: _saving ? 'Salvando...' : 'Criar projeto estruturado',
                  icon: Icons.save_rounded,
                  onPressed: _saving ? () {} : _save,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProjectFormData {
  const _ProjectFormData({
    required this.areas,
    required this.attributes,
    required this.reward,
  });

  final List<Map<String, Object?>> areas;
  final List<Map<String, Object?>> attributes;
  final ProjectReward reward;
}
