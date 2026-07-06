import 'package:flutter/material.dart';

import '../core/repositories/onboarding_repository.dart';
import '../design_system/game_design_system.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'app_shell.dart';

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  final OnboardingRepository _repository = const OnboardingRepository();

  bool _loading = true;
  bool _completed = false;
  Object? _error;

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
      final completed = await _repository.isCompleted();
      if (!mounted) return;
      setState(() {
        _completed = completed;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: GameSpacing.screen,
            child: GameEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Erro ao iniciar o Game Life',
              message: _error.toString(),
              actionLabel: 'Tentar novamente',
              onAction: _load,
            ),
          ),
        ),
      );
    }

    if (!_completed) {
      return OnboardingScreen(onCompleted: _load);
    }

    return const AppShell();
  }
}
