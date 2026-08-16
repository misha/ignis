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

    scene.reassemble(.reload);

    expect(a.builds, 2, reason: 'once on mount, once on the walk');
    expect(b.builds, 2);
  });

  test('drops a reassemble triggered from inside a reassemble', () {
    final node = TestNode();
    final scene = node.mount();
    node.buildAction = () => scene.reassemble(.reload);

    scene.reassemble(.reload);

    expect(node.builds, 2);
  });

  test('flushes what a reassemble enqueued, without an update', () {
    final node = TestNode();
    final child = TestNode('child');
    final scene = node.mount();
    node.buildAction = () => node.add(child);

    scene.reassemble(.reload);

    expect(node.children, [child]);
    expect(child.isMounted, isTrue);
  });
}
