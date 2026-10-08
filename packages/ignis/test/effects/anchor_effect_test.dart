import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('captures the destination offset when mounted', () {
    final node = ShapeNode(shape: .square(0));
    final scene = node.mount();
    node.anchor = .new(10, 0);

    node.add(
      AnchorEffect.to(
        destination: .new(20, 10),
        timeline: .sequence([.once(.wait(0.5)), .duration(1)]),
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
        timeline: .duration(1),
      ),
    );

    node.add(
      AnchorEffect.by(
        offset: .new(0, 20),
        timeline: .duration(1),
      ),
    );

    scene.update(0.5);
    expect(node.anchor, Anchor(5, 10));
  });
}
