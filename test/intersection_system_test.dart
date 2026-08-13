import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

/// An axis-aligned rectangle's half-extent vectors, given a rotation.
(Vector2, Vector2) axes(double angle) => (
  Vector2(math.cos(angle), math.sin(angle)),
  Vector2(-math.sin(angle), math.cos(angle)),
);

void main() {
  final system = StandardIntersectionSystem();

  group('circle-circle', () {
    test('intersects when overlapping', () {
      expect(system.circleCircle(.zero(), 4, .new(6, 0), 4), isTrue);
    });

    test('does not intersect when apart', () {
      expect(system.circleCircle(.zero(), 2, .new(10, 0), 2), isFalse);
    });

    test('touching edges count as intersecting', () {
      expect(system.circleCircle(.zero(), 2, .new(5, 0), 3), isTrue);
    });
  });

  group('rectangle-rectangle', () {
    test('intersects when overlapping', () {
      expect(
        system.rectangleRectangle(
          .zero(),
          .new(2, 0),
          .new(0, 2),
          .new(3, 0),
          .new(2, 0),
          .new(0, 2),
        ),
        isTrue,
      );
    });

    test('does not intersect when apart', () {
      expect(
        system.rectangleRectangle(
          .zero(),
          .new(1, 0),
          .new(0, 1),
          .new(10, 0),
          .new(1, 0),
          .new(0, 1),
        ),
        isFalse,
      );
    });

    test('touching edges count as intersecting', () {
      expect(
        system.rectangleRectangle(
          .zero(),
          .new(2, 0),
          .new(0, 2),
          .new(4, 0),
          .new(2, 0),
          .new(0, 2),
        ),
        isTrue,
      );
    });

    test('excludes a rotated rectangle from a point its AABB would include', () {
      // A 10x10 square rotated 45 degrees, centered on the origin, has an
      // AABB corner at roughly (7.07, 7.07) but doesn't actually reach it.
      final (diamondEx, diamondEy) = axes(math.pi / 4);
      final diamondEx5 = diamondEx * 5;
      final diamondEy5 = diamondEy * 5;
      final probeEx = Vector2(1, 0); // A tiny (2x2) axis-aligned probe rectangle.
      final probeEy = Vector2(0, 1);

      // Inside the AABB, outside the diamond.
      expect(
        system.rectangleRectangle(.zero(), diamondEx5, diamondEy5, .all(6), probeEx, probeEy),
        isFalse,
      );

      // Inside both.
      expect(
        system.rectangleRectangle(.zero(), diamondEx5, diamondEy5, .all(3), probeEx, probeEy),
        isTrue,
      );
    });
  });

  group('circle-rectangle', () {
    test('intersects when the circle overlaps the rectangle', () {
      final (ex, ey) = axes(0);
      expect(system.circleRectangle(.new(4, 0), 2, .zero(), ex * 2, ey * 2), isTrue);
    });

    test('does not intersect when the circle does not overlap the rectangle', () {
      final (ex, ey) = axes(0);
      expect(system.circleRectangle(.new(10, 0), 1, .zero(), ex * 2, ey * 2), isFalse);
    });

    test("accounts for the rectangle's rotation", () {
      // A 10x10 square rotated 45 degrees, centered on the origin, has an
      // AABB corner at roughly (7.07, 7.07) but doesn't actually reach it.
      final (ex, ey) = axes(math.pi / 4);
      expect(system.circleRectangle(.all(6), 1, .zero(), ex * 5, ey * 5), isFalse);
    });
  });
}
