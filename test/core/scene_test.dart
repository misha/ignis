import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_node.dart';

void main() {
  test('tracks size and layout state after resize', () {
    final scene = Node().mount();
    scene.resize(100, 80);

    expect(scene.hasSize, isTrue);
    expect(scene.size, Vector2(100, 80));
  });

  test('resize emits only when the size actually changes', () {
    final node = Node();
    final scene = node.mount();
    var emissions = 0;
    node.onSceneResize((_) => emissions += 1);

    scene.resize(100, 80);
    scene.resize(100, 80);
    scene.resize(100, 90);

    expect(emissions, 2);
  });

  test('resize reaches every node in the tree', () {
    final parent = Node();
    final child = Node();
    parent.add(child);
    final scene = parent.mount();
    final sizes = <Vector2>[];
    parent.onSceneResize(sizes.add);
    child.onSceneResize(sizes.add);

    scene.resize(100, 80);

    expect(sizes, [Vector2(100, 80), Vector2(100, 80)]);
  });

  test('a node mounted into a sized scene hears the current size', () {
    final scene = Node().mount();
    scene.resize(100, 80);
    final node = Node();
    Vector2? heard;
    node.onSceneResize((size) => heard = size);

    scene.node.add(node);
    scene.update(0);

    expect(heard, Vector2(100, 80));
  });

  test('a destroyed scene refuses to be driven', () {
    final scene = Node().mount();
    scene.destroy();

    expect(() => scene.update(0), throwsAssertionError);
    expect(scene.reassemble, throwsAssertionError);
    expect(() => scene.resize(100, 80), throwsAssertionError);
    expect(scene.destroy, returnsNormally);
  });

  test('keeps the given node parentless once loaded', () {
    final node = Node();
    final scene = node.mount();

    expect(scene.node.parent, isNull);
  });

  test('reassembles the whole tree', () {
    final a = TestNode('A');
    final b = TestNode('B');
    a.add(b);
    final scene = a.mount();

    scene.reassemble();

    expect(a.reassembles, 1);
    expect(b.reassembles, 1);
  });

  test('drops a reassemble triggered from inside a reassemble', () {
    late final Scene scene;
    final node = TestNode()..action = () => scene.reassemble();
    scene = node.mount();

    scene.reassemble();

    expect(node.reassembles, 1);
  });
}
