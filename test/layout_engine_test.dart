import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/test_layout_item.dart';

void main() {
  group('box', () {
    Vector2 box(
      List<TestLayoutItem> items, {
      LayoutConstraints? constraints,
      double? width,
      double? height,
      EdgeInsets? padding,
      Anchor? alignment,
    }) => LayoutEngine.box(
      items: items,
      constraints: constraints ?? .unbounded(),
      targetWidth: width,
      targetHeight: height,
      padding: padding ?? EdgeInsets.zero,
      alignment: alignment,
    );

    test('sizes to its target, whatever the items measure', () {
      final items = [TestLayoutItem(size: .all(10))];
      expect(box(items, width: 40, height: 30), Vector2(40, 30));
    });

    test('shrink-wraps to the largest item per axis without a target', () {
      final items = [
        TestLayoutItem(size: .new(20, 10)),
        TestLayoutItem(size: .new(10, 30)),
      ];

      expect(box(items), Vector2(20, 30));
    });

    test('grows past its items by the padding', () {
      final items = [TestLayoutItem(size: .all(10))];
      expect(box(items, padding: const .all(5)), Vector2(20, 20));
    });

    test('an unaligned item lands on the padded origin', () {
      final items = [TestLayoutItem(size: .all(10))];
      box(items, width: 100, height: 100, padding: const .fromLTRB(4, 8, 0, 0));
      expect(items.single.position, Vector2(4, 8));
    });

    test('an unaligned item is measured against the unloosened constraints', () {
      final items = [TestLayoutItem(size: .all(10))];
      box(items, constraints: .tight(.all(50)));
      expect(items.single.lastConstraints, LayoutConstraints.tight(.all(50)));
    });

    test('an aligned item is measured against loosened constraints', () {
      final items = [TestLayoutItem(size: .all(10))];
      box(items, constraints: .tight(.all(50)), alignment: .center);
      expect(items.single.lastConstraints, LayoutConstraints(min: .zero, max: .all(50)));
    });

    test('alignment places each item in the room left over', () {
      final items = [
        TestLayoutItem(size: .new(20, 10)),
        TestLayoutItem(size: .new(10, 20)),
      ];

      box(items, constraints: .tight(.new(100, 60)), alignment: .bottomRight);
      expect(items.map((i) => i.position), [Vector2(80, 50), Vector2(90, 40)]);
    });

    test('alignment measures the leftover room inside the padding', () {
      final items = [TestLayoutItem(size: .all(20))];
      box(
        items,
        constraints: .tight(.all(100)),
        padding: const .all(10),
        alignment: .center,
      );

      // The padded interior is 80x80, so 60 of leftover room, halved.
      expect(items.single.position, Vector2(40, 40));
    });

    test('shrink-wrapping under tight constraints still fills, via satisfy', () {
      final items = [TestLayoutItem(size: .all(10))];
      expect(box(items, constraints: .tight(.new(100, 60))), Vector2(100, 60));
    });

    test('reports the smallest constraint with no items at all', () {
      expect(
        box(
          [],
          constraints: .new(min: .all(5), max: .all(50)),
        ),
        Vector2(5, 5),
      );
    });
  });

  group('flex', () {
    test('splits leftover main-axis space evenly among equal-flex children', () {
      final items = List.generate(
        2,
        (_) => TestLayoutItem(
          size: .all(50),
          flex: .expanded(),
        ),
      );

      final selfSize = LayoutEngine.flex(
        direction: .horizontal,
        constraints: .tight(.new(100, 50)),
        items: items,
        mainAxisAlignment: .start,
        crossAxisAlignment: .center,
        mainAxisSize: .max,
        spacing: 0,
      );

      expect(selfSize, Vector2(100, 50));
      expect(items.map((i) => i.position), [Vector2(0, 0), Vector2(50, 0)]);
    });

    test('stretch places every child at the cross-axis origin', () {
      final items = [TestLayoutItem(size: .all(10))];

      LayoutEngine.flex(
        direction: .horizontal,
        constraints: .tight(.new(100, 50)),
        items: items,
        mainAxisAlignment: .start,
        crossAxisAlignment: .stretch,
        mainAxisSize: .max,
        spacing: 0,
      );

      expect(items.single.position, Vector2(0, 0));
    });

    test('honors spacing between non-flex children and shrinks to consumed space', () {
      final items = List.generate(2, (_) => TestLayoutItem(size: .all(10)));

      final selfSize = LayoutEngine.flex(
        direction: .horizontal,
        constraints: .loose(.new(200, 50)),
        items: items,
        mainAxisAlignment: .start,
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        spacing: 5,
      );

      expect(selfSize.x, 25);
      expect(items.map((i) => i.position), [Vector2(0, 0), Vector2(15, 0)]);
    });

    test('uses the y axis as main when direction is vertical', () {
      final items = List.generate(
        2,
        (_) => TestLayoutItem(
          size: .all(50),
          flex: .expanded(),
        ),
      );

      LayoutEngine.flex(
        direction: .vertical,
        constraints: .tight(.new(50, 100)),
        items: items,
        mainAxisAlignment: .start,
        crossAxisAlignment: .center,
        mainAxisSize: .max,
        spacing: 0,
      );

      expect(items.map((i) => i.position), [Vector2(0, 0), Vector2(0, 50)]);
    });

    test('throws when the main axis is unbounded and a flex child demands forced space', () {
      final items = [TestLayoutItem(flex: .expanded())];

      expect(
        () => LayoutEngine.flex(
          direction: .horizontal,
          constraints: .loose(.new(double.infinity, 50)),
          items: items,
          mainAxisAlignment: .start,
          crossAxisAlignment: .center,
          mainAxisSize: .max,
          spacing: 0,
        ),
        throwsAssertionError,
      );
    });
  });
}
