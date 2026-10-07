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
    expect(scene.destroy, returnsNormally);
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
