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
    final scene = a.mount()..update(0);

    expect(a.passes, 1, reason: 'the first pass runs on the first update');

    scene.reassemble(.reload);
    scene.update(0);

    expect(a.passes, 2);
    expect(b.passes, 2);
  });

  test('costs exactly one full pass, not one per frame', () {
    final node = TestNode();
    final scene = node.mount()
      ..update(0)
      ..update(0);

    expect(node.passes, 1, reason: 'replay frames skip effects');

    scene.reassemble(.reload);
    scene.update(0);
    scene.update(0);

    expect(node.passes, 2);
    expect(node.updates, 4, reason: 'every frame still ticks');
  });
}
