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
          components: [TestComponent(name: 'component', log: log)],
          children: [TestEntity(name: 'child', log: log)],
        ),
      );

      expect(log.builds, ['parent', 'component', 'child']);
    });

    test('destroys after its children and before its entity', () {
      final log = TestLog();

      Scene(
        TestEntity(
          name: 'parent',
          log: log,
          components: [TestComponent(name: 'component', log: log)],
          children: [TestEntity(name: 'child', log: log)],
        ),
      ).destroy();

      expect(log.unmounts, ['child', 'component', 'parent']);
    });

    test('updates after its entity and before its children', () {
      final log = TestLog();

      Scene(
        TestEntity(
          name: 'parent',
          log: log,
          components: [TestComponent(name: 'component', log: log)],
          children: [TestEntity(name: 'child', log: log)],
        ),
      ).update(0);

      expect(log.updates, ['parent', 'component', 'child']);
    });

    test("renders before its entity's children", () {
      final log = TestLog();

      TestEntity(
        components: [TestComponent(name: 'component', log: log)],
        children: [
          TestEntity(
            components: [TestComponent(name: 'child component', log: log)],
          ),
        ],
      ).render(RecordingCanvas());

      expect(log.renders, ['component', 'child component']);
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

    test('runs in priority order, before insertion order', () {
      final log = TestLog();

      Scene(
        Entity(
          components: [
            TestComponent(name: 'over', log: log, priority: 1),
            TestComponent(name: 'under', log: log),
          ],
        ),
      ).render(RecordingCanvas());

      expect(log.renders, ['under', 'over']);
    });

    test('a priority set on a live entity applies on the next update', () {
      final log = TestLog();
      final first = TestComponent(name: 'first', log: log);
      final second = TestComponent(name: 'second', log: log);
      final scene = Scene(Entity(components: [first, second]));

      first.priority = 1;
      scene.update(0);

      expect(log.updates, ['second', 'first']);
    });
  });

  group('structure', () {
    test('a component added to a live entity builds on the next update', () {
      final entity = Entity();
      final component = TestComponent();
      entity.addComponent(component);

      final scene = Scene(entity);
      scene.update(0);

      expect(entity.components, [component]);
      expect(component.builds, 1);
      expect(component.updates, 1);
    });

    test('a component removed from a live entity is destroyed on the next update', () {
      final component = TestComponent();
      final entity = Entity(components: [component]);
      final scene = Scene(entity);

      entity.removeComponent(component);
      expect(entity.components, [component], reason: 'the removal waits for the flush');
      scene.update(0);

      expect(entity.components, isEmpty);
      expect(component.destroys, 1);
      expect(component.isDestroyed, isTrue);
    });

    test('a destroyed component cannot be added again', () {
      final component = TestComponent();
      final entity = Entity(components: [component]);
      Scene(entity).destroy();

      expect(() => Entity().addComponent(component), throwsStateError);
    });

    test('cannot be added while it belongs to another entity', () {
      final component = TestComponent();
      Entity(components: [component]);

      expect(() => Entity().addComponent(component), throwsStateError);
    });

    test('detach removes it from its entity', () {
      final component = TestComponent();
      final entity = Entity(components: [component]);

      component.detach();

      expect(entity.components, isEmpty);
      expect(component.isAttached, isFalse);
    });
  });

  group('activity', () {
    test('a disabled component updates again once enabled', () {
      final component = TestComponent(enabled: false);
      final scene = Scene(Entity(components: [component]));

      scene.update(0);
      component.enable();
      scene.update(0);

      expect(component.updates, 1);
    });

    test("an entity's activity gates its components", () {
      final component = TestComponent();
      final entity = Entity(enabled: false, components: [component]);
      final scene = Scene(entity);

      scene.update(0);
      entity.enable();
      scene.update(0);

      expect(component.updates, 1);
    });
  });
}
