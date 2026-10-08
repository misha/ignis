import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('captures the destination offset when mounted', () {
    final node = SpatialNode();
    final scene = node.mount();
    node.angle = 1;

    node.add(
      RotateEffect.to(
        angle: 2,
        timeline: .sequence([.once(.wait(0.5)), .duration(1)]),
      ),
    );

    scene.update(0.25);
    node.angle = 0;
    scene.update(1.25);

    expect(node.angle, 1);
  });

  test('multiple relative rotation effects compose', () {
    final node = SpatialNode();
    final scene = node.mount();

    node.add(
      RotateEffect.by(
        angle: 1,
        timeline: .duration(1),
      ),
    );

    node.add(
      RotateEffect.by(
        angle: 2,
        timeline: .duration(1),
      ),
    );

    scene.update(0.5);
    expect(node.angle, 1.5);
  });

  test('runs at a given speed, deriving its duration from the angle covered', () {
    final node = SpatialNode(angle: 1);
    final scene = node.mount();

    node.add(
      RotateEffect.to(
        angle: 6, // Angle covered 5, at speed 5 -> duration 1.
        timeline: .speed(5),
      ),
    );

    scene.update(0.5);
    expect(node.angle, 3.5);

    scene.update(0.5);
    expect(node.angle, 6);
  });
}
