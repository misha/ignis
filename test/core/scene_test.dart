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
