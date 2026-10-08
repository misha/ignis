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

  test('a destroyed scene refuses to be driven', () {
    final scene = Node().mount();
    scene.destroy();

    expect(() => scene.update(0), throwsAssertionError);
    expect(() => scene.resize(100, 80), throwsAssertionError);
    expect(scene.reassemble, throwsAssertionError);
    expect(scene.destroy, returnsNormally);
  });

  test('reassembling posts Reassemble to every node once', () {
    final reassembled = <TestNode>[];

    void record(TestNode node, Message message) {
      if (message is Reassemble) reassembled.add(node);
    }

    final child = TestNode(processor: record);
    final root = TestNode(processor: record, children: [child]);
    root.mount().reassemble();

    expect(reassembled, unorderedEquals([root, child]));
  });

  test('keeps the given node parentless once loaded', () {
    final node = Node();
    final scene = node.mount();

    expect(scene.root.parent, isNull);
  });

  test('mounting a root again under a narrower type throws', () {
    final node = TestNode();
    (node as Node).mount();

    expect(node.mount, throwsStateError);
  });
}
