import 'dart:math';

import 'package:flutter/rendering.dart' show Axis;
import 'package:ignis/src/math.dart';
import 'package:ignis/src/rng.dart';

extension AxisVector2 on Vector2 {
  /// The component along [axis]: [x] if horizontal, [y] if vertical.
  double axis(Axis axis) => axis == .horizontal ? x : y;
}

// TODO: Export this to `ivector_math`.
extension RandomVector2 on Vector2 {
  /// A random vector with both components in `[0, 1)`, from [random] if
  /// given, or [rng] otherwise.
  static Vector2 random([Random? random]) {
    final source = random ?? rng;
    return .new(source.nextDouble(), source.nextDouble());
  }
}
