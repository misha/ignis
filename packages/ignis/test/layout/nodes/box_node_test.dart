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
    final node = BoxNode.square(size: 30);
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

  test('grows to fit the child plus the padding when nothing is fixed', () {
    final child = ShapeNode(shape: Rectangle(.new(20, 10)));
    final node = BoxNode(padding: .all(5), children: [child]);
    node.layout(.loose(.all(100)));
    expect((node.width, node.height), (30.0, 20.0));
  });

  test('positions the child inset by an asymmetric padding', () {
    final child = ShapeNode(shape: Rectangle(.new(20, 10)));
    final node = BoxNode(
      padding: .fromLTRB(4, 8, 0, 0),
      children: [child],
    );

    node.layout(.loose(.all(100)));
    expect(child.position, Vector2(4, 8));
  });

  test('deflates unfixed constraints by the padding for a LayoutNode child', () {
    final child = TestLayoutNode();
    final node = BoxNode(padding: .all(5), children: [child]);
    node.layout(.new(min: .all(20), max: .all(100)));
    expect(child.lastConstraints, LayoutConstraints(min: .all(10), max: .all(90)));
  });

  test('positions every child inset by the same padding', () {
    final a = ShapeNode(shape: Rectangle(.new(20, 10)));
    final b = ShapeNode(shape: Rectangle.square(10));
    final node = BoxNode(padding: .all(5), children: [a, b]);
    node.layout(.loose(.all(100)));
    expect([a.position, b.position], [Vector2(5, 5), Vector2(5, 5)]);
  });

  test('grows to fit the largest child plus the padding', () {
    final a = ShapeNode(shape: Rectangle(.new(20, 10)));
    final b = ShapeNode(shape: Rectangle(.new(10, 25)));
    final node = BoxNode(padding: .all(5), children: [a, b]);
    node.layout(.loose(.all(100)));
    expect((node.width, node.height), (30.0, 35.0));
  });

  group('alignment', () {
    test('fills the largest constraint with no child', () {
      final node = BoxNode(alignment: .center);
      node.layout(.new(min: .all(5), max: .all(50)));
      expect((node.width, node.height), (50.0, 50.0));
    });

    test('fills a bounded axis rather than shrink-wrapping to the child', () {
      final child = ShapeNode(shape: Rectangle(.new(20, 10)));
      final node = BoxNode(alignment: .center, children: [child]);
      node.layout(.loose(.all(100)));
      expect((node.width, node.height), (100.0, 100.0));
      expect(child.position, Vector2(40, 45));
    });

    test('centers a fixed-size leaf child', () {
      final child = ShapeNode(shape: Rectangle(.new(20, 10)));
      final node = BoxNode(alignment: .center, children: [child]);
      node.layout(.tight(.new(100, 60)));
      expect(child.position, Vector2(40, 25));
    });

    test('honors a custom alignment', () {
      final child = ShapeNode(shape: Rectangle(.new(20, 10)));
      final node = BoxNode(alignment: .bottomRight, children: [child]);
      node.layout(.tight(.new(100, 60)));
      expect(child.position, Vector2(80, 50));
    });

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

    test('accounts for a non-default child anchor', () {
      final child = ShapeNode(shape: Rectangle(.new(20, 10)), anchor: .center);
      final node = BoxNode(alignment: .center, children: [child]);
      node.layout(.tight(.new(100, 60)));
      expect(child.position, Vector2(50, 30));
    });

    test('positions every child according to the same alignment', () {
      final a = ShapeNode(shape: Rectangle(.new(20, 10)));
      final b = ShapeNode(shape: Rectangle(.new(10, 20)));
      final node = BoxNode(alignment: .bottomRight, children: [a, b]);
      node.layout(.tight(.new(100, 60)));
      expect(a.position, Vector2(80, 50));
      expect(b.position, Vector2(90, 40));
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
