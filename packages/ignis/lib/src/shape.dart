// SPDX-AI-Disclosure: ai-assisted

import 'dart:ui';

import 'package:ignis/src/math.dart';

/// The geometry drawn or hit-tested for a node, in its own local space.
sealed class Shape {
  const Shape();

  /// No shape: an empty rectangle.
  static const Shape none = Rectangle(.zero);

  /// This shape's size, if fully contained by an AABB.
  Vector2 get size;

  /// The width of the AABB that fully contains this shape.
  double get width => size.x;

  /// The height of the AABB that fully contains this shape.
  double get height => size.y;

  /// This shape's bounds at the origin.
  Rect rect() => Rect.fromLTWH(0, 0, width, height);

  /// Draws this shape onto [canvas] with [paint].
  void draw(Canvas canvas, Paint paint);

  factory Shape.rectangle(Vector2 size) = Rectangle;
  factory Shape.square(double size) = Rectangle.square;
  factory Shape.circle(double radius) = Circle;
}

final class Rectangle extends Shape {
  @override
  final Vector2 size;

  const Rectangle(this.size);
  Rectangle.square(double size) : this(.all(size));

  @override
  void draw(Canvas canvas, Paint paint) => canvas.drawRect(rect(), paint);
}

final class Circle extends Shape {
  final double radius;

  @override
  final Vector2 size;

  Circle(this.radius) : size = .all(radius * 2);

  @override
  void draw(Canvas canvas, Paint paint) => canvas.drawOval(rect(), paint);
}
