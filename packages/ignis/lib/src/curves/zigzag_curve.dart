// SPDX-AI-Disclosure: none

import 'package:flutter/animation.dart';

/// Oscillates as a triangle wave between -1 and 1, completing one full cycle
/// as `t` runs from 0 to 1.
class ZigzagCurve extends Curve {
  const ZigzagCurve();

  @override
  double transform(double t) {
    final x = 4 * t;

    return switch (x) {
      <= 1 => x,
      >= 3 => x - 4,
      _ => 2 - x,
    };
  }
}
