import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'package:flutter/foundation.dart';

import '../support/test_component.dart';
import '../support/test_entity.dart';

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
      final entity = TestEntity();
      Scene(entity);

      expect(entity.builds, 1);
    });

    test('a build that throws on mount throws out of mount', () {
      final entity = TestEntity(builder: (_) => throw StateError('no ancestor'));

      expect(() => Scene(entity), throwsStateError);
    });

    test('a build that throws builds none of its components or children', () {
      final component = TestComponent();
      final child = TestEntity();
      final entity = TestEntity(
        builder: (_) => throw StateError('no ancestor'),
        components: [component],
        children: [child],
      );

      expect(() => Scene(entity), throwsStateError);
      expect(component.builds, 0);
      expect(child.builds, 0);
    });

    test('a build that throws on a live add throws out of update', () {
      final root = TestEntity();
      final scene = Scene(root);
      root.add(TestEntity(builder: (_) => throw StateError('no ancestor')));

      expect(() => scene.update(0), throwsStateError);
    });
  });

  group('add', () {
    test('returns the node it was given, on every build', () {
      Entity? given;
      Entity? returned;

      final entity = TestEntity(
        builder: (n) {
          given = Entity();
          returned = n.add(given!);
        },
      );

      Scene(entity).update(0);

      expect(returned, same(given));
      expect(entity.children.single, same(given));
    });
  });

  group('update', () {
    test('runs every update', () {
      var elapsed = 0.0;

      final scene = Scene(
        TestEntity(
          processor: (entity, event) {
            switch (event) {
              case Update(:final dt):
                elapsed += dt;
            }
          },
        ),
      );

      scene.update(0.5);
      scene.update(0.5);

      expect(elapsed, 1);
    });
  });

  group('destroy', () {
    test('runs at unmount', () {
      final log = <String>[];

      final scene = Scene(
        TestEntity(
          processor: (entity, event) {
            switch (event) {
              case Destroy():
                log.add('destroyed');
            }
          },
        ),
      );

      scene.destroy();

      expect(log, ['destroyed']);
    });

    test('a throwing destroy is reported and contained', () {
      final entity = TestEntity(
        processor: (entity, event) {
          switch (event) {
            case Destroy():
              throw StateError('bad');
          }
        },
      );

      final scene = Scene(entity);
      final reported = _reported(scene.destroy);

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
      expect(entity.isMounted, isFalse, reason: 'the unmount still finished');
    });
  });
}
