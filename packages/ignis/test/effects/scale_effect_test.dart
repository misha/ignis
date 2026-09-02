import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('captures the destination offset when mounted', () {
    final node = SpatialNode();
    final scene = node.mount();
    node.scale.setValues(10, 0);

    node.add(
      ScaleEffect.to(
        destination: .new(20, 10),
        timeline: .sequence([.once(.wait(0.5)), .duration(1)]),
      ),
    );

    scene.update(0.25);
    node.scale.setValues(0, 0);
    scene.update(1.25);

    expect(node.scale, Vector2(10, 10));
  });

  test('multiple relative scale effects compose', () {
    final node = SpatialNode();
    final scene = node.mount();

    node.add(
      ScaleEffect.by(
        offset: .new(10, 0),
        timeline: .duration(1),
      ),
    );

    node.add(
      ScaleEffect.by(
        offset: .new(0, 20),
        timeline: .duration(1),
      ),
    );

    scene.update(0.5);
    expect(node.scale, Vector2(6, 11)); // Starts from the default scale of (1, 1).
  });

  test('runs at a given speed, deriving its duration from the distance covered', () {
    final node = SpatialNode(scale: .new(10, 20));
    final scene = node.mount();

    node.add(
      ScaleEffect.to(
        destination: .new(40, 60), // Offset (30, 40): distance 50, at speed 10 -> duration 5.
        timeline: .speed(10),
      ),
    );

    scene.update(2.5);
    expect(node.scale, Vector2(25, 40));

    scene.update(2.5);
    expect(node.scale, Vector2(40, 60));
  });

  test('re-resolves its target after being remounted elsewhere', () {
    final root = SpatialNode();
    final nodeA = SpatialNode(scale: .zero);
    final nodeB = SpatialNode(scale: .all(100));
    root.addAll([nodeA, nodeB]);
    final scene = root.mount();
    final effect = ScaleEffect.by(
      offset: .new(10, 0),
      timeline: .duration(1),
    );

    nodeA.add(effect);

    scene.update(0.5);
    expect(nodeA.scale, Vector2(5, 0));

    effect.detach();
    scene.update(0); // Flush the detach.
    nodeB.add(effect);
    scene.update(0); // Flush the attach.

    scene.update(0.5);
    expect(nodeA.scale, Vector2(5, 0)); // Unchanged.
    expect(nodeB.scale, Vector2(105, 100));
  });
}
