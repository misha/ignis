import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_node.dart';

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

  test('reassembles children in priority order', () {
    final log = TestLog();
    final a = TestNode('A', log);
    final b = TestNode('B', log);
    final c = TestNode('C', log);
    final d = TestNode('D', log);
    b.priority = 1;
    c.priority = -1;
    a.add(b);
    a.add(c);
    b.add(d);
    final scene = a.mount();
    log.builds.clear();

    scene.reassemble();
    expect(log.builds, ['A', 'C', 'B', 'D']);
  });

  test('reassembles disabled nodes, unlike update and render', () {
    final a = TestNode('A');
    final b = TestNode('B');
    final c = TestNode('C');
    a.add(b);
    b.add(c);
    final scene = a.mount();
    b.enabled = false;

    scene.reassemble();

    expect(b.builds, 2);
    expect(c.builds, 2, reason: 'the walk stopped at a disabled node');
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

  test('enable() and disable() set enabled', () {
    final a = TestNode('A');

    a.disable();
    expect(a.enabled, isFalse);

    a.enable();
    expect(a.enabled, isTrue);
  });

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
      expect(log.mounts, ['A']);
      expect(b.isMounted, isFalse); // Still pending.

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
      expect(log.unmounts, isEmpty);
      expect(b.isMounted, isTrue); // Still pending.

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

  group('dependency injection', () {
    test('reads a value provided by the node itself', () {
      final a = Node();
      a.provide(42);
      a.mount();

      expect(a.readOrNull<int>(), 42);
    });

    test('reads a value provided by an ancestor', () {
      final a = Node();
      final b = Node();
      final c = Node();
      a.add(b);
      b.add(c);
      a.provide('hello');
      a.mount();

      expect(c.readOrNull<String>(), 'hello');
    });

    test('prefers the nearest provider over one further up the tree', () {
      final a = Node();
      final b = Node();
      a.add(b);
      a.provide(1);
      b.provide(2);
      a.mount();

      expect(b.readOrNull<int>(), 2);
    });

    test('overwrites a previously provided value of the same type', () {
      final a = Node();
      a.provide(1);
      a.provide(2);
      a.mount();

      expect(a.readOrNull<int>(), 2);
    });

    test('returns null when nothing has provided the requested type', () {
      final a = Node();
      a.mount();

      expect(a.readOrNull<int>(), isNull);
    });

    test('caches a hit, so a later provide of the same type is not picked up', () {
      final a = Node();
      a.provide(1);
      a.mount();
      expect(a.readOrNull<int>(), 1);

      a.provide(2);
      expect(a.readOrNull<int>(), 1);
    });

    test('caches a miss, so a later provide of the same type is not picked up', () {
      final a = Node();
      a.mount();
      expect(a.readOrNull<int>(), isNull);

      a.provide(1);
      expect(a.readOrNull<int>(), isNull);
    });

    test('throws when the node is not mounted yet', () {
      final a = Node();

      expect(() => a.readOrNull<int>(), throwsStateError);
    });

    test('clears a cached value when the node is unmounted', () {
      final a = Node();
      a.provide(1);
      final scene = a.mount();
      expect(a.readOrNull<int>(), 1);

      scene.destroy();
      expect(() => a.readOrNull<int>(), throwsStateError);
    });

    test('resolves anew after an unmount/remount cycle', () {
      final parent = Node();
      final child = Node();
      parent.provide(1);
      parent.add(child);
      final scene = parent.mount();
      expect(child.readOrNull<int>(), 1);

      scene.destroy();
      parent.provide(2);
      parent.mount();

      expect(child.readOrNull<int>(), 2);
    });

    test('read returns the value readOrNull finds, or throws when it finds none', () {
      final a = Node();
      a.provide(1);
      a.mount();
      expect(a.read<int>(), 1);

      final b = Node();
      b.mount();
      expect(() => b.read<int>(), throwsStateError);
    });
  });

  group('query', () {
    test('returns only the direct children of the queried type', () {
      final matching = TestNode('a', TestLog());
      final other = Node();
      final node = Node(children: [matching, other]);

      expect(node.query<TestNode>(), [matching]);
    });

    test('does not descend past a direct child', () {
      final buried = TestNode('a', TestLog());
      final node = Node(
        children: [
          Node(children: [buried]),
        ],
      );

      expect(node.query<TestNode>(), isEmpty);
    });

    test('matches by subtype, not exact runtime type', () {
      final node = Node(children: [TestNode('a', TestLog())]);
      expect(node.query<Node>().length, 1);
    });

    test('picks up a child added after the first call', () {
      final node = Node();
      expect(node.query<TestNode>(), isEmpty);

      final added = TestNode('a', TestLog());
      node.add(added);
      expect(node.query<TestNode>(), [added]);
    });

    test('drops a child removed after the first call', () {
      final removed = TestNode('a', TestLog());
      final node = Node(children: [removed]);
      expect(node.query<TestNode>(), [removed]);

      node.remove(removed);
      expect(node.query<TestNode>(), isEmpty);
    });

    test('keeps results in priority order as children are added', () {
      final log = TestLog();
      final last = TestNode('last', log)..priority = 10;
      final first = TestNode('first', log)..priority = -10;
      final node = Node(children: [last]);

      // Registers the query before the lower-priority child exists, so an
      // append-only cache would put them in the wrong order.
      expect(node.query<TestNode>(), [last]);

      node.add(first);
      expect(node.query<TestNode>(), [first, last]);
    });

    test('reorders results when a child changes priority', () {
      final log = TestLog();
      final a = TestNode('a', log);
      final b = TestNode('b', log);
      final node = Node(children: [a, b]);
      expect(node.query<TestNode>(), [a, b]);

      b.priority = -1;
      expect(node.query<TestNode>(), [b, a]);
    });

    test('returns the same live view on every call', () {
      final node = Node();
      final first = node.query<TestNode>();
      final added = TestNode('a', TestLog());

      node.add(added);
      expect(first, [added]);
      expect(node.query<TestNode>(), same(first));
    });
  });
}

void _render(Node node) {
  final recorder = PictureRecorder();
  node.render(Canvas(recorder));
  recorder.endRecording();
}
