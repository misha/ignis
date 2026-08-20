import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  group('a shape of its own', () {
    test('keeps a shape it was given', () {
      final slot = ShapeNode(shape: .rectangle(.new(30, 20)));
      final taps = TapInput(shape: .square(6));

      slot.add(taps);
      slot.mount();

      expect(taps.size, Vector2.all(6));
    });

    test('hands its shape back to the chain with null', () {
      final slot = ShapeNode(shape: .rectangle(.new(30, 20)));
      final taps = TapInput(shape: .square(6));

      slot.add(taps);
      slot.mount();
      taps.shape = null;

      expect(taps.shape, isA<Rectangle>());
      expect(taps.size, Vector2(30, 20));
    });

    test('hit tests the shape it inherits', () {
      final taps = TapInput();
      final slot = ShapeNode(shape: .square(10), children: [taps]);

      slot.mount();

      expect(slot.hitTest(.all(5)).firstOrNull, same(taps));
      expect(slot.hitTest(.all(15)).firstOrNull, isNull);
    });

    test('hit tests nothing with no shape anywhere above it', () {
      final taps = TapInput();
      final root = Node(children: [taps]);

      root.mount();

      expect(root.hitTest(.zero).firstOrNull, isNull);
    });
  });

  test(
    'excludes a point outside a rotated rectangle hit area whose AABB would otherwise contain it',
    () {
      final root = Node(
        children: [
          TapInput(
            shape: .square(10),
            anchor: .center,
            angle: math.pi / 4, // 45 degrees, turning the square into a diamond.
          ),
        ],
      );

      // (7, 7) sits in the AABB's corner but outside the rotated square.
      expect(root.hitTest(.all(7)).firstOrNull, isNull);
      expect(root.hitTest(.all(3)).firstOrNull, isNotNull);
    },
  );

  test('returns nothing when no InputNode contains the point', () {
    final root = Node(
      children: [
        TapInput(
          shape: .square(10),
        ),
      ],
    );

    expect(root.hitTest(.all(100)), isEmpty);
  });

  test('returns the InputNode whose rectangle hit area contains the point', () {
    late final InputNode a;

    final root = Node(
      children: [
        a = TapInput(
          shape: .square(10),
        ),
      ],
    );

    expect(root.hitTest(.all(5)).firstOrNull, same(a));
  });

  test('excludes a point outside a circle hit area whose AABB would otherwise contain it', () {
    late final InputNode a;

    final root = Node(
      children: [
        a = TapInput(
          shape: .circle(5),
        ),
      ],
    );

    // (10, 10) sits in the AABB's corner but outside the inscribed circle.
    expect(root.hitTest(.all(10)).firstOrNull, isNull);
    expect(root.hitTest(.all(3)).firstOrNull, same(a));
  });

  test('accounts for the anchor when computing the hit area', () {
    late final InputNode a;

    final root = Node(
      children: [
        a = TapInput(
          shape: .square(10),
          anchor: .center,
        ),
      ],
    );

    // Centered on (0, 0), so the hit area spans [-5, 5] on both axes.
    expect(root.hitTest(.all(-3)).firstOrNull, same(a));
    expect(root.hitTest(.all(8)).firstOrNull, isNull);
  });

  test('prefers the higher-priority sibling when hit areas overlap', () {
    late final InputNode a;

    final root = Node(
      children: [
        a = TapInput(
          shape: .square(10),
          priority: 1,
        ),
        TapInput(
          shape: .square(10),
        ),
      ],
    );

    expect(root.hitTest(.all(5)).firstOrNull, same(a));
  });

  test('yields every overlapping sibling, topmost first', () {
    late final InputNode a;
    late final InputNode b;
    late final InputNode c;

    final root = Node(
      children: [
        b = TapInput(
          shape: .square(10),
          priority: 1,
        ),
        c = TapInput(
          shape: .square(10),
          priority: 0,
        ),
        a = TapInput(
          shape: .square(10),
          priority: 2,
        ),
      ],
    );

    expect(root.hitTest(.all(5)).toList(), [a, b, c]);
  });

  test('prefers a nested child over its ancestor when both overlap', () {
    late final InputNode child;

    final root = Node(
      children: [
        TapInput(
          shape: .square(10),
          children: [
            child = TapInput(
              shape: .square(10),
            ),
          ],
        ),
      ],
    );

    // Children always paint on top of their parent, regardless of priority.
    expect(root.hitTest(.all(5)).firstOrNull, same(child));
  });

  test('skips a disabled InputNode', () {
    final root = Node(
      children: [
        TapInput(
          shape: .square(10),
          enabled: false,
        ),
      ],
    );

    expect(root.hitTest(.all(5)), isEmpty);
  });

  test('skips an entire disabled subtree', () {
    final root = Node(
      children: [
        Node(
          enabled: false,
          children: [
            TapInput(
              shape: .square(10),
            ),
          ],
        ),
      ],
    );

    expect(root.hitTest(.all(5)), isEmpty);
  });

  test('non-InputNode nodes are transparent to hit-testing', () {
    late final InputNode a;

    final root = Node(
      children: [
        Node(
          children: [
            a = TapInput(
              shape: .square(10),
            ),
          ],
        ),
      ],
    );

    expect(root.hitTest(.all(5)).firstOrNull, same(a));
  });
}
