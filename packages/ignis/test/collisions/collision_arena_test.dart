import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_node.dart';
import '../support/test_sink.dart';

void main() {
  late CollisionArena arena;

  setUp(() {
    arena = CollisionArena();
  });

  group('overlap detection', () {
    test('does not fire CollisionStart when x-intervals do not overlap', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(100, 0));
      final aSink = TestSink([a]);

      arena
        ..add(a)
        ..add(b)
        ..process();

      expect(aSink.of<CollisionStart>(), isEmpty);
    });

    test('fires CollisionStart on both colliders whose x- and y-intervals overlap', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final aSink = TestSink([a]);
      final bSink = TestSink([b]);

      arena
        ..add(a)
        ..add(b)
        ..process();

      expect(aSink.of<CollisionStart>().single.other, b);
      expect(bSink.of<CollisionStart>().single.other, a);
    });

    test('excludes a pair whose x-intervals overlap but y-intervals do not', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 100));
      final aSink = TestSink([a]);

      arena
        ..add(a)
        ..add(b)
        ..process();

      expect(aSink.of<CollisionStart>(), isEmpty);
    });

    test('excludes a pair whose AABBs overlap but whose shapes do not', () {
      final a = ColliderNode(shape: .circle(4), position: .zero);
      final b = ColliderNode(shape: .circle(4), position: .all(7));
      final aSink = TestSink([a]);

      // a's AABB spans [-4, 4] on both axes, b's spans [3, 11], so they
      // overlap in the corner - but the circles themselves, ~9.9 apart
      // against a combined radius of 8, do not.
      arena
        ..add(a)
        ..add(b)
        ..process();

      expect(aSink.of<CollisionStart>(), isEmpty);
    });

    test('short-circuits past a collider whose x-interval is far away', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final c = ColliderNode(shape: .square(10), position: .new(100, 0));
      final aSink = TestSink([a]);
      final cSink = TestSink([c]);

      arena
        ..add(a)
        ..add(b)
        ..add(c)
        ..process();

      expect(aSink.of<CollisionStart>().single.other, b);
      expect(cSink.of<CollisionStart>(), isEmpty);
    });

    test('fires CollisionStart for every overlapping combination, however many colliders', () {
      final a = ColliderNode(shape: .circle(4), position: .zero);
      final b = ColliderNode(shape: .circle(4), position: .new(1, 0));
      final c = ColliderNode(shape: .circle(4), position: .new(2, 0));
      final sink = TestSink([a, b, c]);

      arena
        ..add(a)
        ..add(b)
        ..add(c)
        ..process();

      // 3 overlapping pairs, 2 emissions each.
      expect(sink.of<CollisionStart>(), hasLength(6));
    });

    test('does not re-fire CollisionStart for a still-overlapping pair across ticks', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final aSink = TestSink([a]);

      arena
        ..add(a)
        ..add(b)
        ..process()
        ..process();

      expect(aSink.of<CollisionStart>(), hasLength(1));
    });

    test('fires CollisionEnd on both colliders when a pair stops overlapping', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final aSink = TestSink([a]);
      final bSink = TestSink([b]);
      CollisionArenaNode(arena: arena, children: [aSink, bSink]).mount();

      arena.process();

      a.position.x = 200;
      arena.process();

      expect(aSink.of<CollisionEnd>().single.other, b);
      expect(bSink.of<CollisionEnd>().single.other, a);
    });

    test('does not fire CollisionEnd for a pair that never overlapped', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(100, 0));
      final aSink = TestSink([a]);
      CollisionArenaNode(arena: arena, children: [aSink, b]).mount();

      arena
        ..process()
        ..process();

      expect(aSink.of<CollisionEnd>(), isEmpty);
    });

    test('does not fire CollisionEnd for a pair with a detached member', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final bSink = TestSink([b]);
      final scene = CollisionArenaNode(arena: arena, children: [a, bSink]).mount();

      arena.process();

      // a's pair with b drops out because a was unregistered, not because they
      // separated. Detaching while mounted queues the removal, so an update is
      // needed.
      a.detach();
      scene.update(0);
      arena.process();

      expect(bSink.of<CollisionEnd>(), isEmpty);
    });
  });

  group('collisions / isColliding', () {
    test('adds the other collider to active while overlapping', () {
      final a = ColliderNode(shape: .square(10));
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      CollisionArenaNode(arena: arena, children: [a, b]).mount();

      arena.process();

      expect(a.collisions, {b});
      expect(b.collisions, {a});
      expect(a.isColliding, isTrue);
      expect(b.isColliding, isTrue);
    });

    test('removes the other collider from active once they stop overlapping', () {
      final a = ColliderNode(shape: .square(10));
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      CollisionArenaNode(arena: arena, children: [a, b]).mount();

      arena.process();

      a.position.x = 200;
      arena.process();

      expect(a.collisions, isEmpty);
      expect(b.collisions, isEmpty);
      expect(a.isColliding, isFalse);
      expect(b.isColliding, isFalse);
    });

    test(
      'drops a detached partner from the survivor\'s active set without firing CollisionEnd',
      () {
        final a = ColliderNode(shape: .square(10));
        final b = ColliderNode(shape: .square(10), position: .new(6, 0));
        final bSink = TestSink([b]);
        final scene = CollisionArenaNode(arena: arena, children: [a, bSink]).mount();

        arena.process();

        a.detach();
        scene.update(0);
        arena.process();

        expect(bSink.of<CollisionEnd>(), isEmpty);
        expect(b.collisions, isEmpty);
        expect(b.isColliding, isFalse);
      },
    );

    test('holds the other collider in active already inside CollisionStart', () {
      final a = ColliderNode(shape: .square(10));
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final seen = <int>[];

      final parent = TestNode(
        processor: (_, event) {
          if (event is! CollisionStart) return;
          seen.add(a.collisions.length);
        },
        children: [a],
      );

      CollisionArenaNode(arena: arena, children: [parent, b]).mount();

      arena.process();

      expect(seen, [1]);
    });

    test('has dropped the other collider from active already inside CollisionEnd', () {
      final a = ColliderNode(shape: .square(10));
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final colliding = <bool>[];

      final parent = TestNode(
        processor: (_, event) {
          if (event is! CollisionEnd) return;
          colliding.add(a.isColliding);
        },
        children: [a],
      );

      CollisionArenaNode(arena: arena, children: [parent, b]).mount();

      arena.process();

      a.position.x = 200;
      arena.process();

      expect(colliding, [false]);
    });

    test('clears active when this collider itself is unmounted', () {
      final a = ColliderNode(shape: .square(10));
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final scene = CollisionArenaNode(arena: arena, children: [a, b]).mount();

      arena.process();

      expect(a.collisions, isNotEmpty);

      a.detach();
      scene.update(0);

      expect(a.collisions, isEmpty);
    });
  });

  group('pair identity', () {
    test('does not re-fire CollisionStart after a sweep-order swap', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final aSink = TestSink([a]);

      arena
        ..add(a)
        ..add(b)
        ..process();

      // a's x-min now exceeds b's, so the two swap places in sweep order,
      // but they're still overlapping and must not be treated as a new pair.
      a.position.x = 10;
      arena.process();

      expect(aSink.of<CollisionStart>(), hasLength(1));
    });

    test('re-fires CollisionStart after a pair stops and resumes overlapping', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final aSink = TestSink([a]);

      arena
        ..add(a)
        ..add(b)
        ..process();

      a.position.x = 200;
      arena.process();

      a.position.x = 0;
      arena.process();

      expect(aSink.of<CollisionStart>(), hasLength(2));
    });

    test('does not treat a different pair sharing a reused key as a continuation', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));

      arena
        ..add(a)
        ..add(b)
        ..process();

      arena.remove(a);

      // c reuses a's freed slot (the free list is LIFO) and occupies the
      // same position, so the pair key it forms with b is identical to
      // the one a and b used to share.
      final c = ColliderNode(shape: .square(10), position: .zero);
      final cSink = TestSink([c]);

      arena
        ..add(c)
        ..process();

      expect(cSink.of<CollisionStart>().single.other, b);
    });
  });

  group('add/remove', () {
    test('omits a removed collider from further processing', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final bSink = TestSink([b]);

      arena
        ..add(a)
        ..add(b);

      arena.remove(a);
      arena.process();

      expect(bSink.of<CollisionStart>(), isEmpty);
    });

    test('asserts against adding an already-registered collider twice', () {
      final a = ColliderNode(shape: .square(10), position: .zero);

      arena.add(a);

      expect(() => arena.add(a), throwsAssertionError);
    });

    test('a collider added after an initial process participates in the very next process', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final aSink = TestSink([a]);

      arena
        ..add(a)
        ..process();

      final b = ColliderNode(shape: .square(10), position: .new(6, 0));

      arena
        ..add(b)
        ..process();

      expect(aSink.of<CollisionStart>().single.other, b);
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

      final aSink = TestSink([a]);

      // a spans x[-5, 5]. b's centerRight anchor pulls its shape to
      // x[-1, 9], which reaches a.
      arena
        ..add(a)
        ..add(b)
        ..process();

      expect(aSink.of<CollisionStart>().single.other, b);
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

      final aSink = TestSink([a]);

      // a spans x[-5, 5]. b's centerLeft anchor pushes its shape to
      // x[9, 19], out of reach of a.
      arena
        ..add(a)
        ..add(b)
        ..process();

      expect(aSink.of<CollisionStart>(), isEmpty);
    });
  });

  group('layers and masks', () {
    test(
      'does not fire CollisionStart on either side when neither mask matches the other layer',
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

        final aSink = TestSink([a]);
        final bSink = TestSink([b]);

        arena
          ..add(a)
          ..add(b)
          ..process();

        expect(aSink.of<CollisionStart>(), isEmpty);
        expect(bSink.of<CollisionStart>(), isEmpty);
      },
    );

    test('fires CollisionStart only on the side whose mask matches the other layer', () {
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

      final aSink = TestSink([a]);
      final bSink = TestSink([b]);

      arena
        ..add(a)
        ..add(b)
        ..process();

      expect(aSink.of<CollisionStart>().single.other, b);
      expect(bSink.of<CollisionStart>(), isEmpty);
    });

    test('fires CollisionEnd only on the side whose mask matches the other layer', () {
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

      final aSink = TestSink([a]);
      final bSink = TestSink([b]);
      CollisionArenaNode(arena: arena, children: [aSink, bSink]).mount();

      arena.process();

      a.position.x = 200;
      arena.process();

      expect(aSink.of<CollisionEnd>().single.other, b);
      expect(bSink.of<CollisionEnd>(), isEmpty);
    });
  });

  group('shapes', () {
    test('circle-circle hits', () {
      final a = ColliderNode(shape: .circle(4), position: .zero);
      final b = ColliderNode(shape: .circle(4), position: .new(2, 0));
      final aSink = TestSink([a]);

      arena
        ..add(a)
        ..add(b)
        ..process();

      expect(aSink.of<CollisionStart>().single.other, b);
    });

    test('rectangle-rectangle hits', () {
      final a = ColliderNode(shape: .square(10), position: .zero);
      final b = ColliderNode(shape: .square(10), position: .new(6, 0));
      final aSink = TestSink([a]);

      arena
        ..add(a)
        ..add(b)
        ..process();

      expect(aSink.of<CollisionStart>().single.other, b);
    });

    test('circle-rectangle hits', () {
      final a = ColliderNode(shape: .circle(4), position: .zero);
      final b = ColliderNode(shape: .square(6), position: .all(2));
      final aSink = TestSink([a]);

      arena
        ..add(a)
        ..add(b)
        ..process();

      expect(aSink.of<CollisionStart>().single.other, b);
    });

    test('rectangle-circle hits', () {
      final a = ColliderNode(shape: .square(6), position: .zero);
      final b = ColliderNode(shape: .circle(4), position: .all(2));
      final aSink = TestSink([a]);

      arena
        ..add(a)
        ..add(b)
        ..process();

      expect(aSink.of<CollisionStart>().single.other, b);
    });
  });
}
