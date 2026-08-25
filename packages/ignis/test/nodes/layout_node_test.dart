import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_layout_node.dart';

void main() {
  test('lays out against unbounded constraints when mounted but not yet resized', () {
    final node = TestLayoutNode();
    final scene = node.mount();
    scene.update(0);
    expect(node.layouts, [LayoutConstraints.unbounded()]);
  });

  test('lays out against loose scene-size constraints once resized', () {
    final node = TestLayoutNode();
    final scene = node.mount();
    scene.resize(100, 80);
    scene.update(0);
    expect(node.layouts, [LayoutConstraints.loose(.new(100, 80))]);
  });

  test('keeps a fixed size at the layout root', () {
    final node = BoxNode(width: 40, height: 30);
    final scene = node.mount();
    scene.resize(100, 80);
    scene.update(0);
    expect((node.width, node.height), (40.0, 30.0));
  });

  test('recomputes against the new size after a later resize', () {
    final node = TestLayoutNode();
    final scene = node.mount();
    scene.resize(100, 80);
    scene.update(0);
    expect(node.layouts, [LayoutConstraints.loose(.new(100, 80))]);

    scene.resize(50, 40);
    scene.update(0);
    expect(node.layouts, [
      LayoutConstraints.loose(.new(100, 80)),
      LayoutConstraints.loose(.new(50, 40)),
    ]);
  });

  test('a LayoutNode child is laid out by its ancestor, not from its own tick', () {
    final child = TestLayoutNode();
    final parent = TestLayoutNode(children: [child]);
    final scene = parent.mount();
    scene.resize(100, 80);
    scene.update(0);
    expect(child.layouts.length, 1);
  });

  test('a LayoutNode behind a plain node becomes its own layout root', () {
    final child = TestLayoutNode();
    final parent = TestLayoutNode(
      children: [
        Node(children: [child]),
      ],
    );

    final scene = parent.mount();
    scene.resize(100, 80);
    scene.update(0);

    expect(child.isLayoutRoot, isTrue);
    expect(child.layouts, [LayoutConstraints.loose(.new(100, 80))]);
  });

  test('a plain node hides its children from its layout parent', () {
    final node = RowNode(
      mainAxisSize: .min,
      children: [
        Node(
          children: [
            ShapeNode(shape: Rectangle.square(10)),
            ShapeNode(shape: Rectangle.square(20)),
          ],
        ),
      ],
    );

    node.layout(.loose(.all(200)));
    expect(node.width, 0);
  });

  group('isLayoutRoot', () {
    test('is true without a parent', () {
      expect(TestLayoutNode().isLayoutRoot, isTrue);
    });

    test('is false under a LayoutNode', () {
      final child = TestLayoutNode();
      TestLayoutNode(children: [child]);
      expect(child.isLayoutRoot, isFalse);
    });

    test('is true under a LayoutNode behind a plain node', () {
      final child = TestLayoutNode();
      TestLayoutNode(
        children: [
          Node(children: [child]),
        ],
      );

      expect(child.isLayoutRoot, isTrue);
    });

    test('is true under a plain node with no LayoutNode above it', () {
      final child = TestLayoutNode();
      Node(children: [child]);
      expect(child.isLayoutRoot, isTrue);
    });
  });

  group('structural changes', () {
    test('re-resolves after a child is added', () {
      final node = RowNode(
        mainAxisSize: .min,
        children: [ShapeNode(shape: Rectangle.square(10))],
      );

      node.layout(.loose(.all(200)));
      expect(node.width, 10);

      node.add(ShapeNode(shape: Rectangle.square(20)));
      node.layout(.loose(.all(200)));
      expect(node.width, 30);
    });

    test('re-resolves after a child is removed', () {
      final victim = ShapeNode(shape: Rectangle.square(20));
      final node = RowNode(
        mainAxisSize: .min,
        children: [
          ShapeNode(shape: Rectangle.square(10)),
          victim,
        ],
      );

      node.layout(.loose(.all(200)));
      expect(node.width, 30);

      node.remove(victim);
      node.layout(.loose(.all(200)));
      expect(node.width, 10);
    });

    test('ignores a change behind a plain node, which is not its child', () {
      final wrapper = Node(children: [ShapeNode(shape: Rectangle.square(10))]);
      final node = RowNode(mainAxisSize: .min, children: [wrapper]);

      node.layout(.loose(.all(200)));
      wrapper.add(ShapeNode(shape: Rectangle.square(20)));
      node.layout(.loose(.all(200)));
      expect(node.width, 0);
    });

    test('re-resolves after a reorder by priority', () {
      final a = ShapeNode(shape: Rectangle.square(10));
      final b = ShapeNode(shape: Rectangle.square(20));
      final node = RowNode(mainAxisSize: .min, children: [a, b]);

      node.layout(.loose(.all(200)));
      expect([a.position.x, b.position.x], [0.0, 10.0]);

      b.priority = -1;
      node.layout(.loose(.all(200)));
      expect([a.position.x, b.position.x], [20.0, 0.0]);
    });
  });

  test('layout clamps an out-of-range constrain result to the given constraints', () {
    final node = TestLayoutNode(sizeToReturn: .new(200, 5));
    node.layout(.new(min: .all(10), max: .all(100)));
    expect((node.width, node.height), (100.0, 10.0));
  });
}
