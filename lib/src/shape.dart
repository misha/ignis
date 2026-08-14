import 'dart:math' as math;
import 'dart:ui';

import 'package:ignis/src/math.dart';

/// The geometry drawn or hit-tested for a node, in its own local space.
sealed class Shape {
  const Shape();

  /// This shape's size, if fully contained by an AABB.
  Vector2 get size;

  /// The width of the AABB that fully contains this shape.
  double get width => size.x;

  /// The height of the AABB that fully contains this shape.
  double get height => size.y;

  /// This shape's size, expressed in a canvas-friendly type.
  Rect rect() => Rect.fromLTWH(0, 0, width, height);

  factory Shape.rectangle(Vector2 size) = Rectangle;
  factory Shape.square(double size) = Rectangle.square;
  factory Shape.circle(double radius) = Circle;
}

final class Rectangle extends Shape {
  @override
  final Vector2 size;

  const Rectangle(this.size);
  Rectangle.square(double size) : this(.all(size));

  /// Computes this rectangle's world-space half-extents under [transform].
  void worldExtents(Matrix3 transform, MVector2 ex, MVector2 ey) {
    ex.setValues(transform[0] * size.x / 2, transform[1] * size.x / 2);
    ey.setValues(transform[3] * size.y / 2, transform[4] * size.y / 2);
  }
}

final class Circle extends Shape {
  final double radius;

  @override
  final Vector2 size;

  Circle(this.radius) : size = .all(radius * 2);

  /// Computes this circle's world-space radius under [transform].
  double worldRadius(Matrix3 transform) {
    return radius * math.sqrt(transform[0] * transform[0] + transform[1] * transform[1]);
  }
}
