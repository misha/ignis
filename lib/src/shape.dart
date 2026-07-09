import 'dart:ui';

import 'package:ignis/src/math.dart';

/// The kind of geometry drawn or hit-tested against a node's `size`.
enum Shape {
  /// Uses the node's full `size`, both width and height.
  rectangle,

  /// Uses only the node's `size.x`, for both dimensions, to stay a true
  /// circle rather than an ellipse.
  circle;

  /// This shape's width when scaled to [size].
  double width(Vector2 size) => size.x;

  /// This shape's height when scaled to [size].
  double height(Vector2 size) => switch (this) {
    .circle => size.x,
    .rectangle => size.y,
  };

  /// The rectangle described by this shape when scaled to [size], with (0, 0)
  /// at its top-left corner.
  Rect rect(Vector2 size) => .fromLTWH(0, 0, width(size), height(size));
}
