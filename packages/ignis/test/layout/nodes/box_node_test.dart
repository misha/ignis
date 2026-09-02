import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/test_layout_node.dart';

void main() {
  test('sizes to the smallest constraint when nothing is fixed and there is no child', () {
    final node = BoxNode();
    node.layout(.new(min: .all(5), max: .all(50)));
    expect((node.width, node.height), (5.0, 5.0));
  });

  test('forces a tight size on a LayoutNode child', () {
    final child = TestLayoutNode();
    final node = BoxNode(width: 30, height: 20, children: [child]);
    node.layout(.loose(.all(100)));
    expect(child.lastConstraints, LayoutConstraints.tight(.new(30, 20)));
  });

  test('passes through the incoming constraints on an axis without a fixed size', () {
    final child = TestLayoutNode();
    final node = BoxNode(width: 30, children: [child]);
    node.layout(.new(min: .new(0, 10), max: .new(100, 60)));
    expect(child.lastConstraints, LayoutConstraints(min: .new(30, 10), max: .new(30, 60)));
  });

  test('clamps a fixed size that falls outside the incoming constraints', () {
    final node = BoxNode(width: 200, height: 5);
    node.layout(.new(min: .new(0, 10), max: .new(100, 60)));
    expect((node.width, node.height), (100.0, 10.0));
  });

  test('deflates the fixed size by the padding for a LayoutNode child', () {
    final child = TestLayoutNode();
    final node = BoxNode(width: 50, height: 50, padding: .all(5), children: [child]);
    node.layout(.loose(.all(100)));
    expect(child.lastConstraints, LayoutConstraints.tight(.all(40)));
  });

  test('deflates unfixed constraints by the padding for a LayoutNode child', () {
    final child = TestLayoutNode();
    final node = BoxNode(padding: .all(5), children: [child]);
    node.layout(.new(min: .all(20), max: .all(100)));
    expect(child.lastConstraints, LayoutConstraints(min: .all(10), max: .all(90)));
  });

  group('alignment', () {
    test('shrink-wraps to the child on an unbounded axis', () {
      final child = ShapeNode(shape: Rectangle(.new(20, 10)));
      final node = BoxNode(alignment: .center, children: [child]);
      node.layout(.unbounded());
      expect((node.width, node.height), (20.0, 10.0));
    });

    test('lays out a LayoutNode child with loosened constraints', () {
      final child = TestLayoutNode();
      final node = BoxNode(alignment: .center, children: [child]);
      node.layout(.new(min: .all(10), max: .new(100, 60)));
      expect(child.lastConstraints, LayoutConstraints(min: .zero, max: .new(100, 60)));
    });

    test('sizes to the largest child on each unbounded axis', () {
      final a = ShapeNode(shape: Rectangle(.new(20, 10)));
      final b = ShapeNode(shape: Rectangle(.new(10, 30)));
      final node = BoxNode(alignment: .center, children: [a, b]);
      node.layout(.unbounded());
      expect((node.width, node.height), (20.0, 30.0));
    });
  });
}
