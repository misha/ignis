import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_layout_node.dart';

void main() {
  test('lays out against unbounded constraints when unmounted', () {
    final node = TestLayoutNode();
    node.tick(0);
    expect(node.layouts, [LayoutConstraints.unbounded()]);
  });

  test('lays out against unbounded constraints when mounted but not yet resized', () {
    final node = TestLayoutNode();
    final scene = node.mount();
    scene.update(0);
    expect(node.layouts, [LayoutConstraints.unbounded()]);
  });

  test('lays out against tight scene-size constraints once resized', () {
    final node = TestLayoutNode();
    final scene = node.mount();
    scene.resize(100, 80);
    scene.update(0);
    expect(node.layouts, [LayoutConstraints.tight(.new(100, 80))]);
  });

  test('recomputes against the new size after a later resize', () {
    final node = TestLayoutNode();
    final scene = node.mount();
    scene.resize(100, 80);
    scene.update(0);
    expect(node.layouts, [LayoutConstraints.tight(.new(100, 80))]);

    scene.resize(50, 40);
    scene.update(0);
    expect(node.layouts, [
      LayoutConstraints.tight(.new(100, 80)),
      LayoutConstraints.tight(.new(50, 40)),
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

  test('a LayoutNode behind a plain non-SizedNode intermediate is never laid out', () {
    final child = TestLayoutNode();
    final wrapper = Node(children: [child]);
    final parent = TestLayoutNode(children: [wrapper]);
    final scene = parent.mount();
    scene.resize(100, 80);
    scene.update(0);
    expect(child.layouts, isEmpty);
  });

  test('layout clamps an out-of-range performLayout result to the given constraints', () {
    final node = TestLayoutNode(sizeToReturn: .new(200, 5));
    node.layout(.new(min: .all(10), max: .all(100)));
    expect((node.width, node.height), (100.0, 10.0));
  });

  test('LayoutEngine.place compensates for a non-default child anchor', () {
    final child = TestLayoutNode(sizeToReturn: .new(20, 10), anchor: .center());
    child.layout(.tight(.new(20, 10)));
    LayoutEngine.place(child, .all(50));
    expect(child.position, Vector2(60, 55));
  });
}
