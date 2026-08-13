import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

/// A transform matching [TransformNode.localTransform]'s construction, so
/// these tests exercise the same shape a real collider ever sees.
Matrix3 transform({
  Vector2? position,
  Vector2? scale,
  double angle = 0,
}) {
  position ??= .zero();
  scale ??= .all(1);
  final cosA = math.cos(angle);
  final sinA = math.sin(angle);

  return Matrix3(
    cosA * scale.x,
    sinA * scale.x,
    0,
    -sinA * scale.y,
    cosA * scale.y,
    0,
    position.x,
    position.y,
    1,
  );
}

void main() {
  group('Rectangle.worldExtents', () {
    test('half-extents point along the local axes, unrotated', () {
      final shape = Rectangle(.new(20, 10));
      final Vector2 ex = .zero();
      final Vector2 ey = .zero();

      shape.worldExtents(transform(), ex.mutate(), ey.mutate());

      expect(ex, Vector2(10, 0));
      expect(ey, Vector2(0, 5));
    });

    test('rotates with the transform', () {
      final shape = Rectangle(.new(20, 10));
      final Vector2 ex = .zero();
      final Vector2 ey = .zero();

      shape.worldExtents(transform(angle: math.pi / 2), ex.mutate(), ey.mutate());

      expect(ex.x, closeTo(0, 1e-9));
      expect(ex.y, closeTo(10, 1e-9));
      expect(ey.x, closeTo(-5, 1e-9));
      expect(ey.y, closeTo(0, 1e-9));
    });

    test('ignores translation - extents are directions, not points', () {
      final shape = Rectangle(.new(20, 10));
      final Vector2 ex = .zero();
      final Vector2 ey = .zero();

      shape.worldExtents(transform(position: .all(100)), ex.mutate(), ey.mutate());

      expect(ex, Vector2(10, 0));
      expect(ey, Vector2(0, 5));
    });

    test('scales with the transform', () {
      final shape = Rectangle.square(10);
      final Vector2 ex = .zero();
      final Vector2 ey = .zero();

      shape.worldExtents(transform(scale: .new(2, 3)), ex.mutate(), ey.mutate());

      expect(ex, Vector2(10, 0));
      expect(ey, Vector2(0, 15));
    });
  });

  group('Circle.worldRadius', () {
    test('unaffected by rotation or translation', () {
      final shape = Circle(5);
      final radius = shape.worldRadius(transform(angle: math.pi / 3, position: .all(50)));
      expect(radius, closeTo(5, 1e-9));
    });

    test("scales with the transform's X-axis scale factor", () {
      final shape = Circle(5);
      expect(shape.worldRadius(transform(scale: .new(2, 4))), closeTo(10, 1e-9));
    });
  });
}
