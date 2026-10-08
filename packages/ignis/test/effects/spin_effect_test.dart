import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_sink.dart';

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

  test('never emits EffectFinish', () {
    final node = SpatialNode();
    final scene = node.mount();
    final effect = SpinEffect(speed: 1);
    final sink = TestSink([effect]);
    node.add(sink);

    scene.update(100);
    expect(sink.of<EffectFinish>().length, 0);
  });
}
