import 'package:flutter/rendering.dart' show FlexFit;
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/test_layout_node.dart';

void main() {
  group('FlexibleNode', () {
    test('sizes to the smallest constraint when there is no child', () {
      final node = FlexibleNode();
      node.layout(.new(min: .all(5), max: .all(50)));
      expect((node.width, node.height), (5.0, 5.0));
    });

    test('positions a fixed-size leaf child at its local origin', () {
      final child = ShapeNode(shape: Rectangle(.new(20, 10)));
      final node = FlexibleNode(children: [child]);
      node.layout(.tight(.new(100, 60)));
      expect(child.position, Vector2.zero());
    });

    test('lays out a LayoutNode child with exactly the received constraints', () {
      final child = TestLayoutNode();
      final node = FlexibleNode(children: [child]);
      final constraints = LayoutConstraints(min: .all(10), max: .new(100, 60));
      node.layout(constraints);
      expect(child.lastConstraints, constraints);
    });

    test('defaults flex to 1 and fit to loose', () {
      final node = FlexibleNode();
      expect((node.flex, node.fit), (1, FlexFit.loose));
    });

    test('rejects more than one child', () {
      final node = FlexibleNode(
        children: [
          ShapeNode(shape: Rectangle.square(10)),
          ShapeNode(shape: Rectangle.square(10)),
        ],
      );

      expect(() => node.layout(.unbounded()), throwsAssertionError);
    });

    test('flex and fit are inert without a FlexNode ancestor', () {
      final child = ShapeNode(shape: Rectangle(.new(20, 10)));
      final node = FlexibleNode(fit: .tight, children: [child]);
      node.layout(.new(min: .zero(), max: .all(200)));
      expect((node.width, node.height), (20.0, 10.0));
    });
  });

  group('ExpandedNode', () {
    test('defaults fit to tight', () {
      final node = ExpandedNode();
      expect(node.fit, FlexFit.tight);
    });

    test('honors a custom flex', () {
      final node = ExpandedNode(flex: 3);
      expect(node.flex, 3);
    });
  });
}
