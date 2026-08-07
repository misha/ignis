import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('scales its parent by an offset', () {
    final node = TransformNode(scale: .new(10, 20));
    final scene = node.mount();

    node.add(
      ScaleEffect.by(
        offset: .new(20, -10),
        controller: .new(duration: 1),
        cleanup: true,
      ),
    );

    scene.update(0.25);
    expect(node.scale, Vector2(15, 17.5));

    scene.update(0.75);
    expect(node.scale, Vector2(30, 10));

    scene.update(0); // Flush the self-detach.
    expect(node.children, isEmpty);
  });

  test('scales its parent to a destination', () {
    final node = TransformNode(scale: .new(10, 20));
    final scene = node.mount();

    node.add(
      ScaleEffect.to(
        destination: .new(30, 10),
        controller: .new(duration: 1),
      ),
    );

    scene.update(0.5);
    expect(node.scale, Vector2(20, 15));

    scene.update(0.5);
    expect(node.scale, Vector2(30, 10));
  });

  test('captures the destination offset when the effect starts', () {
    final node = TransformNode();
    final scene = node.mount();

    node.add(
      ScaleEffect.to(
        destination: .new(20, 10),
        controller: .new(duration: 1, startDelay: 0.5),
      ),
    );

    scene.update(0.25);
    node.scale.mutate().setFrom(.new(10, 0));
    scene.update(0.75);

    expect(node.scale, Vector2(15, 5));
  });

  test('multiple relative scale effects compose', () {
    final node = TransformNode();
    final scene = node.mount();

    node.add(
      ScaleEffect.by(
        offset: .new(10, 0),
        controller: .new(duration: 1),
      ),
    );

    node.add(
      ScaleEffect.by(
        offset: .new(0, 20),
        controller: .new(duration: 1),
      ),
    );

    scene.update(0.5);
    expect(node.scale, Vector2(6, 11)); // Starts from the default scale of (1, 1).
  });

  test('re-resolves its target after being remounted elsewhere', () {
    final root = TransformNode();
    final nodeA = TransformNode(scale: .new(0, 0));
    final nodeB = TransformNode(scale: .new(100, 100));
    root.addAll([nodeA, nodeB]);
    final scene = root.mount();
    final effect = ScaleEffect.by(
      offset: .new(10, 0),
      controller: .new(duration: 1),
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
