import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('moves its parent by an offset', () {
    final node = TransformNode(position: .new(10, 20));
    final scene = node.mount();

    node.add(
      MoveEffect.by(
        offset: .new(20, -10),
        controller: .linear(1),
        cleanup: true,
      ),
    );

    scene.update(0.25);
    expect(node.position, Vector2(15, 17.5));

    scene.update(0.75);
    expect(node.position, Vector2(30, 10));

    scene.update(0); // Flush the self-detach.
    expect(node.children, isEmpty);
  });

  test('moves its parent to a destination', () {
    final node = TransformNode(position: .new(10, 20));
    final scene = node.mount();

    node.add(
      MoveEffect.to(
        destination: .new(30, 10),
        controller: .linear(1),
      ),
    );

    scene.update(0.5);
    expect(node.position, Vector2(20, 15));

    scene.update(0.5);
    expect(node.position, Vector2(30, 10));
  });

  test('captures the destination offset when mounted', () {
    final node = TransformNode();
    final scene = node.mount();
    node.position.mutate().setFrom(.new(10, 0));

    node.add(
      MoveEffect.to(
        destination: .new(20, 10),
        controller: .sequence([.delay(0.5), .linear(1)]),
      ),
    );

    scene.update(0.25);
    node.position.mutate().setFrom(.new(0, 0));
    scene.update(1.25);

    expect(node.position, Vector2(10, 10));
  });

  test('multiple relative movement effects compose', () {
    final node = TransformNode();
    final scene = node.mount();

    node.add(
      MoveEffect.by(
        offset: .new(10, 0),
        controller: .linear(1),
      ),
    );

    node.add(
      MoveEffect.by(
        offset: .new(0, 20),
        controller: .linear(1),
      ),
    );

    scene.update(0.5);
    expect(node.position, Vector2(5, 10));
  });

  test('runs at a given speed, deriving its duration from the distance covered', () {
    final node = TransformNode(position: .new(0, 0));
    final scene = node.mount();

    node.add(
      MoveEffect.to(
        destination: .new(30, 40), // Distance 50, at speed 10 -> duration 5.
        controller: .speed(10),
      ),
    );

    scene.update(2.5);
    expect(node.position, Vector2(15, 20));

    scene.update(2.5);
    expect(node.position, Vector2(30, 40));
  });

  test('speed uses the offset captured at mount, not a live re-measurement', () {
    final node = TransformNode();
    final scene = node.mount();
    node.position.mutate().setFrom(.new(10, 0));

    node.add(
      MoveEffect.to(
        destination: .new(40, 40), // Offset (30, 40) from (10, 0): distance 50.
        controller: .sequence([.delay(0.5), .speed(10)]), // Duration 5 once started.
      ),
    );

    scene.update(0.25); // Still within the delay; no movement yet.
    node.position.mutate().setFrom(.new(0, 0));
    scene.update(5.25); // Remaining 0.25 delay, then the full speed-driven leg.

    expect(node.position, Vector2(30, 40));
  });

  test('re-resolves its target after being remounted elsewhere', () {
    final root = TransformNode();
    final nodeA = TransformNode(position: .new(0, 0));
    final nodeB = TransformNode(position: .new(100, 100));
    root.addAll([nodeA, nodeB]);
    final scene = root.mount();
    final effect = MoveEffect.by(
      offset: .new(10, 0),
      controller: .linear(1),
    );

    nodeA.add(effect);

    scene.update(0.5);
    expect(nodeA.position, Vector2(5, 0));

    effect.detach();
    scene.update(0); // Flush the detach.
    nodeB.add(effect);
    scene.update(0); // Flush the attach.

    scene.update(0.5);
    expect(nodeA.position, Vector2(5, 0)); // Unchanged.
    expect(nodeB.position, Vector2(105, 100));
  });
}
