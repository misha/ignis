import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'package:flutter/foundation.dart';

import '../support/test_node.dart';

/// Runs [body] with error reporting captured instead of presented.
List<FlutterErrorDetails> _reported(void Function() body) {
  final reported = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = reported.add;

  try {
    body();
  } finally {
    FlutterError.onError = previous;
  }

  return reported;
}

/// Two distinguishable node types, for watching a declaration change shape.
final class _A extends Node {}

final class _B extends Node {}

void main() {
  group('builds', () {
    test('build runs on mount', () {
      final node = TestNode(builder: (_) {})..mount();

      expect(node.builds, 1);
    });

    test('a build that throws on mount throws out of mount', () {
      final node = TestNode(builder: (_) => throw StateError('no ancestor'));

      expect(node.mount, throwsStateError);
    });

    test('a build that throws on a live add throws out of update', () {
      final root = TestNode(builder: (_) {});
      final scene = root.mount();
      root.add(TestNode(builder: (_) => throw StateError('no ancestor')));

      expect(() => scene.update(0), throwsStateError);
    });
  });

  group('declaring', () {
    test('asserts on a tick before the node has built', () {
      expect(() => Node().tick((_) {}), throwsAssertionError);
    });

    test('asserts on a declaration once the build has returned', () {
      final node = TestNode()..mount();

      expect(() => node.tick((_) {}), throwsAssertionError);
      expect(() => node.draw((_) {}), throwsAssertionError);
      expect(() => node.debugDraw((_) {}), throwsAssertionError);
      expect(() => node.trash(() {}), throwsAssertionError);
    });

    test('asserts on a tick aimed at another node from a build', () {
      final child = Node();
      final parent = TestNode(builder: (_) => child.tick((_) {}));

      expect(parent.mount, throwsAssertionError);
    });
  });

  group('declarations', () {
    test('returns the node it was given, on every build', () {
      Node? given;
      Node? returned;

      final node = TestNode(
        builder: (n) {
          given = _A();
          returned = n.add(given!);
        },
      );

      node.mount().update(0);

      expect(returned, same(given));
      expect(node.children.single, same(given));
    });

    test('a remount replaces the children the previous build declared', () {
      final node = TestNode(builder: (n) => n.add(_A()));
      final root = Node(children: [node]);
      final scene = root.mount()..update(0);
      final first = node.children.single;

      root.remove(node);
      scene.update(0);
      root.add(node);
      scene.update(0);

      expect(first.isMounted, isFalse);
      expect(node.children.single, isNot(same(first)));
    });

    test('a remount into a new scene replaces the children the previous build declared', () {
      final node = TestNode(builder: (n) => n.add(_A()));
      final scene = node.mount()..update(0);
      final first = node.children.single;

      scene.destroy();
      node.mount().update(0);

      expect(first.isMounted, isFalse);
      expect(node.children.single, isNot(same(first)));
    });

    test('a remount leaves imperative additions alone', () {
      final node = TestNode(builder: (n) => n.add(_A()));
      final root = Node(children: [node]);
      final scene = root.mount()..update(0);
      final spawned = node.add(_B());
      scene.update(0);

      root.remove(node);
      scene.update(0);
      root.add(node);
      scene.update(0);

      expect(spawned.isMounted, isTrue, reason: 'no build declared it');
      expect(node.children, hasLength(2));
    });
  });

  group('onUpdate', () {
    test('runs its callback every update', () {
      var elapsed = 0.0;
      final scene = TestNode(builder: (node) => node.tick((dt) => elapsed += dt)).mount();

      scene.update(0.5);
      scene.update(0.5);

      expect(elapsed, 1);
    });
  });

  group('trash', () {
    test('empties at unmount', () {
      final log = <String>[];
      final scene = TestNode(builder: (node) => node.trash(() => log.add('cleaned'))).mount();

      scene.destroy();

      expect(log, ['cleaned']);
    });

    test('empties in reverse order', () {
      final log = <String>[];

      final scene = TestNode(
        builder: (node) {
          node.trash(() => log.add('a'));
          node.trash(() => log.add('b'));
          node.trash(() => log.add('c'));
        },
      ).mount();

      scene.destroy();

      expect(log, ['c', 'b', 'a']);
    });

    test('a throwing cleanup is reported and contained', () {
      final log = <String>[];

      final scene = TestNode(
        builder: (node) {
          node.trash(() => log.add('after'));
          node.trash(() => throw StateError('bad'));
        },
      ).mount();

      final reported = _reported(scene.destroy);

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
      expect(log, ['after'], reason: 'the rest still emptied');
    });
  });

  group('signals', () {
    test('a subscription made in build lives and dies with the node', () {
      final signal = Signal0();
      var emissions = 0;
      final node = TestNode(builder: (_) => signal(() => emissions += 1));
      final scene = node.mount();

      signal.emit();
      scene.destroy();
      signal.emit();

      expect(emissions, 1);
    });

    test('outside a build, the caller owns the subscription', () {
      final signal = Signal0();
      var emissions = 0;
      final cleanup = signal(() => emissions += 1);

      signal.emit();
      cleanup();
      signal.emit();

      expect(emissions, 1);
    });
  });
}
