import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_node.dart';
import '../support/test_server.dart';

void main() {
  test('a registration made in a build dies with the node', () {
    final server = TestServer();
    final node = TestNode(
      builder: (node) {
        server.add(node);
      },
    );

    final scene = node.mount();
    expect(server.nodes, [node]);

    scene.destroy();
    expect(server.nodes, isEmpty);
  });

  test("a registration made outside a build is the caller's to end", () {
    final server = TestServer();
    final node = Node();
    final cleanup = server.add(node);
    expect(server.nodes, [node]);

    cleanup();
    expect(server.nodes, isEmpty);
  });
}
