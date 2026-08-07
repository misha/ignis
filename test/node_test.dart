import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/test_node.dart';

void main() {
  test('ignores duplicate child additions', () {
    final a = Node();
    final b = Node();
    a.add(b);

    expect(() => a.add(b), returnsNormally);
    expect(a.children, [b]);
  });

  test('prevents children from having two parents', () {
    final a = Node();
    final b = Node();
    final c = Node();
    a.add(c);

    expect(() => b.add(c), throwsStateError);
    expect(c.parent, same(a));
  });

  test('cannot own itself', () {
    final a = Node();

    expect(() => a.add(a), throwsStateError);
  });

  test('cannot be added beneath its descendants', () {
    final a = Node();
    final b = Node();
    final c = Node();
    a.add(b);
    b.add(c);

    expect(() => c.add(a), throwsStateError);
    expect(a.children, [b]);
    expect(b.children, [c]);
  });

  test('lists ancestors and descendants in traversal order', () {
    final a = Node();
    final b = Node();
    final c = Node();
    final d = Node();
    a.add(b);
    a.add(c);
    b.add(d);

    expect(d.ancestors, [b, a]);
    expect(a.descendants, [b, d, c]);
  });

  test('orders children by priority while preserving insertion order for ties', () {
    final a = Node();
    final b = Node();
    final c = Node();
    final d = Node();
    b.priority = 1;
    c.priority = -1;
    d.priority = 1;
    a.add(b);
    a.add(c);
    a.add(d);

    expect(a.children, [c, b, d]);
  });

  test('reorders children when their priority changes', () {
    final a = Node();
    final b = Node();
    final c = Node();
    final d = Node();
    a.add(b);
    a.add(c);
    a.add(d);

    c.priority = 1;
    expect(a.children, [b, d, c]);

    c.priority = 0;
    expect(a.children, [b, d, c]);
  });

  test('updates and renders children in priority order', () {
    final log = TestLog();
    final a = TestNode('A', log);
    final b = TestNode('B', log);
    final c = TestNode('C', log);
    final d = TestNode('D', log);
    b.priority = 1;
    c.priority = -1;
    d.priority = 1;
    a.add(b);
    a.add(c);
    a.add(d);
    a.mount();

    a.update(1);
    expect(log.updates, ['A', 'C', 'B', 'D']);

    _render(a);
    expect(log.renders, ['A', 'C', 'B', 'D']);
  });

  test('a disabled root skips update and render for itself and its subtree', () {
    final a = TestNode('A');
    final b = TestNode('B');
    a.add(b);
    final scene = a.mount();
    a.enabled = false;

    a.update(1);
    expect(a.updates, 0);
    expect(b.updates, 0);

    final recorder = PictureRecorder();
    scene.render(Canvas(recorder));
    expect(a.renders, 0);
    expect(b.renders, 0);
  });

  test(
    'a disabled child skips update and render for itself and its subtree, without affecting its siblings',
    () {
      final a = TestNode('A');
      final b = TestNode('B');
      final c = TestNode('C');
      a.add(b);
      a.add(c);
      a.mount();
      b.enabled = false;

      a.update(1);
      expect(b.updates, 0);
      expect(c.updates, 1);

      _render(a);
      expect(b.renders, 0);
      expect(c.renders, 1);
    },
  );

  test(
    'a child removed during an update still ticks that same pass, but is gone by the next flush',
    () {
      final log = TestLog();
      final a = TestNode('A', log);
      final b = TestNode('B', log);
      final c = TestNode('C', log);
      b.action = () => a.remove(c);
      a.add(b);
      a.add(c);
      final scene = a.mount();

      scene.update(1);
      expect(log.updates, ['A', 'B', 'C']);
      expect(a.children, [b, c]);
      log.updates.clear();

      scene.update(1);
      expect(log.updates, ['A', 'B']);
      expect(a.children, [b]);
    },
  );

  test('defers children added during an update until the next update', () {
    final log = TestLog();
    final a = TestNode('A', log);
    final b = TestNode('B', log);
    final c = TestNode('C', log);
    b.action = () => a.add(c);
    a.add(b);
    final scene = a.mount();

    scene.update(1);
    expect(log.updates, ['A', 'B']);
    log.updates.clear();

    scene.update(1);
    expect(log.updates, ['A', 'B', 'C']);
  });

  test('defers priority changes during an update until the next update', () {
    final log = TestLog();
    final a = TestNode('A', log);
    final b = TestNode('B', log);
    final c = TestNode('C', log);
    final d = TestNode('D', log);
    c.priority = 1;
    d.priority = 2;
    b.action = () => d.priority = -1;
    a.add(b);
    a.add(c);
    a.add(d);
    final scene = a.mount();

    scene.update(1);
    expect(log.updates, ['A', 'B', 'C', 'D']);
    log.updates.clear();

    scene.update(1);
    expect(log.updates, ['A', 'D', 'B', 'C']);
  });

  test('prevents reentrant removal', () {
    final a = Node();
    final b = Node();
    var calls = 0;
    b.onUnmount(() {
      calls += 1;
      b.detach();
    });
    a.add(b);
    final scene = a.mount();

    a.remove(b);
    scene.update(0);

    expect(calls, 1);
  });

  test('preserves children added during remove-all', () {
    final a = Node();
    final b = Node();
    final c = Node();
    final d = Node();
    b.onUnmount(() => a.add(d));
    a.add(b);
    a.add(c);
    final scene = a.mount();

    a.removeAll();
    scene.update(0);

    expect(a.children, [d]);
  });

  test('remove-all on an unmounted node removes every child immediately', () {
    final a = Node();
    final b = Node();
    final c = Node();
    a.add(b);
    a.add(c);

    a.removeAll();

    expect(a.children, isEmpty);
    expect(b.hasParent, isFalse);
    expect(c.hasParent, isFalse);
  });

  test('a node can be removed and re-added to a tree', () {
    final a = Node();
    final b = Node();
    a.add(b);
    a.remove(b);

    expect(b.parent, isNull);

    a.add(b);
    expect(a.children, [b]);

    expect(a.remove(b), isTrue);
    expect(b.parent, isNull);
  });

  test('propagates destroy listener failures while still detaching the node', () {
    final a = Node();
    final b = Node();
    b.onUnmount(() => throw StateError('Listener failed.'));
    a.add(b);
    final scene = a.mount();

    expect(a.remove(b), isTrue);
    expect(() => scene.update(0), throwsStateError);
    expect(b.parent, isNull);
  });

  test('node emits onUnmount before detaching', () {
    final parent = Node();
    final child = Node();
    parent.add(child);
    final scene = parent.mount();
    child.onUnmount(() => expect(parent, same(child.parent)));
    parent.remove(child);
    scene.update(0);
    expect(child.parent, isNull);
  });

  group('mounting', () {
    test('mounts a node and its subtree from the root downward', () {
      final log = TestLog();
      final a = TestNode('A', log);
      final b = TestNode('B', log);
      final c = TestNode('C', log);
      a.add(b);
      b.add(c);

      a.mount();

      expect(log.mounts, ['A', 'B', 'C']);
      expect(a.isMounted, isTrue);
      expect(b.isMounted, isTrue);
      expect(c.isMounted, isTrue);
    });

    test('unmounts a node and its subtree from the leaves upward', () {
      final log = TestLog();
      final a = TestNode('A', log);
      final b = TestNode('B', log);
      final c = TestNode('C', log);
      a.add(b);
      b.add(c);
      final scene = a.mount();

      scene.destroy();

      expect(log.unmounts, ['C', 'B', 'A']);
      expect(a.isMounted, isFalse);
      expect(b.isMounted, isFalse);
      expect(c.isMounted, isFalse);
    });

    test('adding a child to a mounted node mounts its whole subtree on the next flush', () {
      final log = TestLog();
      final a = TestNode('A', log);
      final b = TestNode('B', log);
      final c = TestNode('C', log);
      b.add(c);
      final scene = a.mount();

      a.add(b);
      expect(log.mounts, ['A']); // Not mounted yet — still pending.
      expect(b.isMounted, isFalse);

      scene.update(0);
      expect(log.mounts, ['A', 'B', 'C']);
      expect(b.isMounted, isTrue);
      expect(c.isMounted, isTrue);
    });

    test('removing a child from a mounted node unmounts its whole subtree on the next flush', () {
      final log = TestLog();
      final a = TestNode('A', log);
      final b = TestNode('B', log);
      final c = TestNode('C', log);
      a.add(b);
      b.add(c);
      final scene = a.mount();

      a.remove(b);
      expect(log.unmounts, isEmpty); // Not unmounted yet — still pending.
      expect(b.isMounted, isTrue);

      scene.update(0);
      expect(log.unmounts, ['C', 'B']);
      expect(b.isMounted, isFalse);
      expect(c.isMounted, isFalse);
    });

    test('nodes added to an unmounted tree are not mounted', () {
      final log = TestLog();
      final a = TestNode('A', log);
      final b = TestNode('B', log);
      a.add(b);

      expect(log.mounts, isEmpty);
      expect(a.isMounted, isFalse);
      expect(b.isMounted, isFalse);
    });

    test('mounting an already-mounted node is a no-op', () {
      final a = Node();
      var mounts = 0;
      a.onMount(() => mounts += 1);
      final scene = a.mount();

      final result = a.mount();

      expect(result, same(scene));
      expect(mounts, 1);
    });

    test('propagates the owning scene to the whole subtree once mounted', () {
      final a = Node();
      final b = Node();
      final c = Node();
      a.add(b);
      b.add(c);
      final scene = a.mount();

      expect(a.scene, same(scene));
      expect(b.scene, same(scene));
      expect(c.scene, same(scene));
    });

    test('clears the scene from the whole subtree once unmounted', () {
      final a = Node();
      final b = Node();
      a.add(b);
      final scene = a.mount();

      scene.destroy();

      expect(a.isMounted, isFalse);
      expect(b.isMounted, isFalse);
    });

    test('a node can be unmounted and remounted', () {
      final log = TestLog();
      final a = TestNode('A', log);
      final scene = a.mount();

      scene.destroy();
      final newScene = a.mount();

      expect(log.mounts, ['A', 'A']);
      expect(log.unmounts, ['A']);
      expect(a.isMounted, isTrue);
      expect(newScene, isNot(same(scene)));
    });
  });

  // Structural changes made from a signal handler firing mid-cascade (onMount
  // during a mount, onUnmount during an unmount) never touch _children
  // synchronously once mounted — they enqueue, same as any other post-mount
  // add()/remove(). That's what makes these safe: the cascade's own loop
  // never sees a collection mutated out from under it.
  group('reentrant mutation during mount/unmount', () {
    test('removing a sibling from onMount during a mount cascade defers the removal', () {
      final a = Node();
      final b = Node();
      final c = Node();
      a.add(b);
      a.add(c);
      b.onMount(() => a.remove(c));

      final scene = a.mount();
      // The removal was requested mid-cascade, but a.remove(c) only enqueues.
      // c still gets mounted this same pass.
      expect(c.isMounted, isTrue);

      scene.update(0);
      expect(c.isMounted, isFalse);
    });

    test('removing a sibling from onUnmount during an unmount cascade unmounts it once', () {
      final a = Node();
      final b = Node();
      final c = Node();
      a.add(b);
      a.add(c);
      final scene = a.mount();
      var cUnmounts = 0;
      c.onUnmount(() => cUnmounts += 1);
      b.onUnmount(() => a.remove(c));

      scene.destroy();
      expect(cUnmounts, 1);
    });

    test('adding a sibling from onMount during a mount cascade mounts it on the next flush', () {
      final a = Node();
      final b = Node();
      final d = Node();
      a.add(b);
      var dMounts = 0;
      d.onMount(() => dMounts += 1);
      b.onMount(() => a.add(d));

      final scene = a.mount();
      expect(dMounts, 0);

      scene.update(0);
      expect(dMounts, 1);
    });

    test(
      'a node can detach itself from within its own onMount, taking effect on the next flush',
      () {
        final a = Node();
        final b = Node();
        a.add(b);
        b.onMount(() => b.detach());

        final scene = a.mount();
        expect(b.parent, same(a));

        scene.update(0);
        expect(b.parent, isNull);
      },
    );

    test('reparenting from within onMount throws because the node still has a parent', () {
      final a = Node();
      final b = Node();
      final c = Node();
      a.add(b);
      Object? caught;

      b.onMount(() {
        try {
          c.add(b);
        } catch (error) {
          caught = error;
        }
      });

      a.mount();

      expect(caught, isStateError);
    });

    test('mounting a node reentrantly from within its own onMount is a no-op', () {
      final a = Node();
      var mounts = 0;

      a.onMount(() {
        mounts += 1;
        a.mount();
      });

      a.mount();

      expect(mounts, 1);
    });
  });
}

void _render(Node node) {
  final recorder = PictureRecorder();
  node.render(Canvas(recorder));
  recorder.endRecording();
}
