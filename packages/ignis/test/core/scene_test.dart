import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_entity.dart';

void main() {
  test('tracks size and layout state after resize', () {
    final scene = Scene(Entity());
    scene.resize(100, 80);

    expect(scene.hasSize, isTrue);
    expect(scene.size, Vector2(100, 80));
  });

  test('a destroyed scene refuses to be driven', () {
    final scene = Scene(Entity());
    scene.destroy();

    expect(() => scene.update(0), throwsAssertionError);
    expect(() => scene.resize(100, 80), throwsAssertionError);
    expect(scene.reassemble, throwsAssertionError);
    expect(scene.destroy, returnsNormally);
  });

  test('reassembling posts Reassemble to every node once', () {
    final reassembled = <TestEntity>[];

    void record(TestEntity entity, Message message) {
      if (message is Reassemble) reassembled.add(entity);
    }

    final child = TestEntity(processor: record);
    final root = TestEntity(processor: record, children: [child]);
    Scene(root).reassemble();

    expect(reassembled, unorderedEquals([root, child]));
  });

  test('keeps the given node parentless once loaded', () {
    final entity = Entity();
    final scene = Scene(entity);

    expect(scene.root.parent, isNull);
  });
}
