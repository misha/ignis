import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/canvas.dart';
import '../support/test_component.dart';
import '../support/test_entity.dart';

void main() {
  group('lifecycle', () {
    test('builds after its entity and before its children', () {
      final log = TestLog();

      Scene(
        TestEntity(
          name: 'parent',
          log: log,
          components: [TestComponent(name: 'part', log: log)],
          children: [TestEntity(name: 'child', log: log)],
        ),
      );

      expect(log.builds, ['parent', 'part', 'child']);
    });

    test('destroys after its children and before its entity', () {
      final log = TestLog();

      Scene(
        TestEntity(
          name: 'parent',
          log: log,
          components: [TestComponent(name: 'part', log: log)],
          children: [TestEntity(name: 'child', log: log)],
        ),
      ).destroy();

      expect(log.unmounts, ['child', 'part', 'parent']);
    });

    test('updates after its entity and before its children', () {
      final log = TestLog();

      Scene(
        TestEntity(
          name: 'parent',
          log: log,
          components: [TestComponent(name: 'part', log: log)],
          children: [TestEntity(name: 'child', log: log)],
        ),
      ).update(0);

      expect(log.updates, ['parent', 'part', 'child']);
    });

    test('renders after its entity and before its children', () {
      final log = TestLog();

      TestEntity(
        name: 'parent',
        log: log,
        components: [TestComponent(name: 'part', log: log)],
        children: [TestEntity(name: 'child', log: log)],
      ).render(RecordingCanvas());

      expect(log.renders, ['parent', 'part', 'child']);
    });

    test('runs in the order components were added', () {
      final log = TestLog();

      Scene(
        Entity(
          components: [
            TestComponent(name: 'first', log: log),
            TestComponent(name: 'second', log: log),
          ],
        ),
      ).update(0);

      expect(log.updates, ['first', 'second']);
    });
  });

  group('structure', () {
    test('a component added to a live entity builds on the next update', () {
      final entity = Entity();
      final scene = Scene(entity);
      final part = entity.components.add(TestComponent());

      scene.update(0);

      expect(entity.components, [part]);
      expect(part.builds, 1);
      expect(part.updates, 1);
    });

    test('a component removed from a live entity is destroyed on the next update', () {
      final part = TestComponent();
      final entity = Entity(components: [part]);
      final scene = Scene(entity);

      entity.components.remove(part);
      expect(entity.components, [part], reason: 'the removal waits for the flush');
      scene.update(0);

      expect(entity.components, isEmpty);
      expect(part.destroys, 1);
      expect(part.isDestroyed, isTrue);
    });

    test('a destroyed component cannot be added again', () {
      final part = TestComponent();
      final entity = Entity(components: [part]);
      Scene(entity).destroy();

      expect(() => Entity().components.add(part), throwsStateError);
    });

    test('detach removes it from its entity', () {
      final part = TestComponent();
      final entity = Entity(components: [part]);

      part.detach();

      expect(entity.components, isEmpty);
      expect(part.isAttached, isFalse);
    });
  });

  group('activity', () {
    test('a disabled component updates again once enabled', () {
      final part = TestComponent(enabled: false);
      final scene = Scene(Entity(components: [part]));

      scene.update(0);
      part.enable();
      scene.update(0);

      expect(part.updates, 1);
    });

    test("an entity's activity gates its components", () {
      final part = TestComponent();
      final entity = Entity(enabled: false, components: [part]);
      final scene = Scene(entity);

      scene.update(0);
      entity.enable();
      scene.update(0);

      expect(part.updates, 1);
    });
  });
}
