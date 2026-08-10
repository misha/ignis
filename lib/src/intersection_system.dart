import 'package:ignis/src/math.dart';

abstract class IntersectionSystem {
  const IntersectionSystem();

  /// Returns true if two rectangles overlap, given their world-space centers
  /// and, for each, the vectors from its center to the midpoints of its
  /// right ([exA]/[exB]) and bottom ([eyA]/[eyB]) edges.
  bool rectangleRectangle(
    Vector2 centerA,
    Vector2 exA,
    Vector2 eyA,
    Vector2 centerB,
    Vector2 exB,
    Vector2 eyB,
  );

  /// Returns true if a circle at [circleCenter] with [radius] overlaps a
  /// rectangle centered at [rectCenter], described by extents [ex]/[ey].
  bool circleRectangle(
    Vector2 circleCenter,
    double radius,
    Vector2 rectCenter,
    Vector2 ex,
    Vector2 ey,
  );

  /// Returns true if two circles overlap.
  bool circleCircle(Vector2 centerA, double radiusA, Vector2 centerB, double radiusB);
}

final class StandardIntersectionSystem extends IntersectionSystem {
  const StandardIntersectionSystem();

  @override
  bool rectangleRectangle(
    Vector2 centerA,
    Vector2 exA,
    Vector2 eyA,
    Vector2 centerB,
    Vector2 exB,
    Vector2 eyB,
  ) {
    final delta = centerB - centerA;
    if (sat(delta, exA, exA, eyA, exB, eyB)) return false;
    if (sat(delta, eyA, exA, eyA, exB, eyB)) return false;
    if (sat(delta, exB, exA, eyA, exB, eyB)) return false;
    if (sat(delta, eyB, exA, eyA, exB, eyB)) return false;
    return true;
  }

  @override
  bool circleRectangle(
    Vector2 circleCenter,
    double radius,
    Vector2 rectCenter,
    Vector2 ex,
    Vector2 ey,
  ) {
    final delta = circleCenter - rectCenter;
    final u = (delta.dot(ex) / ex.length2).clamp(-1.0, 1.0);
    final v = (delta.dot(ey) / ey.length2).clamp(-1.0, 1.0);
    final closest = rectCenter + ex * u + ey * v;
    return circleCenter.distance2(closest) <= radius * radius;
  }

  @override
  bool circleCircle(
    Vector2 centerA,
    double radiusA,
    Vector2 centerB,
    double radiusB,
  ) {
    final radii = radiusA + radiusB;
    return centerA.distance2(centerB) <= radii * radii;
  }

  /// Returns true if [axis] separates a rectangle described by [exA]/[eyA],
  /// centered [delta] away from a rectangle described by [exB]/[eyB].
  ///
  /// [axis] doesn't need to be normalized: both projections scale by the same
  /// factor, which doesn't affect whether their ranges overlap.
  static bool sat(
    Vector2 delta,
    Vector2 axis,
    Vector2 exA,
    Vector2 eyA,
    Vector2 exB,
    Vector2 eyB,
  ) {
    final distance = delta.dot(axis).abs();
    final radius =
        exA.dot(axis).abs() + //
        eyA.dot(axis).abs() +
        exB.dot(axis).abs() +
        eyB.dot(axis).abs();

    return distance > radius;
  }
}
