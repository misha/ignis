import 'dart:math' as math;
import 'dart:ui';

import 'package:ignis/src/math.dart';

/// The geometry drawn or hit-tested for a node, in its own local space.
sealed class Shape {
  const Shape();

  /// The width of the axis-aligned box that fully contains this shape.
  double get width;

  /// The height of the axis-aligned box that fully contains this shape.
  double get height;

  /// This shape's [width]/[height], as a [Rect] with (0, 0) at its top-left
  /// corner.
  Rect rect() => Rect.fromLTWH(0, 0, width, height);

  factory Shape.rectangle(Vector2 size) = Rectangle;
  factory Shape.square(double size) = Rectangle.square;
  factory Shape.circle(double radius) = Circle;
}

final class Rectangle extends Shape {
  final Vector2 size;

  const Rectangle(this.size);
  Rectangle.square(double size) : this(.all(size));

  @override
  double get width => size.x;

  @override
  double get height => size.y;

  /// Computes this rectangle's world-space half-extents under [transform].
  void worldExtents(Matrix3 transform, MutableVector2 ex, MutableVector2 ey) {
    ex.setValues(transform[0] * size.x / 2, transform[1] * size.x / 2);
    ey.setValues(transform[3] * size.y / 2, transform[4] * size.y / 2);
  }
}

final class Circle extends Shape {
  final double radius;

  const Circle(this.radius);

  @override
  double get width => radius * 2;

  @override
  double get height => radius * 2;

  /// Computes this circle's world-space radius under [transform].
  double worldRadius(Matrix3 transform) {
    final scaleX = math.sqrt(transform[0] * transform[0] + transform[1] * transform[1]);
    return radius * scaleX;
  }
}
