import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/canvas.dart';
import '../support/test_entity.dart';

final class _Ping extends Message {
  const _Ping();
}

void main() {
  test('ignores duplicate child additions', () {
    final a = Entity();
    final b = Entity();
    a.add(b);

    expect(() => a.add(b), returnsNormally);
    expect(a.children, [b]);
  });

  test('moves a child to its new parent rather than sharing it', () {
    final a = Entity();
    final b = Entity();
    final c = Entity();
    a.add(c);

    b.add(c);

    expect(c.parent, same(b));
    expect(a.children, isEmpty);
    expect(b.children.single, same(c));
  });

  test('cannot own itself', () {
    final a = Entity();

    expect(() => a.add(a), throwsStateError);
  });

  test('lists ancestors and descendants in traversal order', () {
    final a = Entity();
    final b = Entity();
    final c = Entity();
    final d = Entity();
    a.add(b);
    a.add(c);
    b.add(d);

    expect(d.ancestors, [b, a]);
    expect(a.descendants, [b, d, c]);
  });

  test('orders children by priority while preserving insertion order for ties', () {
    final a = Entity();
    final b = Entity();
    final c = Entity();
    final d = Entity();
    b.priority = 1;
    c.priority = -1;
    d.priority = 1;
    a.add(b);
    a.add(c);
    a.add(d);

    expect(a.children, [c, b, d]);
  });

  test('reorders children when their priority changes', () {
    final a = Entity();
    final b = Entity();
    final c = Entity();
    final d = Entity();
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
    final a = TestEntity(name: 'A', log: log);
    final b = TestEntity(name: 'B', log: log);
    final c = TestEntity(name: 'C', log: log);
    final d = TestEntity(name: 'D', log: log);
    b.priority = 1;
    c.priority = -1;
    d.priority = 1;
    a.add(b);
    a.add(c);
    a.add(d);
    Scene(a);

    a.update(Update(1));
    expect(log.updates, ['A', 'C', 'B', 'D']);

    a.render(RecordingCanvas());
    expect(log.renders, ['A', 'C', 'B', 'D']);
  });

  test('a disabled root skips update and render for itself and its subtree', () {
    final a = TestEntity(name: 'A');
    final b = TestEntity(name: 'B');
    a.add(b);
    final scene = Scene(a);
    a.enabled = false;

    a.update(Update(1));
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
      final a = TestEntity(name: 'A');
      final b = TestEntity(name: 'B');
      final c = TestEntity(name: 'C');
      a.add(b);
      a.add(c);
      Scene(a);
      b.enabled = false;

      a.update(Update(1));
      expect(b.updates, 0);
      expect(c.updates, 1);

      a.render(RecordingCanvas());
      expect(b.renders, 0);
      expect(c.renders, 1);
    },
  );

  test('enable() and disable() set enabled', () {
    final a = TestEntity(name: 'A');

    a.disable();
    expect(a.enabled, isFalse);

    a.enable();
    expect(a.enabled, isTrue);
  });

  test(
    'a child removed during an update still ticks that same pass, but is gone by the next flush',
    () {
      final log = TestLog();
      final a = TestEntity(name: 'A', log: log);
      final b = TestEntity(name: 'B', log: log);
      final c = TestEntity(name: 'C', log: log);
      b.action = () => a.remove(c);
      a.add(b);
      a.add(c);
      final scene = Scene(a);

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
    final a = TestEntity(name: 'A', log: log);
    final b = TestEntity(name: 'B', log: log);
    final c = TestEntity(name: 'C', log: log);
    b.action = () {
      a.add(c);
      b.action = null;
    };

    a.add(b);
    final scene = Scene(a);

    scene.update(1);
    expect(log.updates, ['A', 'B']);

    log.updates.clear();

    scene.update(1);
    expect(log.updates, ['A', 'B', 'C']);
  });

  test('defers priority changes during an update until the next update', () {
    final log = TestLog();
    final a = TestEntity(name: 'A', log: log);
    final b = TestEntity(name: 'B', log: log);
    final c = TestEntity(name: 'C', log: log);
    final d = TestEntity(name: 'D', log: log);
    c.priority = 1;
    d.priority = 2;
    b.action = () => d.priority = -1;
    a.add(b);
    a.add(c);
    a.add(d);
    final scene = Scene(a);

    scene.update(1);
    expect(log.updates, ['A', 'B', 'C', 'D']);

    log.updates.clear();

    scene.update(1);
    expect(log.updates, ['A', 'D', 'B', 'C']);
  });

  test('prevents reentrant removal', () {
    final a = Entity();
    var calls = 0;

    final b = TestEntity(
      processor: (entity, event) {
        switch (event) {
          case Destroy():
            calls += 1;
            entity.detach();
        }
      },
    );

    a.add(b);
    final scene = Scene(a);
    a.remove(b);
    scene.update(0);

    expect(calls, 1);
  });

  test('preserves children added during remove-all', () {
    final a = Entity();
    final c = Entity();
    final d = Entity();
    final b = TestEntity(
      processor: (entity, event) {
        switch (event) {
          case Destroy():
            a.add(d);
        }
      },
    );

    a.add(b);
    a.add(c);
    final scene = Scene(a);
    a.removeAll();
    scene.update(0);

    expect(a.children, [d]);
  });

  test('remove-all on an unmounted entity removes every child immediately', () {
    final a = Entity();
    final b = Entity();
    final c = Entity();
    a.add(b);
    a.add(c);
    a.removeAll();

    expect(a.children, isEmpty);
    expect(b.hasParent, isFalse);
    expect(c.hasParent, isFalse);
  });

  test('an entity can be removed and re-added to a tree', () {
    final a = Entity();
    final b = Entity();
    a.add(b);
    a.remove(b);

    expect(b.parent, isNull);

    a.add(b);

    expect(a.children, [b]);

    a.remove(b);

    expect(b.parent, isNull);
  });

  test('entity tears down its build before detaching', () {
    final parent = Entity();
    Entity? seen;

    final child = TestEntity(
      processor: (entity, event) {
        switch (event) {
          case Destroy():
            seen = entity.parent;
        }
      },
    );

    parent.add(child);
    final scene = Scene(parent);

    parent.remove(child);
    scene.update(0);
    expect(seen, same(parent));
    expect(child.parent, isNull);
  });

  test('post processes the event on the entity', () {
    final processed = <Message>[];
    final entity = TestEntity(processor: (entity, event) => processed.add(event));
    const ping = _Ping();

    entity.post(ping);

    expect(processed, [ping]);
  });

  group('mounting', () {
    test('mounts an entity and its subtree from the root downward', () {
      final log = TestLog();
      final a = TestEntity(name: 'A', log: log);
      final b = TestEntity(name: 'B', log: log);
      final c = TestEntity(name: 'C', log: log);
      a.add(b);
      b.add(c);
      Scene(a);

      expect(log.mounts, ['A', 'B', 'C']);
      expect(a.isMounted, isTrue);
      expect(b.isMounted, isTrue);
      expect(c.isMounted, isTrue);
    });

    test('unmounts an entity and its subtree from the leaves upward', () {
      final log = TestLog();
      final a = TestEntity(name: 'A', log: log);
      final b = TestEntity(name: 'B', log: log);
      final c = TestEntity(name: 'C', log: log);
      a.add(b);
      b.add(c);
      final scene = Scene(a);
      scene.destroy();

      expect(log.unmounts, ['C', 'B', 'A']);
      expect(a.isMounted, isFalse);
      expect(b.isMounted, isFalse);
      expect(c.isMounted, isFalse);
    });

    test('adding a child to a mounted entity mounts its whole subtree on the next flush', () {
      final log = TestLog();
      final a = TestEntity(name: 'A', log: log);
      final b = TestEntity(name: 'B', log: log);
      final c = TestEntity(name: 'C', log: log);
      b.add(c);
      final scene = Scene(a);

      a.add(b);
      expect(log.mounts, ['A']);
      expect(b.isMounted, isFalse); // Still pending.

      scene.update(0);
      expect(log.mounts, ['A', 'B', 'C']);
      expect(b.isMounted, isTrue);
      expect(c.isMounted, isTrue);
    });

    test('removing a child from a mounted entity unmounts its whole subtree on the next flush', () {
      final log = TestLog();
      final a = TestEntity(name: 'A', log: log);
      final b = TestEntity(name: 'B', log: log);
      final c = TestEntity(name: 'C', log: log);
      a.add(b);
      b.add(c);
      final scene = Scene(a);

      a.remove(b);
      expect(log.unmounts, isEmpty);
      expect(b.isMounted, isTrue); // Still pending.

      scene.update(0);
      expect(log.unmounts, ['C', 'B']);
      expect(b.isMounted, isFalse);
      expect(c.isMounted, isFalse);
    });

    test('entities added to an unmounted tree are not mounted', () {
      final log = TestLog();
      final a = TestEntity(name: 'A', log: log);
      final b = TestEntity(name: 'B', log: log);
      a.add(b);

      expect(log.mounts, isEmpty);
      expect(a.isMounted, isFalse);
      expect(b.isMounted, isFalse);
    });

    test('mounting an already-mounted entity throws', () {
      final a = TestEntity();
      Scene(a);

      expect(() => Scene(a), throwsStateError);
    });

    test('propagates the owning scene to the whole subtree once mounted', () {
      final a = Entity();
      final b = Entity();
      final c = Entity();
      a.add(b);
      b.add(c);
      final scene = Scene(a);

      expect(a.scene, same(scene));
      expect(b.scene, same(scene));
      expect(c.scene, same(scene));
    });

    test('clears the scene from the whole subtree once unmounted', () {
      final a = Entity();
      final b = Entity();
      a.add(b);
      final scene = Scene(a);
      scene.destroy();

      expect(a.isMounted, isFalse);
      expect(b.isMounted, isFalse);
    });

    test('a removed entity is destroyed once the removal flushes', () {
      final a = Entity();
      final b = Entity();
      a.add(b);
      final scene = Scene(a);

      a.remove(b);
      expect(b.isDestroyed, isFalse);

      scene.update(0);
      expect(b.isDestroyed, isTrue);
    });

    test('adding a mounted entity throws, even to its own parent', () {
      final a = Entity();
      final b = Entity();
      final c = Entity();
      a.add(b);
      a.add(c);
      final scene = Scene(a);

      c.add(b);
      expect(() => scene.update(0), throwsStateError);

      a.add(b);
      expect(() => scene.update(0), throwsStateError);
    });

    test('adding a destroyed entity throws', () {
      final a = Entity();
      final b = Entity();
      a.add(b);
      final scene = Scene(a);
      a.remove(b);
      scene.update(0);
      a.add(b);

      expect(() => scene.update(0), throwsStateError);
    });

    test('mounting a destroyed entity throws', () {
      final a = Entity();
      Scene(a).destroy();

      expect(() => Scene(a), throwsStateError);
    });

    test('posting to a destroyed entity throws', () {
      final a = Entity();
      Scene(a).destroy();

      expect(() => a.post(const Build()), throwsAssertionError);
    });
  });

  group('reentrant mutation during mount/unmount', () {
    test('removing a sibling from a build during a mount cascade removes it', () {
      final a = Entity();
      final c = Entity();
      final b = TestEntity(builder: (_) => a.remove(c));
      a.add(b);
      a.add(c);
      final scene = Scene(a);

      scene.update(0);
      expect(c.hasParent, isFalse);
      expect(c.isMounted, isFalse);
    });

    test('removing a sibling from a teardown during an unmount cascade unmounts it once', () {
      final a = Entity();
      final c = TestEntity();
      final b = TestEntity(
        processor: (entity, event) {
          switch (event) {
            case Destroy():
              a.remove(c);
          }
        },
      );

      a.add(b);
      a.add(c);
      final scene = Scene(a);
      scene.destroy();
      expect(c.unmounts, 1);
    });

    test('adding a sibling from a build during a mount cascade mounts it on the next flush', () {
      final a = Entity();
      final d = TestEntity();
      final b = TestEntity(builder: (_) => a.add(d));
      a.add(b);

      final scene = Scene(a);
      expect(d.mounts, 0);

      scene.update(0);
      expect(d.mounts, 1);
    });

    test(
      'an entity can detach itself from within its own build, taking effect on the next flush',
      () {
        final a = Entity();
        final b = TestEntity(builder: (entity) => entity.detach());
        a.add(b);

        final scene = Scene(a);
        expect(b.parent, same(a));

        scene.update(0);
        expect(b.parent, isNull);
      },
    );

    test('mounting an entity reentrantly from within its own build throws', () {
      final a = TestEntity(builder: (entity) => Scene(entity));

      expect(() => Scene(a), throwsStateError);
    });
  });

  group('dependency injection', () {
    test('reads a value provided by the entity itself', () {
      final a = Entity();
      a.provide(42);
      Scene(a);

      expect(a.readOrNull<int>(), 42);
    });

    test('reads a value provided by an ancestor', () {
      final a = Entity();
      final b = Entity();
      final c = Entity();
      a.add(b);
      b.add(c);
      a.provide('hello');
      Scene(a);

      expect(c.readOrNull<String>(), 'hello');
    });

    test('prefers the nearest provider over one further up the tree', () {
      final a = Entity();
      final b = Entity();
      a.add(b);
      a.provide(1);
      b.provide(2);
      Scene(a);

      expect(b.readOrNull<int>(), 2);
    });

    test('overwrites a previously provided value of the same type', () {
      final a = Entity();
      a.provide(1);
      a.provide(2);
      Scene(a);

      expect(a.readOrNull<int>(), 2);
    });

    test('returns null when nothing has provided the requested type', () {
      final a = Entity();
      Scene(a);

      expect(a.readOrNull<int>(), isNull);
    });

    test('caches a hit, so a later provide of the same type is not picked up', () {
      final a = Entity();
      a.provide(1);
      Scene(a);
      expect(a.readOrNull<int>(), 1);

      a.provide(2);
      expect(a.readOrNull<int>(), 1);
    });

    test('caches a miss, so a later provide of the same type is not picked up', () {
      final a = Entity();
      Scene(a);
      expect(a.readOrNull<int>(), isNull);

      a.provide(1);
      expect(a.readOrNull<int>(), isNull);
    });

    test('throws when the entity is not mounted yet', () {
      final a = Entity();

      expect(() => a.readOrNull<int>(), throwsStateError);
    });

    test('clears a cached value when the entity is unmounted', () {
      final a = Entity();
      a.provide(1);
      final scene = Scene(a);
      expect(a.readOrNull<int>(), 1);

      scene.destroy();
      expect(() => a.readOrNull<int>(), throwsStateError);
    });

    test('read returns the value readOrNull finds, or throws when it finds none', () {
      final a = Entity();
      a.provide(1);
      Scene(a);
      expect(a.read<int>(), 1);

      final b = Entity();
      Scene(b);
      expect(() => b.read<int>(), throwsStateError);
    });
  });

  group('query', () {
    test('returns only the direct children of the queried type', () {
      final matching = TestEntity(name: 'a', log: TestLog());
      final other = Entity();
      final entity = Entity(children: [matching, other]);

      expect(entity.query<TestEntity>(), [matching]);
    });

    test('does not descend past a direct child', () {
      final buried = TestEntity(name: 'a', log: TestLog());
      final entity = Entity(
        children: [
          Entity(children: [buried]),
        ],
      );

      expect(entity.query<TestEntity>(), isEmpty);
    });

    test('matches by subtype, not exact runtime type', () {
      final entity = Entity(
        children: [TestEntity(name: 'a', log: TestLog())],
      );
      expect(entity.query<Entity>().length, 1);
    });

    test('picks up a child added after the first call', () {
      final entity = Entity();
      expect(entity.query<TestEntity>(), isEmpty);

      final added = TestEntity(name: 'a', log: TestLog());
      entity.add(added);
      expect(entity.query<TestEntity>(), [added]);
    });

    test('drops a child removed after the first call', () {
      final removed = TestEntity(name: 'a', log: TestLog());
      final entity = Entity(children: [removed]);
      expect(entity.query<TestEntity>(), [removed]);

      entity.remove(removed);
      expect(entity.query<TestEntity>(), isEmpty);
    });

    test('keeps results in priority order as children are added', () {
      final log = TestLog();
      final last = TestEntity(name: 'last', log: log)..priority = 10;
      final first = TestEntity(name: 'first', log: log)..priority = -10;
      final entity = Entity(children: [last]);

      // Registers the query before the lower-priority child exists, so an
      // append-only cache would put them in the wrong order.
      expect(entity.query<TestEntity>(), [last]);

      entity.add(first);
      expect(entity.query<TestEntity>(), [first, last]);
    });

    test('reorders results when a child changes priority', () {
      final log = TestLog();
      final a = TestEntity(name: 'a', log: log);
      final b = TestEntity(name: 'b', log: log);
      final entity = Entity(children: [a, b]);
      expect(entity.query<TestEntity>(), [a, b]);

      b.priority = -1;
      expect(entity.query<TestEntity>(), [b, a]);
    });

    test('returns the same live view on every call', () {
      final entity = Entity();
      final first = entity.query<TestEntity>();
      final added = TestEntity(name: 'a', log: TestLog());

      entity.add(added);
      expect(first, [added]);
      expect(entity.query<TestEntity>(), same(first));
    });
  });

  group('activity', () {
    test('rendering alone paints without ticking', () {
      final entity = TestEntity()..activity = .render;
      final scene = Scene(entity);

      scene.update(1);
      scene.render(RecordingCanvas());
      expect(entity.updates, 0);
      expect(entity.renders, 1);
    });

    test('enabled means all three', () {
      final entity = TestEntity()..activity = .render;
      expect(entity.enabled, isFalse);

      entity.enabled = true;
      expect(entity.activity, Activity.all);
    });
  });
}
