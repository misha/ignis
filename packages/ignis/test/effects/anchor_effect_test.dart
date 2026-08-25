import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('anchors its parent by an offset', () {
    final node = ShapeNode(shape: .square(0), anchor: .new(10, 20));
    final scene = node.mount();

    node.add(
      AnchorEffect.by(
        offset: .new(20, -10),
        controller: .duration(1),
        cleanup: true,
      ),
    );

    scene.update(0.25);
    expect(node.anchor, Anchor(15, 17.5));

    scene.update(0.75);
    expect(node.anchor, Anchor(30, 10));

    scene.update(0); // Flush the self-detach.
    expect(node.children, isEmpty);
  });

  test('anchors its parent to a destination', () {
    final node = ShapeNode(shape: .square(0), anchor: .new(10, 20));
    final scene = node.mount();

    node.add(
      AnchorEffect.to(
        destination: .new(30, 10),
        controller: .duration(1),
      ),
    );

    scene.update(0.5);
    expect(node.anchor, Anchor(20, 15));

    scene.update(0.5);
    expect(node.anchor, Anchor(30, 10));
  });

  test('captures the destination offset when mounted', () {
    final node = ShapeNode(shape: .square(0));
    final scene = node.mount();
    node.anchor = .new(10, 0);

    node.add(
      AnchorEffect.to(
        destination: .new(20, 10),
        controller: .sequence([.once(.wait(0.5)), .duration(1)]),
      ),
    );

    scene.update(0.25);
    node.anchor = .new(0, 0);
    scene.update(1.25);

    expect(node.anchor, Anchor(10, 10));
  });

  test('multiple relative anchor effects compose', () {
    final node = ShapeNode(shape: .square(0));
    final scene = node.mount();

    node.add(
      AnchorEffect.by(
        offset: .new(10, 0),
        controller: .duration(1),
      ),
    );

    node.add(
      AnchorEffect.by(
        offset: .new(0, 20),
        controller: .duration(1),
      ),
    );

    scene.update(0.5);
    expect(node.anchor, Anchor(5, 10));
  });

  test('re-resolves its target after being remounted elsewhere', () {
    final root = SpatialNode();
    final nodeA = ShapeNode(shape: .square(0), anchor: .new(0, 0));
    final nodeB = ShapeNode(shape: .square(0), anchor: .new(100, 100));
    root.addAll([nodeA, nodeB]);
    final scene = root.mount();
    final effect = AnchorEffect.by(
      offset: .new(10, 0),
      controller: .duration(1),
    );

    nodeA.add(effect);

    scene.update(0.5);
    expect(nodeA.anchor, Anchor(5, 0));

    effect.detach();
    scene.update(0); // Flush the detach.
    nodeB.add(effect);
    scene.update(0); // Flush the attach.

    scene.update(0.5);
    expect(nodeA.anchor, Anchor(5, 0)); // Unchanged.
    expect(nodeB.anchor, Anchor(105, 100));
  });
}
