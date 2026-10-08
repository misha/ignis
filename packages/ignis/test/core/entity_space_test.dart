import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
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
