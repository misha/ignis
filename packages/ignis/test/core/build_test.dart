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

  group('update', () {
    test('runs every update', () {
      var elapsed = 0.0;

      final scene = TestNode(
        processor: (node, state) {
          switch (state) {
            case Update(:final dt):
              elapsed += dt;
          }
        },
      ).mount();

      scene.update(0.5);
      scene.update(0.5);

      expect(elapsed, 1);
    });
  });

  group('destroy', () {
    test('runs at unmount', () {
      final log = <String>[];

      final scene = TestNode(
        processor: (node, state) {
          switch (state) {
            case Destroy():
              log.add('destroyed');
          }
        },
      ).mount();

      scene.destroy();

      expect(log, ['destroyed']);
    });

    test('a throwing destroy is reported and contained', () {
      final signal = Signal0();
      var emissions = 0;

      final scene = TestNode(
        builder: (_) => signal(() => emissions += 1),
        processor: (node, state) {
          switch (state) {
            case Destroy():
              throw StateError('bad');
          }
        },
      ).mount();

      final reported = _reported(scene.destroy);
      signal.emit();

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
      expect(emissions, 0, reason: 'the build was still torn down');
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
