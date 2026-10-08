import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  group('holding a shape', () {
    test('is a point by default, even under a shaped parent', () {
      final entity = Entity();
      Scene(
        Entity(
          shape: .square(40),
          children: [entity],
        ),
      );

      expect(entity.size, Vector2.zero);
    });

    test('holds the shape it is given', () {
      final entity = Entity(shape: .rectangle(.new(30, 20)));
      expect(entity.size, Vector2(30, 20));
    });
  });

  group('anchor', () {
    test('covers no area without a size, so it moves nothing', () {
      final entity = Entity(position: .new(10, 20), anchor: .center);

      expect(entity.size, Vector2.zero);
      expect(entity.absolutePosition, Vector2(10, 20));
    });

    test('puts a child at the parent it is anchored inside, not on its position', () {
      final child = Entity();

      Scene(
        Entity(
          shape: .square(40),
          position: .all(100),
          anchor: .center,
          children: [child],
        ),
      );

      // The parent's box spans (80,80)..(120,120), so its corner is (80, 80).
      expect(child.absolutePosition, Vector2(80, 80));
    });

    test('leaves a child alone while the parent is unanchored', () {
      final child = Entity();

      Scene(
        Entity(
          shape: .square(40),
          position: .all(100),
          children: [child],
        ),
      );

      expect(child.absolutePosition, Vector2(100, 100));
    });

    test('carries through the scale and anchor that follow it', () {
      final child = Entity();

      Scene(
        Entity(
          shape: .square(40),
          position: .all(100),
          anchor: .center,
          scale: .all(2),
          children: [child],
        ),
      );

      // The offset is stated in the parent's own space, so the scale doubles it.
      expect(child.absolutePosition, Vector2(60, 60));
    });
  });

  group('pointAt', () {
    test('names a point inside its own box', () {
      final entity = Entity(shape: .rectangle(.new(40, 20)));

      expect(entity.pointAt(.topLeft), Vector2.zero);
      expect(entity.pointAt(.center), Vector2(20, 10));
      expect(entity.pointAt(.bottomRight), Vector2(40, 20));
    });

    test('ignores its own anchor, which the transform already carries', () {
      final entity = Entity(
        shape: .square(40),
        anchor: .center,
      );

      expect(entity.pointAt(.center), Vector2.all(20));
    });

    test('places a child on the point it names', () {
      final child = Entity();

      final parent = Entity(
        shape: .square(40),
        position: .all(100),
        anchor: .center,
        children: [child],
      );

      child.position.setFrom(parent.pointAt(.bottomRight));
      Scene(parent);

      // The parent's box spans (80,80)..(120,120).
      expect(child.absolutePosition, Vector2(120, 120));
    });

    test('center is the middle of the box', () {
      final entity = Entity(shape: .rectangle(.new(40, 20)));

      expect(entity.center, Vector2(20, 10));
    });
  });

  test('absolutePosition matches position without a parent', () {
    final entity = Entity(position: .new(3, 4));

    expect(entity.absolutePosition, Vector2(3, 4));
  });

  test('absolutePosition composes translation through every ancestor', () {
    final entity = Entity(position: .new(1, 2));

    Entity(
      position: .new(10, 20),
      children: [
        Entity(
          position: .new(100, 200),
          children: [entity],
        ),
      ],
    );

    expect(entity.absolutePosition, Vector2(111, 222));
  });

  test('absolutePosition applies an ancestor\'s scale', () {
    final entity = Entity(position: .new(3, 4));

    Entity(
      position: .new(10, 10),
      scale: .new(2, 3),
      children: [entity],
    );

    expect(entity.absolutePosition, Vector2(16, 22));
  });

  test('absolutePosition applies an ancestor\'s angle', () {
    final entity = Entity(position: .new(10, 0));

    Entity(
      angle: math.pi / 2,
      children: [entity],
    );

    final absolute = entity.absolutePosition;

    expect(absolute.x, closeTo(0, 1e-12));
    expect(absolute.y, closeTo(10, 1e-12));
  });

  test('scenePosition stops at upTo without including it', () {
    final entity = Entity(position: .new(1, 2));
    late final Entity middle;

    Entity(
      position: .new(100, 200),
      children: [
        middle = Entity(
          position: .new(10, 20),
          children: [entity],
        ),
      ],
    );

    expect(entity.scenePosition(middle), Vector2(1, 2));
    expect(entity.scenePosition(), entity.absolutePosition);
  });

  test('absolutePosition agrees with absoluteTransform\'s translation', () {
    final entity = Entity(
      position: .new(3, 4),
      scale: .new(2, 2),
      angle: 0.75,
    );

    Entity(
      position: .new(10, 20),
      scale: .new(1.5, 0.5),
      angle: -0.4,
      children: [
        Entity(
          position: .new(5, 6),
          angle: 1.1,
          children: [entity],
        ),
      ],
    );

    final transform = entity.absoluteTransform();
    final absolute = entity.absolutePosition;

    expect(absolute.x, closeTo(transform[6], 1e-12));
    expect(absolute.y, closeTo(transform[7], 1e-12));
  });

  test('absolutePosition returns a fresh vector the caller may mutate', () {
    final entity = Entity(position: .new(3, 4));
    final absolute = entity.absolutePosition..setValues(0, 0);

    expect(entity.position, Vector2(3, 4));
    expect(absolute, Vector2.zero);
    expect(entity.absolutePosition, isNot(same(absolute)));
  });
}
