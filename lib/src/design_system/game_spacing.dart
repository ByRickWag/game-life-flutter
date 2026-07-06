import 'package:flutter/material.dart';

abstract final class GameSpacing {
  const GameSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets screen = EdgeInsets.all(md);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets cardLarge = EdgeInsets.all(lg);
  static const EdgeInsets chip = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const EdgeInsets button = EdgeInsets.symmetric(horizontal: 18, vertical: 14);
}
