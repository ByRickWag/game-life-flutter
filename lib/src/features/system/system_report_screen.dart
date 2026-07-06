import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/repositories/system_repository.dart';
import '../../design_system/game_design_system.dart';

class SystemReportScreen extends StatefulWidget {
  const SystemReportScreen({super.key});

  @override
  State<SystemReportScreen> createState() => _SystemReportScreenState();
}

class _SystemReportScreenState extends State<SystemReportScreen> {
  final SystemRepository _repository = const SystemRepository();

  String _report = '';
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final report = await _repository.buildTextReport();
      if (!mounted) return;
      setState(() {
        _report = report;
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

  Future<void> _copyReport() async {
    if (_report.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _report));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Relatório copiado.'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório técnico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Copiar',
            onPressed: _loading ? null : _copyReport,
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Padding(
        padding: GameSpacing.screen,
        child: GameEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Erro ao gerar relatório',
          message: _error.toString(),
          actionLabel: 'Tentar novamente',
          onAction: _load,
        ),
      );
    }

    return SingleChildScrollView(
      padding: GameSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameHighlightCard(
            accentColor: GameColors.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.description_rounded, color: GameColors.info, size: 34),
                const SizedBox(height: GameSpacing.sm),
                Text('Relatório técnico', style: GameTextStyles.title),
                const SizedBox(height: GameSpacing.xs),
                Text('Resumo em texto para copiar, salvar ou revisar fora do app.', style: GameTextStyles.body),
              ],
            ),
          ),
          const SizedBox(height: GameSpacing.md),
          GamePrimaryButton(
            label: 'Copiar relatório',
            icon: Icons.copy_rounded,
            onPressed: _copyReport,
          ),
          const SizedBox(height: GameSpacing.md),
          GameCard(
            padding: const EdgeInsets.all(GameSpacing.md),
            backgroundColor: GameColors.surfaceSoft,
            child: SelectableText(
              _report,
              style: GameTextStyles.caption.copyWith(
                height: 1.45,
                color: GameColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: GameSpacing.lg),
        ],
      ),
    );
  }
}
