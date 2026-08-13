import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Oscillates as a sine wave between -1 and 1, completing one full cycle as
/// `t` runs from 0 to 1.
class SineCurve extends Curve {
  const SineCurve();

  @override
  double transform(double t) => math.sin(2 * math.pi * t);
}
