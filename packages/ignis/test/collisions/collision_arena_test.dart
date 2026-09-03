import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  late CollisionArena arena;

  setUp(() {
    arena = CollisionArena();
  });

  group('overlap detection', () {
    test('does not fire onCollisionStart when x-intervals do not overlap', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(100, 0));
      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      arena
        ..add(a)
        ..add(b)
        ..process(0);

      expect(aStarted, isEmpty);
    });

    test('fires onCollisionStart on both colliders whose x- and y-intervals overlap', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final aStarted = <ColliderNode>[];
      final bStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);
      b.onCollisionStart(bStarted.add);

      arena
        ..add(a)
        ..add(b)
        ..process(0);

      expect(aStarted, [b]);
      expect(bStarted, [a]);
    });

    test('excludes a pair whose x-intervals overlap but y-intervals do not', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 100));
      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      arena
        ..add(a)
        ..add(b)
        ..process(0);

      expect(aStarted, isEmpty);
    });

    test('excludes a pair whose AABBs overlap but whose shapes do not', () {
      final a = ColliderNode(shape: .circle(4), position: .zero);
      final b = ColliderNode(shape: .circle(4), position: .all(7));
      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      // a's AABB spans [-4, 4] on both axes, b's spans [3, 11], so they
      // overlap in the corner - but the circles themselves, ~9.9 apart
      // against a combined radius of 8, do not.
      arena
        ..add(a)
        ..add(b)
        ..process(0);

      expect(aStarted, isEmpty);
    });

    test('short-circuits past a collider whose x-interval is far away', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final c = ColliderNode(shape: .square(10), position: .new(100, 0));
      final aStarted = <ColliderNode>[];
      final cStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);
      c.onCollisionStart(cStarted.add);

      arena
        ..add(a)
        ..add(b)
        ..add(c)
        ..process(0);

      expect(aStarted, [b]);
      expect(cStarted, isEmpty);
    });

    test('fires onCollisionStart for every overlapping combination, however many colliders', () {
      final a = ColliderNode(shape: .circle(4), position: .zero);
      final b = ColliderNode(shape: .circle(4), position: .new(1, 0));
      final c = ColliderNode(shape: .circle(4), position: .new(2, 0));
      final started = <ColliderNode>[];
      a.onCollisionStart(started.add);
      b.onCollisionStart(started.add);
      c.onCollisionStart(started.add);

      arena
        ..add(a)
        ..add(b)
        ..add(c)
        ..process(0);

      // 3 overlapping pairs, 2 signal emissions each.
      expect(started, hasLength(6));
    });

    test('does not re-fire onCollisionStart for a still-overlapping pair across ticks', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      arena
        ..add(a)
        ..add(b)
        ..process(0)
        ..process(0);

      expect(aStarted, hasLength(1));
    });

    test('fires onCollisionEnd on both colliders when a pair stops overlapping', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      CollisionArenaNode(arena: arena, children: [a, b]).mount();
      final aEnded = <ColliderNode>[];
      final bEnded = <ColliderNode>[];
      a.onCollisionEnd(aEnded.add);
      b.onCollisionEnd(bEnded.add);

      arena.process(0);

      a.position.x = 200;
      arena.process(0);

      expect(aEnded, [b]);
      expect(bEnded, [a]);
    });

    test('does not fire onCollisionEnd for a pair that never overlapped', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(100, 0));
      CollisionArenaNode(arena: arena, children: [a, b]).mount();
      final aEnded = <ColliderNode>[];
      a.onCollisionEnd(aEnded.add);

      arena
        ..process(0)
        ..process(0);

      expect(aEnded, isEmpty);
    });

    test('does not fire onCollisionEnd for a pair with a detached member', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final scene = CollisionArenaNode(arena: arena, children: [a, b]).mount();

      arena.process(0);

      final bEnded = <ColliderNode>[];
      b.onCollisionEnd(bEnded.add);

      // a's pair with b drops out because a was unregistered (detached),
      // not because it genuinely drifted apart. Detaching while mounted only
      // queues the removal, so it needs an update to actually take effect.
      a.detach();
      scene.update(0);
      arena.process(0);

      expect(bEnded, isEmpty);
    });
  });

  group('active / isColliding', () {
    test('adds the other collider to active while overlapping', () {
      final a = ColliderNode(shape: .square(10));
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      CollisionArenaNode(arena: arena, children: [a, b]).mount();

      arena.process(0);

      expect(a.active, {b});
      expect(b.active, {a});
      expect(a.isColliding, isTrue);
      expect(b.isColliding, isTrue);
    });

    test('removes the other collider from active once they stop overlapping', () {
      final a = ColliderNode(shape: .square(10));
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      CollisionArenaNode(arena: arena, children: [a, b]).mount();

      arena.process(0);

      a.position.x = 200;
      arena.process(0);

      expect(a.active, isEmpty);
      expect(b.active, isEmpty);
      expect(a.isColliding, isFalse);
      expect(b.isColliding, isFalse);
    });

    test(
      'drops a detached partner from the survivor\'s active set without firing onCollisionEnd',
      () {
        final a = ColliderNode(shape: .square(10));
        final b = ColliderNode(shape: .square(10), position: .new(6, 0));
        final scene = CollisionArenaNode(arena: arena, children: [a, b]).mount();

        arena.process(0);

        final bEnded = <ColliderNode>[];
        b.onCollisionEnd(bEnded.add);

        a.detach();
        scene.update(0);
        arena.process(0);

        expect(bEnded, isEmpty);
        expect(b.active, isEmpty);
        expect(b.isColliding, isFalse);
      },
    );

    test('holds the other collider in active already inside onCollisionStart', () {
      final a = ColliderNode(shape: .square(10));
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final seen = <int>[];

      // Subscribed before the collider builds, so this handler runs ahead of
      // any the node declares for itself.
      a.onCollisionStart((_) {
        seen.add(a.active.length);
      });

      CollisionArenaNode(arena: arena, children: [a, b]).mount();

      arena.process(0);

      expect(seen, [1]);
    });

    test('has dropped the other collider from active already inside onCollisionEnd', () {
      final a = ColliderNode(shape: .square(10));
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final colliding = <bool>[];

      a.onCollisionEnd((_) {
        colliding.add(a.isColliding);
      });

      CollisionArenaNode(arena: arena, children: [a, b]).mount();

      arena.process(0);

      a.position.x = 200;
      arena.process(0);

      expect(colliding, [false]);
    });

    test('clears active when this collider itself is unmounted', () {
      final a = ColliderNode(shape: .square(10));
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final scene = CollisionArenaNode(arena: arena, children: [a, b]).mount();

      arena.process(0);

      expect(a.active, isNotEmpty);

      a.detach();
      scene.update(0);

      expect(a.active, isEmpty);
    });
  });

  group('pair identity', () {
    test('does not re-fire onCollisionStart after a sweep-order swap', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      arena
        ..add(a)
        ..add(b)
        ..process(0);

      // a's x-min now exceeds b's, so the two swap places in sweep order,
      // but they're still overlapping and must not be treated as a new pair.
      a.position.x = 10;
      arena.process(0);

      expect(aStarted, hasLength(1));
    });

    test('re-fires onCollisionStart after a pair stops and resumes overlapping', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      arena
        ..add(a)
        ..add(b)
        ..process(0);

      a.position.x = 200;
      arena.process(0);

      a.position.x = 0;
      arena.process(0);

      expect(aStarted, hasLength(2));
    });

    test('does not treat a different pair sharing a reused key as a continuation', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));

      arena
        ..add(a)
        ..add(b)
        ..process(0);

      arena.remove(a);

      // c reuses a's freed slot (the free list is LIFO) and occupies the
      // same position, so the pair key it forms with b is identical to
      // the one a and b used to share.
      final c = ColliderNode(shape: .square(10), position: .zero);
      final cStarted = <ColliderNode>[];
      c.onCollisionStart(cStarted.add);

      arena
        ..add(c)
        ..process(0);

      expect(cStarted, [b]);
    });
  });

  group('add/remove', () {
    test('omits a removed collider from further processing', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final bStarted = <ColliderNode>[];
      b.onCollisionStart(bStarted.add);

      arena
        ..add(a)
        ..add(b);

      arena.remove(a);
      arena.process(0);

      expect(bStarted, isEmpty);
    });

    test('asserts against adding an already-registered collider twice', () {
      final a = ColliderNode(shape: .square(10), position: .zero);

      arena.add(a);

      expect(() => arena.add(a), throwsAssertionError);
    });

    test('a collider added after an initial process participates in the very next process', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      arena
        ..add(a)
        ..process(0);

      final b = ColliderNode(shape: .square(10), position: .new(6, 0));

      arena
        ..add(b)
        ..process(0);

      expect(aStarted, [b]);
    });
  });

  group('anchor', () {
    test('shifts a collider into overlap', () {
      final a = ColliderNode(
        shape: .square(10),
        position: .zero,
        anchor: .center,
      );

      final b = ColliderNode(
        shape: .square(10),
        position: .new(9, 0),
        anchor: .centerRight,
      );

      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      // a spans x[-5, 5]. b's centerRight anchor pulls its shape to
      // x[-1, 9], which reaches a.
      arena
        ..add(a)
        ..add(b)
        ..process(0);

      expect(aStarted, [b]);
    });

    test('shifts a collider out of overlap', () {
      final a = ColliderNode(
        shape: .square(10),
        position: .zero,
        anchor: .center,
      );

      final b = ColliderNode(
        shape: .square(10),
        position: .new(9, 0),
        anchor: .centerLeft,
      );

      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      // a spans x[-5, 5]. b's centerLeft anchor pushes its shape to
      // x[9, 19], out of reach of a.
      arena
        ..add(a)
        ..add(b)
        ..process(0);

      expect(aStarted, isEmpty);
    });
  });

  group('layers and masks', () {
    test(
      'does not fire onCollisionStart on either side when neither mask matches the other layer',
      () {
        final a = ColliderNode(
          shape: .square(10),
          position: .zero,
          layer: 1,
          mask: 2,
        );

        final b = ColliderNode(
          shape: .square(10),
          position: .new(6, 0),
          layer: 4,
          mask: 8,
        );

        final aStarted = <ColliderNode>[];
        final bStarted = <ColliderNode>[];
        a.onCollisionStart(aStarted.add);
        b.onCollisionStart(bStarted.add);

        arena
          ..add(a)
          ..add(b)
          ..process(0);

        expect(aStarted, isEmpty);
        expect(bStarted, isEmpty);
      },
    );

    test('fires onCollisionStart only on the side whose mask matches the other layer', () {
      final a = ColliderNode(
        shape: .square(10),
        position: .zero,
        layer: 1,
        mask: 2,
      );

      final b = ColliderNode(
        shape: .square(10),
        position: .new(6, 0),
        layer: 2,
        mask: 0,
      );

      final aStarted = <ColliderNode>[];
      final bStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);
      b.onCollisionStart(bStarted.add);

      arena
        ..add(a)
        ..add(b)
        ..process(0);

      expect(aStarted, [b]);
      expect(bStarted, isEmpty);
    });

    test('fires onCollisionEnd only on the side whose mask matches the other layer', () {
      final a = ColliderNode(
        shape: .square(10),
        position: .zero,
        layer: 1,
        mask: 2,
      );

      final b = ColliderNode(
        shape: .square(10),
        position: .new(6, 0),
        layer: 2,
        mask: 0,
      );

      CollisionArenaNode(arena: arena, children: [a, b]).mount();
      final aEnded = <ColliderNode>[];
      final bEnded = <ColliderNode>[];
      a.onCollisionEnd(aEnded.add);
      b.onCollisionEnd(bEnded.add);

      arena.process(0);

      a.position.x = 200;
      arena.process(0);

      expect(aEnded, [b]);
      expect(bEnded, isEmpty);
    });
  });

  group('shapes', () {
    test('circle-circle hits', () {
      final a = ColliderNode(shape: .circle(4), position: .zero);
      final b = ColliderNode(shape: .circle(4), position: .new(2, 0));
      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      arena
        ..add(a)
        ..add(b)
        ..process(0);

      expect(aStarted, [b]);
    });

    test('rectangle-rectangle hits', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      arena
        ..add(a)
        ..add(b)
        ..process(0);

      expect(aStarted, [b]);
    });

    test('circle-rectangle hits', () {
      final a = ColliderNode(shape: .circle(4), position: .zero);
      final b = ColliderNode(shape: .square(6), position: .all(2));
      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      arena
        ..add(a)
        ..add(b)
        ..process(0);

      expect(aStarted, [b]);
    });

    test('rectangle-circle hits', () {
      final a = ColliderNode(shape: .square(6), position: .zero);
      final b = ColliderNode(shape: .circle(4), position: .all(2));
      final aStarted = <ColliderNode>[];
      a.onCollisionStart(aStarted.add);

      arena
        ..add(a)
        ..add(b)
        ..process(0);

      expect(aStarted, [b]);
    });
  });
}
