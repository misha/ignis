import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/test_layout_node.dart';

void main() {
  test('sizes to the padding alone when there is no child', () {
    final node = PaddingNode(padding: .all(10));
    node.layout(.loose(.new(100, 100)));
    expect((node.width, node.height), (20.0, 20.0));
  });

  test('grows to fit the child plus the padding', () {
    final child = ShapeNode(shape: Rectangle(.new(20, 10)));
    final node = PaddingNode(padding: .all(5), children: [child]);
    node.layout(.loose(.new(100, 100)));
    expect((node.width, node.height), (30.0, 20.0));
  });

  test('positions the child inset by the padding', () {
    final child = ShapeNode(shape: Rectangle(.new(20, 10)));
    final node = PaddingNode(
      padding: .fromLTRB(4, 8, 0, 0),
      children: [child],
    );

    node.layout(.loose(.new(100, 100)));
    expect(child.position, Vector2(4, 8));
  });

  test('deflates the constraints handed to a LayoutNode child', () {
    final child = TestLayoutNode();
    final node = PaddingNode(padding: .all(5), children: [child]);
    node.layout(.new(min: .new(20, 20), max: .new(100, 100)));
    expect(child.lastConstraints, LayoutConstraints(min: .new(10, 10), max: .new(90, 90)));
  });

  test('positions every child inset by the same padding', () {
    final a = ShapeNode(shape: Rectangle(.new(20, 10)));
    final b = ShapeNode(shape: Rectangle.square(10));
    final node = PaddingNode(padding: .all(5), children: [a, b]);
    node.layout(.loose(.new(100, 100)));
    expect([a.position, b.position], [Vector2(5, 5), Vector2(5, 5)]);
  });

  test('grows to fit the largest child plus the padding', () {
    final a = ShapeNode(shape: Rectangle(.new(20, 10)));
    final b = ShapeNode(shape: Rectangle(.new(10, 25)));
    final node = PaddingNode(padding: .all(5), children: [a, b]);
    node.layout(.loose(.new(100, 100)));
    expect((node.width, node.height), (30.0, 35.0));
  });
}
