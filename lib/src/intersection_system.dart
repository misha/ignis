import 'package:ignis/src/math.dart';

abstract class IntersectionSystem {
  const IntersectionSystem();

  /// Returns true if [point] lies within the rectangle described by [rect].
  bool rectanglePoint(Aabb2 rect, Vector2 point);

  /// Returns true if [point] lies within the circle described by [circle].
  bool circlePoint(Aabb2 circle, Vector2 point);

  /// Returns true if the AABBs for two rectangles intersect.
  bool rectangleRectangle(Aabb2 a, Aabb2 b);

  /// Returns true if the AABBs for two circles intersect.
  bool circleCircle(Aabb2 a, Aabb2 b);

  /// Returns true if the AABBs for a circle and a rect intersect.
  bool circleRectangle(Aabb2 circle, Aabb2 rect);
}

final class StandardIntersectionSystem extends IntersectionSystem {
  const StandardIntersectionSystem();

  @override
  bool rectanglePoint(Aabb2 rect, Vector2 point) {
    return rect.intersectsWithVector2(point);
  }

  @override
  bool circlePoint(Aabb2 circle, Vector2 point) {
    final dx = point.x - circle.centerX;
    final dy = point.y - circle.centerY;
    final radius = circle.width / 2;
    return dx * dx + dy * dy <= radius * radius;
  }

  @override
  bool rectangleRectangle(Aabb2 a, Aabb2 b) {
    return a.intersectsWithAabb2(b);
  }

  @override
  bool circleCircle(Aabb2 a, Aabb2 b) {
    final dx = (a.min.x + a.max.x) - (b.min.x + b.max.x);
    final dy = (a.min.y + a.max.y) - (b.min.y + b.max.y);
    final diameter = (a.max.x - a.min.x) + (b.max.x - b.min.x);
    return dx * dx + dy * dy <= diameter * diameter;
  }

  @override
  bool circleRectangle(Aabb2 circle, Aabb2 rect) {
    final cx = circle.centerX;
    final cy = circle.centerY;
    final radius = circle.width / 2;
    final closestX = cx.clamp(rect.min.x, rect.max.x);
    final closestY = cy.clamp(rect.min.y, rect.max.y);
    final dx = cx - closestX;
    final dy = cy - closestY;
    return (dx * dx + dy * dy) <= (radius * radius);
  }
}
