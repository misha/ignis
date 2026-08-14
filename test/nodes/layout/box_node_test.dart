import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/test_layout_node.dart';

void main() {
  test('sizes to the smallest constraint when nothing is fixed and there is no child', () {
    final node = BoxNode();
    node.layout(.new(min: .all(5), max: .all(50)));
    expect((node.width, node.height), (5.0, 5.0));
  });

  test('sizes to its fixed width and height', () {
    final node = BoxNode(width: 30, height: 20);
    node.layout(.loose(.all(100)));
    expect((node.width, node.height), (30.0, 20.0));
  });

  test('square sets width and height to the same size', () {
    final node = BoxNode.square(30);
    node.layout(.loose(.all(100)));
    expect((node.width, node.height), (30.0, 30.0));
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

  test('shrinks to the largest child on an axis without a fixed size', () {
    final a = ShapeNode(shape: Rectangle(.new(20, 10)));
    final b = ShapeNode(shape: Rectangle(.new(10, 25)));
    final node = BoxNode(width: 50, children: [a, b]);
    node.layout(.loose(.all(100)));
    expect((node.width, node.height), (50.0, 25.0));
  });

  test('positions every child at the local origin', () {
    final a = ShapeNode(shape: Rectangle(.new(20, 10)));
    final b = ShapeNode(shape: Rectangle.square(10));
    final node = BoxNode(width: 50, height: 50, children: [a, b]);
    node.layout(.tight(.all(50)));
    expect([a.position, b.position], [Vector2.zero, Vector2.zero]);
  });

  test('grows to fit the padding alone when nothing else is fixed', () {
    final node = BoxNode(padding: .all(5));
    node.layout(.loose(.all(100)));
    expect((node.width, node.height), (10.0, 10.0));
  });

  test('insets the child by the padding within a fixed size', () {
    final child = ShapeNode(shape: Rectangle.square(10));
    final node = BoxNode(width: 50, height: 50, padding: .all(5), children: [child]);
    node.layout(.loose(.all(100)));
    expect(child.position, Vector2(5, 5));
  });

  test('deflates the fixed size by the padding for a LayoutNode child', () {
    final child = TestLayoutNode();
    final node = BoxNode(width: 50, height: 50, padding: .all(5), children: [child]);
    node.layout(.loose(.all(100)));
    expect(child.lastConstraints, LayoutConstraints.tight(.all(40)));
  });
}
