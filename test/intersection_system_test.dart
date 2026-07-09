import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  final system = StandardIntersectionSystem();

  group('circle-circle', () {
    test('intersects when overlapping', () {
      final a = Aabb2.centerAndHalfExtents(Vector2(0, 0), Vector2(4, 4));
      final b = Aabb2.centerAndHalfExtents(Vector2(6, 0), Vector2(4, 4));

      expect(system.circleCircle(a, b), isTrue);
    });

    test('does not intersect when apart', () {
      final a = Aabb2.centerAndHalfExtents(Vector2(0, 0), Vector2(2, 2));
      final b = Aabb2.centerAndHalfExtents(Vector2(10, 0), Vector2(2, 2));

      expect(system.circleCircle(a, b), isFalse);
    });

    test('touching edges count as intersecting', () {
      final a = Aabb2.centerAndHalfExtents(Vector2(0, 0), Vector2(2, 2));
      final b = Aabb2.centerAndHalfExtents(Vector2(5, 0), Vector2(3, 3));

      expect(system.circleCircle(a, b), isTrue);
    });
  });

  group('rectangle-rectangle', () {
    test('intersects when overlapping', () {
      final a = Aabb2.centerAndHalfExtents(Vector2(0, 0), Vector2(2, 2));
      final b = Aabb2.centerAndHalfExtents(Vector2(3, 0), Vector2(2, 2));

      expect(system.rectangleRectangle(a, b), isTrue);
    });

    test('does not intersect when apart', () {
      final a = Aabb2.centerAndHalfExtents(Vector2(0, 0), Vector2(1, 1));
      final b = Aabb2.centerAndHalfExtents(Vector2(10, 0), Vector2(1, 1));

      expect(system.rectangleRectangle(a, b), isFalse);
    });

    test('touching edges count as intersecting', () {
      final a = Aabb2.centerAndHalfExtents(Vector2(0, 0), Vector2(2, 2));
      final b = Aabb2.centerAndHalfExtents(Vector2(4, 0), Vector2(2, 2));

      expect(system.rectangleRectangle(a, b), isTrue);
    });
  });

  group('circle-rectangle', () {
    test('intersects when the circle overlaps the rectangle', () {
      final circle = Aabb2.centerAndHalfExtents(Vector2(4, 0), Vector2(2, 2));
      final rectangle = Aabb2.centerAndHalfExtents(Vector2(0, 0), Vector2(2, 2));

      expect(system.circleRectangle(circle, rectangle), isTrue);
    });

    test('does not intersect when the circle does not overlap the rectangle', () {
      final circle = Aabb2.centerAndHalfExtents(Vector2(10, 0), Vector2(1, 1));
      final rectangle = Aabb2.centerAndHalfExtents(Vector2(0, 0), Vector2(2, 2));

      expect(system.circleRectangle(circle, rectangle), isFalse);
    });

    // TODO: Tangent test.
  });
}
