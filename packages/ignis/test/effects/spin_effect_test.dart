import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('re-reads speed every tick', () {
    final node = SpatialNode(angle: 0);
    final scene = node.mount();
    final effect = SpinEffect(speed: 1);
    node.add(effect);

    scene.update(1);
    expect(node.angle, 1);

    effect.speed = 3;
    scene.update(1);
    expect(node.angle, 4);
  });

  test('never emits onFinish', () {
    final node = SpatialNode();
    final scene = node.mount();
    final effect = SpinEffect(speed: 1);
    var finishes = 0;
    effect.onFinish(() => finishes += 1);
    node.add(effect);

    scene.update(100);
    expect(finishes, 0);
  });
}
