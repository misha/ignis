// SPDX-AI-Disclosure: none

import 'package:flutter/rendering.dart' show Axis;
import 'package:ignis/src/math.dart';

extension AxisToVector2 on Axis {
  /// A [Vector2] with [main] and [cross] placed along this axis.
  Vector2 toVector2({
    required double main,
    required double cross,
  }) => switch (this) {
    .horizontal => .new(main, cross),
    .vertical => .new(cross, main),
  };
}
