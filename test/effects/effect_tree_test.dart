import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('composites nest inside one another', () {
    final node = TransformNode();
    final scene = node.mount();
    final sequence = SequentialEffect(
      effects: [
        CombinedEffect(
          effects: [
            MoveEffect.by(
              offset: .new(10, 0),
              controller: .linear(1),
            ),
            RotateEffect.by(
              angle: 2,
              controller: .linear(1),
            ),
          ],
        ),
        MoveEffect.by(
          offset: .new(0, 10),
          controller: .linear(1),
        ),
      ],
    );

    var finishes = 0;
    sequence.onFinish(() => finishes += 1);
    node.add(sequence);

    scene.update(0.5);
    expect(node.position, Vector2(5, 0));
    expect(node.angle, 1);

    scene.update(0.5);
    expect(node.position, Vector2(10, 0)); // The combined effect just finished.
    expect(node.angle, 2);
    expect(finishes, 0);

    scene.update(0.5);
    expect(node.position, Vector2(10, 5)); // The trailing move effect is running.

    scene.update(0.5);
    expect(node.position, Vector2(10, 10));
    expect(finishes, 1);
  });
}
