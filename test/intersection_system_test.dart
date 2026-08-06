import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  final system = StandardIntersectionSystem();

  group('circle-circle', () {
    test('intersects when overlapping', () {
      final a = Aabb2.centerAndHalfExtents(.zero(), .all(4));
      final b = Aabb2.centerAndHalfExtents(.new(6, 0), .all(4));

      expect(system.circleCircle(a, b), isTrue);
    });

    test('does not intersect when apart', () {
      final a = Aabb2.centerAndHalfExtents(.zero(), .all(2));
      final b = Aabb2.centerAndHalfExtents(.new(10, 0), .all(2));

      expect(system.circleCircle(a, b), isFalse);
    });

    test('touching edges count as intersecting', () {
      final a = Aabb2.centerAndHalfExtents(.zero(), .all(2));
      final b = Aabb2.centerAndHalfExtents(.new(5, 0), .all(3));

      expect(system.circleCircle(a, b), isTrue);
    });
  });

  group('rectangle-rectangle', () {
    test('intersects when overlapping', () {
      final a = Aabb2.centerAndHalfExtents(.zero(), .all(2));
      final b = Aabb2.centerAndHalfExtents(.new(3, 0), .all(2));

      expect(system.rectangleRectangle(a, b), isTrue);
    });

    test('does not intersect when apart', () {
      final a = Aabb2.centerAndHalfExtents(.zero(), .all(1));
      final b = Aabb2.centerAndHalfExtents(.new(10, 0), .all(1));

      expect(system.rectangleRectangle(a, b), isFalse);
    });

    test('touching edges count as intersecting', () {
      final a = Aabb2.centerAndHalfExtents(.zero(), .all(2));
      final b = Aabb2.centerAndHalfExtents(.new(4, 0), .all(2));

      expect(system.rectangleRectangle(a, b), isTrue);
    });
  });

  group('circle-rectangle', () {
    test('intersects when the circle overlaps the rectangle', () {
      final circle = Aabb2.centerAndHalfExtents(.new(4, 0), .all(2));
      final rectangle = Aabb2.centerAndHalfExtents(.zero(), .all(2));

      expect(system.circleRectangle(circle, rectangle), isTrue);
    });

    test('does not intersect when the circle does not overlap the rectangle', () {
      final circle = Aabb2.centerAndHalfExtents(.new(10, 0), .all(1));
      final rectangle = Aabb2.centerAndHalfExtents(.zero(), .all(2));

      expect(system.circleRectangle(circle, rectangle), isFalse);
    });

    // TODO: Tangent test.
  });

  group('rectangle-point', () {
    test('intersects when the point lies within the rectangle', () {
      final rect = Aabb2.centerAndHalfExtents(.zero(), .all(2));

      expect(system.rectanglePoint(rect, .all(1)), isTrue);
    });

    test('does not intersect when the point lies outside the rectangle', () {
      final rect = Aabb2.centerAndHalfExtents(.zero(), .all(2));

      expect(system.rectanglePoint(rect, .all(5)), isFalse);
    });

    test('touching an edge counts as intersecting', () {
      final rect = Aabb2.centerAndHalfExtents(.zero(), .all(2));

      expect(system.rectanglePoint(rect, .new(2, 0)), isTrue);
    });
  });

  group('circle-point', () {
    test('intersects when the point lies within the circle', () {
      final circle = Aabb2.centerAndHalfExtents(.zero(), .all(4));

      expect(system.circlePoint(circle, .all(1)), isTrue);
    });

    test('does not intersect when the point lies outside the circle', () {
      final circle = Aabb2.centerAndHalfExtents(.zero(), .all(4));

      // (4, 4) sits in the AABB's corner but outside the inscribed circle.
      expect(system.circlePoint(circle, .all(4)), isFalse);
    });

    test('touching the edge counts as intersecting', () {
      final circle = Aabb2.centerAndHalfExtents(.zero(), .all(4));

      expect(system.circlePoint(circle, .new(4, 0)), isTrue);
    });
  });
}
