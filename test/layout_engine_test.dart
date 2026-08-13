import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/test_measurable.dart';

void main() {
  group('stack', () {
    test('measures every child against the same constraints', () {
      final childConstraints = LayoutConstraints.tight(.new(50, 50));
      final items = List.generate(3, (_) => TestMeasurable(size: .new(10, 10)));

      LayoutEngine.stack(
        items: items,
        childConstraints: childConstraints,
        computeSelfSize: (count, largest) => largest,
        computeOffset: (self, child) => .zero(),
      );

      expect(items.map((i) => i.lastConstraints), [
        childConstraints,
        childConstraints,
        childConstraints,
      ]);
    });

    test('reports the largest extent per axis across all children', () {
      final sizes = [Vector2(10, 30), Vector2(20, 5), Vector2(5, 5)];
      final items = sizes.map((size) => TestMeasurable(size: size)).toList();
      Vector2? largestSeen;

      LayoutEngine.stack(
        items: items,
        childConstraints: .unbounded(),
        computeSelfSize: (count, largest) {
          largestSeen = largest;
          return largest;
        },
        computeOffset: (self, child) => .zero(),
      );

      expect(largestSeen, Vector2(20, 30));
    });

    test('passes the child count to computeSelfSize', () {
      final items = List.generate(4, (_) => TestMeasurable());
      int? countSeen;

      LayoutEngine.stack(
        items: items,
        childConstraints: .unbounded(),
        computeSelfSize: (count, largest) {
          countSeen = count;
          return largest;
        },
        computeOffset: (self, child) => .zero(),
      );

      expect(countSeen, 4);
    });

    test('computes an offset per child, in order, via computeOffset, and applies it', () {
      final sizes = [Vector2(10, 10), Vector2(20, 20)];
      final items = sizes.map((size) => TestMeasurable(size: size)).toList();

      final selfSize = LayoutEngine.stack(
        items: items,
        childConstraints: .unbounded(),
        computeSelfSize: (count, largest) => largest,
        computeOffset: (self, child) => .new(self.x - child.x, self.y - child.y),
      );

      expect(selfSize, Vector2(20, 20));
      expect(items.map((i) => i.position), [Vector2(10, 10), Vector2(0, 0)]);
    });

    test('applies nothing and reports a zero largest extent with no children', () {
      final selfSize = LayoutEngine.stack(
        items: [],
        childConstraints: .unbounded(),
        computeSelfSize: (count, largest) => largest,
        computeOffset: (self, child) => .zero(),
      );

      expect(selfSize, Vector2.zero());
    });
  });

  group('flex', () {
    test('splits leftover main-axis space evenly among equal-flex children', () {
      final items = List.generate(
        2,
        (_) => TestMeasurable(
          size: .new(50, 50),
          flex: 1,
          fit: .tight,
          canResize: true,
        ),
      );

      final selfSize = LayoutEngine.flex(
        direction: .horizontal,
        constraints: .tight(.new(100, 50)),
        items: items,
        mainAxisAlignment: .start,
        crossAxisAlignment: .center,
        mainAxisSize: .max,
        reverse: false,
        spacing: 0,
      );

      expect(selfSize, Vector2(100, 50));
      expect(items.map((i) => i.position), [Vector2(0, 0), Vector2(50, 0)]);
    });

    test('falls back to start for a child that cannot resize, even with stretch', () {
      final items = [TestMeasurable(size: .new(10, 10))];

      LayoutEngine.flex(
        direction: .horizontal,
        constraints: .tight(.new(100, 50)),
        items: items,
        mainAxisAlignment: .start,
        crossAxisAlignment: .stretch,
        mainAxisSize: .max,
        reverse: false,
        spacing: 0,
      );

      expect(items.single.position, Vector2(0, 0));
    });

    test('honors spacing between non-flex children and shrinks to consumed space', () {
      final items = List.generate(2, (_) => TestMeasurable(size: .new(10, 10)));

      final selfSize = LayoutEngine.flex(
        direction: .horizontal,
        constraints: .loose(.new(200, 50)),
        items: items,
        mainAxisAlignment: .start,
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        reverse: false,
        spacing: 5,
      );

      expect(selfSize.x, 25);
      expect(items.map((i) => i.position), [Vector2(0, 0), Vector2(15, 0)]);
    });

    test('reverse accumulates children from the end of the main axis', () {
      final items = List.generate(2, (_) => TestMeasurable(size: .new(10, 10)));

      LayoutEngine.flex(
        direction: .horizontal,
        constraints: .tight(.new(100, 50)),
        items: items,
        mainAxisAlignment: .start,
        crossAxisAlignment: .start,
        mainAxisSize: .max,
        reverse: true,
        spacing: 0,
      );

      expect(items.map((i) => i.position), [Vector2(90, 0), Vector2(80, 0)]);
    });

    test('uses the y axis as main when direction is vertical', () {
      final items = List.generate(
        2,
        (_) => TestMeasurable(
          size: .new(50, 50),
          flex: 1,
          fit: .tight,
          canResize: true,
        ),
      );

      LayoutEngine.flex(
        direction: .vertical,
        constraints: .tight(.new(50, 100)),
        items: items,
        mainAxisAlignment: .start,
        crossAxisAlignment: .center,
        mainAxisSize: .max,
        reverse: false,
        spacing: 0,
      );

      expect(items.map((i) => i.position), [Vector2(0, 0), Vector2(0, 50)]);
    });

    test('throws when the main axis is unbounded and a flex child demands forced space', () {
      final items = [
        TestMeasurable(
          flex: 1,
          fit: .tight,
          canResize: true,
        ),
      ];

      expect(
        () => LayoutEngine.flex(
          direction: .horizontal,
          constraints: .loose(.new(double.infinity, 50)),
          items: items,
          mainAxisAlignment: .start,
          crossAxisAlignment: .center,
          mainAxisSize: .max,
          reverse: false,
          spacing: 0,
        ),
        throwsAssertionError,
      );
    });
  });
}
