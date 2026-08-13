import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/test_layout_node.dart';

void main() {
  test('sizes to the smallest constraint when there is no child', () {
    final node = AlignNode();
    node.layout(.new(min: .new(5, 5), max: .new(50, 50)));
    expect((node.width, node.height), (5.0, 5.0));
  });

  test('centers a fixed-size leaf child by default', () {
    final child = ShapeNode(shape: Rectangle(.new(20, 10)));
    final node = AlignNode(children: [child]);
    node.layout(.tight(.new(100, 60)));
    expect(child.position, Vector2(40, 25));
  });

  test('honors a custom alignment', () {
    final child = ShapeNode(shape: Rectangle(.new(20, 10)));
    final node = AlignNode(alignment: .bottomRight(), children: [child]);
    node.layout(.tight(.new(100, 60)));
    expect(child.position, Vector2(80, 50));
  });

  test('shrink-wraps to the child on an unbounded axis', () {
    final child = ShapeNode(shape: Rectangle(.new(20, 10)));
    final node = AlignNode(children: [child]);
    node.layout(.unbounded());
    expect((node.width, node.height), (20.0, 10.0));
  });

  test('lays out a LayoutNode child with loosened constraints', () {
    final child = TestLayoutNode();
    final node = AlignNode(children: [child]);
    node.layout(.new(min: .new(10, 10), max: .new(100, 60)));
    expect(child.lastConstraints, LayoutConstraints(min: .zero(), max: .new(100, 60)));
  });

  test('accounts for a non-default child anchor', () {
    final child = ShapeNode(shape: Rectangle(.new(20, 10)), anchor: .center());
    final node = AlignNode(children: [child]);
    node.layout(.tight(.new(100, 60)));
    expect(child.position, Vector2(50, 30));
  });

  test('positions every child according to the same alignment', () {
    final a = ShapeNode(shape: Rectangle(.new(20, 10)));
    final b = ShapeNode(shape: Rectangle(.new(10, 20)));
    final node = AlignNode(alignment: .bottomRight(), children: [a, b]);
    node.layout(.tight(.new(100, 60)));
    expect(a.position, Vector2(80, 50));
    expect(b.position, Vector2(90, 40));
  });

  test('sizes to the largest child on each unbounded axis', () {
    final a = ShapeNode(shape: Rectangle(.new(20, 10)));
    final b = ShapeNode(shape: Rectangle(.new(10, 30)));
    final node = AlignNode(children: [a, b]);
    node.layout(.unbounded());
    expect((node.width, node.height), (20.0, 30.0));
  });
}
