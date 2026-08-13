import 'package:flutter/rendering.dart' show Axis;
import 'package:ignis/src/math.dart';

extension AxisVector2 on Vector2 {
  /// The component along [axis]: [x] if horizontal, [y] if vertical.
  double axis(Axis axis) => axis == .horizontal ? x : y;
}
