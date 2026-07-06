import 'package:flutter/animation.dart';

abstract final class GameMotion {
  const GameMotion._();

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve curve = Curves.easeOutCubic;
  static const Curve entranceCurve = Curves.easeOutQuart;
}
