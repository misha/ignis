import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('moves its parent by an offset', () {
    final node = TransformNode(position: .new(10, 20));
    final scene = node.mount();

    node.add(
      MoveEffect.by(
        offset: .new(20, -10),
        controller: EffectController(duration: 1),
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
        controller: EffectController(duration: 1),
      ),
    );

    scene.update(0.5);
    expect(node.position, Vector2(20, 15));

    scene.update(0.5);
    expect(node.position, Vector2(30, 10));
  });

  test('captures the destination offset when the effect starts', () {
    final node = TransformNode();
    final scene = node.mount();

    node.add(
      MoveEffect.to(
        destination: .new(20, 10),
        controller: EffectController(duration: 1, startDelay: 0.5),
      ),
    );

    scene.update(0.25);
    node.position.mutate().setFrom(.new(10, 0));
    scene.update(0.75);

    expect(node.position, Vector2(15, 5));
  });

  test('multiple relative movement effects compose', () {
    final node = TransformNode();
    final scene = node.mount();

    node.add(
      MoveEffect.by(
        offset: .new(10, 0),
        controller: EffectController(duration: 1),
      ),
    );

    node.add(
      MoveEffect.by(
        offset: .new(0, 20),
        controller: EffectController(duration: 1),
      ),
    );

    scene.update(0.5);
    expect(node.position, Vector2(5, 10));
  });

  test('re-resolves its target after being remounted elsewhere', () {
    final root = TransformNode();
    final nodeA = TransformNode(position: .new(0, 0));
    final nodeB = TransformNode(position: .new(100, 100));
    root.addAll([nodeA, nodeB]);
    final scene = root.mount();
    final effect = MoveEffect.by(
      offset: .new(10, 0),
      controller: EffectController(duration: 1),
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
