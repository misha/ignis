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
    final a = LiveTestNode(name: 'A');
    final b = LiveTestNode(name: 'B');
    a.add(b);
    final scene = a.mount();

    scene.reassemble();

    expect(a.builds, 2, reason: 'once on mount, once on the walk');
    expect(b.builds, 2);
  });

  test('drops a reassemble triggered from inside a reassemble', () {
    final node = LiveTestNode();
    final scene = node.mount();
    node.builder = (_) => scene.reassemble();

    scene.reassemble();

    expect(node.builds, 2);
  });

  group('pause', () {
    test('pause and resume flip it, and emit only on a change', () {
      final scene = Node().mount();
      final emitted = <bool>[];
      scene.onPause(emitted.add);

      scene.pause();
      expect(scene.paused, isTrue);

      scene.pause();
      expect(emitted, [true], reason: 'already paused, nothing changed');

      scene.resume();
      expect(scene.paused, isFalse);
      expect(emitted, [true, false]);
    });

    test('the setter goes through pause and resume', () {
      final scene = Node().mount();
      final emitted = <bool>[];
      scene.onPause(emitted.add);

      scene.paused = true;
      scene.paused = true;
      scene.paused = false;

      expect(emitted, [true, false]);
    });
  });
}
