import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/vault_repository.dart';
import '../../design_system/game_design_system.dart';

class VaultFormScreen extends StatefulWidget {
  const VaultFormScreen({super.key, this.vault});

  final Vault? vault;

  @override
  State<VaultFormScreen> createState() => _VaultFormScreenState();
}

class _VaultFormScreenState extends State<VaultFormScreen> {
  final _repository = const VaultRepository();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _goalController;
  bool _saving = false;

  bool get _isEditing => widget.vault != null;

  @override
  void initState() {
    super.initState();
    final vault = widget.vault;
    _nameController = TextEditingController(text: vault?.name ?? '');
    _descriptionController = TextEditingController(text: vault?.description ?? '');
    _goalController = TextEditingController(
      text: vault == null || vault.goalAmount <= 0 ? '' : vault.goalAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final input = CreateVaultInput(
      name: _nameController.text,
      description: _descriptionController.text,
      goalAmount: _parseMoney(_goalController.text),
    );

    try {
      final vault = widget.vault;
      if (vault == null) {
        await _repository.createVault(input);
      } else {
        await _repository.updateVault(vaultId: vault.id, input: input);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar cofre: $error')),
      );
    }
  }

  double _parseMoney(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return 0;
    final clean = raw.contains(',')
        ? raw.replaceAll('.', '').replaceAll(',', '.')
        : raw;
    return double.tryParse(clean) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar cofre' : 'Novo cofre')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: GameSpacing.screen,
            children: [
              GameHighlightCard(
                accentColor: GameColors.reward,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.savings_rounded, color: GameColors.reward, size: 34),
                    const SizedBox(height: GameSpacing.sm),
                    Text(_isEditing ? 'Editar Cofre do Reino' : 'Criar Cofre do Reino', style: GameTextStyles.title),
                    const SizedBox(height: GameSpacing.xs),
                    const Text(
                      'Registre dinheiro real guardado fora do app, como caixinhas, reserva, metas de compra ou planos futuros.',
                      style: GameTextStyles.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GameSpacing.md),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome do cofre',
                  hintText: 'Reserva, GamePad, Viagem, Curso...',
                  prefixIcon: Icon(Icons.label_rounded),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Informe um nome.';
                  return null;
                },
              ),
              const SizedBox(height: GameSpacing.sm),
              TextFormField(
                controller: _goalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Meta em reais opcional',
                  hintText: 'Ex.: 150,00',
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
                validator: (value) {
                  final clean = (value ?? '').trim();
                  if (clean.isEmpty) return null;
                  final parsed = _parseMoney(clean);
                  if (parsed < 0) return 'A meta não pode ser negativa.';
                  return null;
                },
              ),
              const SizedBox(height: GameSpacing.sm),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descrição opcional',
                  hintText: 'Pra que esse dinheiro está sendo guardado?',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: GameSpacing.lg),
              GamePrimaryButton(
                label: _saving ? 'Salvando...' : 'Salvar cofre',
                icon: Icons.save_rounded,
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
      ),
    );
  }
}
