import 'package:flutter/material.dart';

import '../../core/app_version.dart';
import '../../design_system/game_design_system.dart';

class AboutV1Screen extends StatelessWidget {
  const AboutV1Screen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: SingleChildScrollView(
        padding: GameSpacing.screen,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameHighlightCard(
              accentColor: GameColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: GameColors.rewardSoft,
                    size: 36,
                  ),
                  SizedBox(height: GameSpacing.sm),
                  Text('Game Life', style: GameTextStyles.title),
                  SizedBox(height: GameSpacing.xs),
                  Text(
                    'Release Premium local-first para iniciar a campanha Transformação 20–25 com capítulos mais claros, áreas inteligentes e evolução visível.',
                    style: GameTextStyles.body,
                  ),
                ],
              ),
            ),
            SizedBox(height: GameSpacing.md),
            _VersionCard(),
            SizedBox(height: GameSpacing.md),
            _AboutSection(
              title: 'Base estável',
              icon: Icons.verified_rounded,
              color: GameColors.success,
              items: [
                'Missões, hábitos, saúde, objetivos, sessões, projetos, cofre, loja, XP, coins, atributos, áreas e histórico continuam locais.',
                'O app funciona sem login, sem Firebase e sem sincronização em nuvem.',
                'Os dados ficam salvos no aparelho usando SQLite local.',
                'Onboarding, campanha, dificuldade, hábitos, saúde, cofre, loja e capítulos formam a base de uso diário.',
              ],
            ),
            SizedBox(height: GameSpacing.md),
            _AboutSection(
              title: 'Recursos principais',
              icon: Icons.auto_awesome_rounded,
              color: GameColors.primary,
              items: [
                'Dashboard com resumo da jornada e visual premium.',
                'Jornada com missões, hábitos, saúde, objetivos e campanha.',
                'Campanha com leitura narrativa por capítulos e sinais reais.',
                'Evolução com herói, atributos, áreas, conquistas e relatório.',
                'Finanças com Cofre do Reino e Loja V1.',
              ],
            ),
            SizedBox(height: GameSpacing.md),
            _AboutSection(
              title: 'Fora do escopo atual',
              icon: Icons.lock_outline_rounded,
              color: GameColors.textMuted,
              items: [
                'Pixel art completa e personagem animado.',
                'Login, Firebase, sincronização em nuvem ou backend.',
                'Calendário completo, loja avançada e sistemas online.',
                'Inventário cosmético complexo, bosses ou sistemas narrativos pesados.',
              ],
            ),
            SizedBox(height: GameSpacing.md),
            _AboutSection(
              title: 'Uso recomendado',
              icon: Icons.rocket_launch_rounded,
              color: GameColors.reward,
              items: [
                'Use o app diariamente para registrar esforço real, água e limites alimentares.',
                'Acompanhe missões, objetivos, sessões e projetos pelo Dashboard.',
                'Use a campanha para enxergar o capítulo atual da sua jornada.',
                'Ajuste dificuldade, presets e balanceamento em Configurações quando necessário.',
              ],
            ),
            SizedBox(height: GameSpacing.lg),
          ],
        ),
      ),
    );

    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: content,
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard();

  @override
  Widget build(BuildContext context) {
    return GameCard(
      padding: const EdgeInsets.all(GameSpacing.md),
      backgroundColor: GameColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: GameColors.info),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: Text(
                  'Informações da versão',
                  style: GameTextStyles.cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          const Wrap(
            spacing: GameSpacing.xs,
            runSpacing: GameSpacing.xs,
            children: [
              GameChip(
                label: AppVersion.display,
                icon: Icons.new_releases_rounded,
                color: GameColors.primary,
                selected: true,
              ),
              GameChip(
                label: 'Capítulos V1',
                icon: Icons.auto_stories_rounded,
                color: GameColors.faith,
                selected: true,
              ),
              GameChip(
                label: 'Local-first',
                icon: Icons.storage_rounded,
                color: GameColors.info,
                selected: true,
              ),
              GameChip(
                label: 'Offline',
                icon: Icons.cloud_off_rounded,
                color: GameColors.success,
                selected: true,
              ),
              GameChip(
                label: 'Android',
                icon: Icons.android_rounded,
                color: GameColors.reward,
                selected: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(child: Text(title, style: GameTextStyles.cardTitle)),
            ],
          ),
          const SizedBox(height: GameSpacing.sm),
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: GameSpacing.sm),
                Expanded(child: Text(item, style: GameTextStyles.body)),
              ],
            ),
            const SizedBox(height: GameSpacing.xs),
          ],
        ],
      ),
    );
  }
}
