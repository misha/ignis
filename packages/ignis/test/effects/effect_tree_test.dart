import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_sink.dart';

void main() {
  test('composites nest inside one another', () {
    final node = SpatialNode();
    final scene = node.mount();
    final sequence = SequentialEffect(
      effects: [
        CombinedEffect(
          effects: [
            MoveEffect.by(
              offset: .new(10, 0),
              timeline: .duration(1),
            ),
            RotateEffect.by(
              angle: 2,
              timeline: .duration(1),
            ),
          ],
        ),
        MoveEffect.by(
          offset: .new(0, 10),
          timeline: .duration(1),
        ),
      ],
    );

    final sink = TestSink([sequence]);
    node.add(sink);

    scene.update(0.5);
    expect(node.position, Vector2(5, 0));
    expect(node.angle, 1);

    scene.update(0.5);
    expect(node.position, Vector2(10, 0)); // The combined effect just finished.
    expect(node.angle, 2);
    expect(sink.of<EffectFinish>().length, 0);

    scene.update(0.5);
    expect(node.position, Vector2(10, 5)); // The trailing move effect is running.

    scene.update(0.5);
    expect(node.position, Vector2(10, 10));
    expect(sink.of<EffectFinish>().length, 1);
  });
}
