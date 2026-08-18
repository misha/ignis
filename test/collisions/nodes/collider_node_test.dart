import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('throws without a CollisionNode ancestor', () {
    final collider = ColliderNode(
      shape: .circle(1),
      position: .zero,
    );

    expect(collider.mount, throwsStateError);
  });

  test('does nothing without a CollisionNode ancestor while not strict', () {
    final collider = ColliderNode(
      shape: .circle(1),
      position: .zero,
      strict: false,
    );

    expect(() => collider.mount(), returnsNormally);
  });

  test('registers with the nearest CollisionNode ancestor, not an outer one', () {
    final outer = CollisionDetectionNode();
    final inner = CollisionDetectionNode();
    outer.add(inner);

    final a = ColliderNode(
      shape: .circle(4),
      position: .zero,
      layer: 1,
      mask: 1,
    );

    inner.add(a);

    final innerSibling = ColliderNode(
      shape: .circle(4),
      position: .new(1, 0),
      layer: 1,
      mask: 1,
    );

    inner.add(innerSibling);

    outer.add(
      ColliderNode(
        shape: .circle(4),
        position: .zero,
        layer: 1,
        mask: 1,
      ),
    );

    final aStarted = <ColliderNode>[];
    a.onCollisionStart(aStarted.add);

    outer.mount().update(0);

    expect(aStarted, [innerSibling]);
  });

  test('unregisters from CollisionNode when detached', () {
    final collisions = CollisionDetectionNode();
    final a = ColliderNode(
      shape: .circle(4),
      position: .zero,
      layer: 1,
      mask: 1,
    );

    final b = ColliderNode(
      shape: .circle(4),
      position: .new(1, 0),
      layer: 1,
      mask: 1,
    );

    collisions.add(a);
    collisions.add(b);

    final bExited = <ColliderNode>[];
    b.onCollisionEnd(bExited.add);

    final scene = collisions.mount();
    scene.update(0);

    a.detach();
    expect(() => scene.update(0), returnsNormally);
    expect(bExited, isEmpty);
  });
}
