import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_node.dart';
import '../support/test_registry.dart';

void main() {
  test('a registration made in a build dies with the node', () {
    final registry = TestRegistry();
    final node = TestNode(
      builder: (node) {
        registry.add(node);
      },
    );

    final scene = node.mount();
    expect(registry.nodes, [node]);

    scene.destroy();
    expect(registry.nodes, isEmpty);
  });

  test("a registration made outside a build is the caller's to end", () {
    final registry = TestRegistry();
    final node = Node();
    final cleanup = registry.add(node);
    expect(registry.nodes, [node]);

    cleanup();
    expect(registry.nodes, isEmpty);
  });
}
