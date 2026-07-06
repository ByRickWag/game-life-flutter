import 'package:flutter/material.dart';

import '../../core/models/game_models.dart';
import '../../core/repositories/shop_repository.dart';
import '../../design_system/game_design_system.dart';

class ShopItemFormScreen extends StatefulWidget {
  const ShopItemFormScreen({super.key, this.item});

  final ShopItem? item;

  @override
  State<ShopItemFormScreen> createState() => _ShopItemFormScreenState();
}

class _ShopItemFormScreenState extends State<ShopItemFormScreen> {
  final _repository = const ShopRepository();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _coinCostController;
  late final TextEditingController _requiredMoneyController;
  List<VaultWithSummary> _vaults = const [];
  String _type = 'reward';
  String _linkedVaultId = '';
  bool _loadingVaults = true;
  bool _saving = false;

  bool get _isEditing => widget.item != null;
  bool get _isRealPurchase => _type == 'real_purchase';
  String get _selectedVaultValue {
    if (_linkedVaultId.isEmpty) return 'none';
    final exists = _vaults.any((item) => item.vault.id == _linkedVaultId);
    return exists ? _linkedVaultId : 'none';
  }

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _type = item?.type ?? 'reward';
    _linkedVaultId = item?.linkedVaultId ?? '';
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(text: item?.description ?? '');
    _coinCostController = TextEditingController(text: item == null ? '' : item.coinCost.toString());
    _requiredMoneyController = TextEditingController(
      text: item == null || item.requiredMoneyAmount <= 0 ? '' : item.requiredMoneyAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _loadVaults();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _coinCostController.dispose();
    _requiredMoneyController.dispose();
    super.dispose();
  }

  Future<void> _loadVaults() async {
    try {
      final vaults = await _repository.getActiveVaultOptions();
      if (!mounted) return;
      setState(() {
        _vaults = vaults;
        _loadingVaults = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingVaults = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final input = CreateShopItemInput(
      title: _titleController.text,
      description: _descriptionController.text,
      type: _type,
      coinCost: int.tryParse(_coinCostController.text.trim()) ?? 0,
      requiredMoneyAmount: _isRealPurchase ? _parseMoney(_requiredMoneyController.text) : 0,
      linkedVaultId: _isRealPurchase && _linkedVaultId.isNotEmpty ? _linkedVaultId : null,
    );

    try {
      final item = widget.item;
      if (item == null) {
        await _repository.createItem(input);
      } else {
        await _repository.updateItem(itemId: item.id, input: input);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar item da loja: $error')),
      );
    }
  }

  double _parseMoney(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return 0;
    final clean = raw.contains(',') ? raw.replaceAll('.', '').replaceAll(',', '.') : raw;
    return double.tryParse(clean) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar item da loja' : 'Novo item da loja')),
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
                  children: const [
                    Icon(Icons.storefront_rounded, color: GameColors.reward, size: 34),
                    SizedBox(height: GameSpacing.sm),
                    Text('Loja do Reino', style: GameTextStyles.title),
                    SizedBox(height: GameSpacing.xs),
                    Text(
                      'Crie recompensas compradas com coins ou compras reais planejadas que exigem cofre vinculado.',
                      style: GameTextStyles.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GameSpacing.md),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Título do item',
                  hintText: 'Ex.: 2h de jogatina, GamePad, livro...',
                  prefixIcon: Icon(Icons.label_rounded),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return 'Informe um título.';
                  return null;
                },
              ),
              const SizedBox(height: GameSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo de item',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'reward', child: Text('Recompensa simples')),
                  DropdownMenuItem(value: 'real_purchase', child: Text('Compra real planejada')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _type = value;
                    if (!_isRealPurchase) _linkedVaultId = '';
                  });
                },
              ),
              const SizedBox(height: GameSpacing.sm),
              TextFormField(
                controller: _coinCostController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Custo em coins',
                  hintText: 'Ex.: 80',
                  prefixIcon: Icon(Icons.monetization_on_rounded),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Informe um número inteiro.';
                  if (parsed < 0) return 'O custo não pode ser negativo.';
                  return null;
                },
              ),
              if (_isRealPurchase) ...[
                const SizedBox(height: GameSpacing.sm),
                TextFormField(
                  controller: _requiredMoneyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Valor real necessário',
                    hintText: 'Ex.: 150,00',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                  validator: (value) {
                    final parsed = _parseMoney(value ?? '');
                    if (parsed < 0) return 'O valor não pode ser negativo.';
                    if (parsed > 0 && _linkedVaultId.isEmpty) return 'Vincule um cofre para esse valor.';
                    return null;
                  },
                ),
                const SizedBox(height: GameSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _selectedVaultValue,
                  decoration: const InputDecoration(
                    labelText: 'Cofre vinculado',
                    prefixIcon: Icon(Icons.savings_rounded),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: 'none', child: Text('Nenhum cofre')),
                    for (final item in _vaults)
                      DropdownMenuItem<String>(
                        value: item.vault.id,
                        child: Text('${item.vault.name} • ${formatCurrency(item.summary.balance)}'),
                      ),
                  ],
                  onChanged: _loadingVaults ? null : (value) => setState(() => _linkedVaultId = value == 'none' ? '' : value ?? ''),
                ),
                const SizedBox(height: GameSpacing.xs),
                Text(
                  _vaults.isEmpty
                      ? 'Crie um Cofre do Reino antes de usar compra real com dinheiro guardado.'
                      : 'A compra real só será liberada quando o cofre tiver saldo suficiente.',
                  style: GameTextStyles.caption,
                ),
              ],
              const SizedBox(height: GameSpacing.sm),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descrição opcional',
                  hintText: 'Explique a regra dessa recompensa ou compra.',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: GameSpacing.lg),
              GamePrimaryButton(
                label: _saving ? 'Salvando...' : 'Salvar item',
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
