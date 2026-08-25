// SPDX-AI-Disclosure: none

import 'dart:ui' show Offset;

import 'package:ignis/src/math.dart';

extension OffsetToVector2 on Offset {
  /// This offset as a [Vector2].
  Vector2 toVector2() => Vector2(dx, dy);
}
