// SPDX-AI-Disclosure: none

import 'dart:ui' show Size;

import 'package:ignis/src/math.dart';

extension SizeToVector2 on Size {
  /// This size as a [Vector2].
  Vector2 toVector2() => Vector2(width, height);
}
