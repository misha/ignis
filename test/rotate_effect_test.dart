import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('rotates its parent by an angle', () {
    final node = TransformNode(angle: 1);
    final scene = node.mount();

    node.add(
      RotateEffect.by(
        angle: 2,
        controller: EffectController(duration: 1),
        cleanup: true,
      ),
    );

    scene.update(0.25);
    expect(node.angle, 1.5);

    scene.update(0.75);
    expect(node.angle, 3);

    scene.update(0); // Flush the self-detach.
    expect(node.children, isEmpty);
  });

  test('rotates its parent to an angle', () {
    final node = TransformNode(angle: 1);
    final scene = node.mount();

    node.add(
      RotateEffect.to(
        angle: 3,
        controller: EffectController(duration: 1),
      ),
    );

    scene.update(0.5);
    expect(node.angle, 2);

    scene.update(0.5);
    expect(node.angle, 3);
  });

  test('captures the destination offset when the effect starts', () {
    final node = TransformNode();
    final scene = node.mount();

    node.add(
      RotateEffect.to(
        angle: 2,
        controller: EffectController(duration: 1, startDelay: 0.5),
      ),
    );

    scene.update(0.25);
    node.angle = 1;
    scene.update(0.75);

    expect(node.angle, 1.5);
  });

  test('multiple relative rotation effects compose', () {
    final node = TransformNode();
    final scene = node.mount();

    node.add(
      RotateEffect.by(
        angle: 1,
        controller: EffectController(duration: 1),
      ),
    );

    node.add(
      RotateEffect.by(
        angle: 2,
        controller: EffectController(duration: 1),
      ),
    );

    scene.update(0.5);
    expect(node.angle, 1.5);
  });

  test('re-resolves its target after being remounted elsewhere', () {
    final root = TransformNode();
    final nodeA = TransformNode(angle: 0);
    final nodeB = TransformNode(angle: 10);
    root.addAll([nodeA, nodeB]);
    final scene = root.mount();

    final effect = RotateEffect.by(
      angle: 2,
      controller: EffectController(duration: 1),
    );
    nodeA.add(effect);

    scene.update(0.5);
    expect(nodeA.angle, 1);

    effect.detach();
    scene.update(0); // Flush the detach.
    nodeB.add(effect);
    scene.update(0); // Flush the attach.

    scene.update(0.5);
    expect(nodeA.angle, 1); // Unchanged.
    expect(nodeB.angle, 11);
  });
}
