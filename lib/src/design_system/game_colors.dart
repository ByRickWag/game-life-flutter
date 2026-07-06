import 'package:flutter/material.dart';

/// Paleta oficial da V2/V4.
///
/// Direção: RPG discreto premium.
/// Fundo escuro profundo, roxo como identidade principal,
/// dourado para recompensas, verde para progresso positivo.
abstract final class GameColors {
  const GameColors._();

  static const Color background = Color(0xFF050711);
  static const Color backgroundAlt = Color(0xFF0A0F1F);
  static const Color backgroundElevated = Color(0xFF0E1426);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceSoft = Color(0xFF172033);
  static const Color surfaceRaised = Color(0xFF1D2740);
  static const Color surfaceOverlay = Color(0xFF24304A);
  static const Color glass = Color(0xB3121829);

  static const Color border = Color(0xFF2D3654);
  static const Color borderSoft = Color(0x22FFFFFF);
  static const Color borderPremium = Color(0x38F8FAFC);

  static const Color primary = Color(0xFF8B5CF6);
  static const Color primarySoft = Color(0xFFA78BFA);
  static const Color primaryDeep = Color(0xFF312E81);
  static const Color primaryGlow = Color(0x668B5CF6);

  static const Color reward = Color(0xFFF59E0B);
  static const Color rewardSoft = Color(0xFFFFC857);
  static const Color rewardDeep = Color(0xFF92400E);
  static const Color coin = Color(0xFFFBBF24);

  static const Color success = Color(0xFF22C55E);
  static const Color successSoft = Color(0xFF86EFAC);
  static const Color warning = Color(0xFFF97316);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF64748B);

  static const Color strength = Color(0xFFEF4444);
  static const Color vigor = Color(0xFF22C55E);
  static const Color clarity = Color(0xFF38BDF8);
  static const Color focus = Color(0xFF8B5CF6);
  static const Color creativity = Color(0xFFEC4899);
  static const Color responsibility = Color(0xFFF59E0B);
  static const Color discipline = Color(0xFF14B8A6);
  static const Color faith = Color(0xFFA78BFA);

  static const LinearGradient appBackgroundGradient = LinearGradient(
    colors: [
      background,
      backgroundAlt,
      background,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient surfaceGradient({Color accent = primary}) {
    return LinearGradient(
      colors: [
        accent.withValues(alpha: 0.10),
        surfaceRaised.withValues(alpha: 0.82),
        surface,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient premiumGradient({Color accent = primary}) {
    return LinearGradient(
      colors: [
        accent.withValues(alpha: 0.32),
        primaryDeep.withValues(alpha: 0.28),
        surfaceRaised,
        surface,
      ],
      stops: const [0.0, 0.34, 0.72, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color attributeById(String? attributeId) {
    return switch (attributeId) {
      'strength' => strength,
      'vigor' => vigor,
      'clarity' => clarity,
      'focus' => focus,
      'creativity' => creativity,
      'responsibility' => responsibility,
      'discipline' => discipline,
      'faith' => faith,
      _ => primary,
    };
  }

  static Color areaById(String? areaId) {
    return switch (areaId) {
      'body_health' => vigor,
      'mind_knowledge' => clarity,
      'spirit_purpose' => faith,
      'projects_career' => primary,
      'creation_expression' => creativity,
      'finance_responsibility' => reward,
      'routine_order' => discipline,
      _ => primary,
    };
  }
}
