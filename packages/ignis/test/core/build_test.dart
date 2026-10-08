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

  group('add', () {
    test('returns the node it was given, on every build', () {
      Node? given;
      Node? returned;

      final node = TestNode(
        builder: (n) {
          given = Node();
          returned = n.add(given!);
        },
      );

      node.mount().update(0);

      expect(returned, same(given));
      expect(node.children.single, same(given));
    });
  });

  group('update', () {
    test('runs every update', () {
      var elapsed = 0.0;

      final scene = TestNode(
        processor: (node, event) {
          switch (event) {
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
        processor: (node, event) {
          switch (event) {
            case Destroy():
              log.add('destroyed');
          }
        },
      ).mount();

      scene.destroy();

      expect(log, ['destroyed']);
    });

    test('a throwing destroy is reported and contained', () {
      final node = TestNode(
        processor: (node, event) {
          switch (event) {
            case Destroy():
              throw StateError('bad');
          }
        },
      );

      final scene = node.mount();
      final reported = _reported(scene.destroy);

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
      expect(node.isMounted, isFalse, reason: 'the unmount still finished');
    });
  });
}
