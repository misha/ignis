import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('runs its effects in parallel', () {
    final node = TransformNode();
    final scene = node.mount();

    node.add(
      CombinedEffect(
        effects: [
          MoveEffect.by(offset: .new(10, 0), controller: EffectController(duration: 1)),
          RotateEffect.by(angle: 2, controller: EffectController(duration: 1)),
        ],
      ),
    );

    scene.update(0.5);
    expect(node.position, Vector2(5, 0));
    expect(node.angle, 1);
  });

  test('emits onFinish once every effect has finished', () {
    final node = TransformNode();
    final scene = node.mount();
    final combined = CombinedEffect(
      effects: [
        MoveEffect.by(offset: .new(10, 0), controller: EffectController(duration: 1)),
        RotateEffect.by(angle: 2, controller: EffectController(duration: 2)),
      ],
    );

    var finishes = 0;
    combined.onFinish(() => finishes += 1);
    node.add(combined);

    scene.update(1);
    expect(finishes, 0); // The move effect finished; the rotate one hasn't.

    scene.update(1);
    expect(finishes, 1);
  });

  test('detaches itself once every effect finishes, when cleanup is true', () {
    final node = TransformNode();
    final scene = node.mount();

    node.add(
      CombinedEffect(
        effects: [
          MoveEffect.by(
            offset: .new(10, 0),
            controller: EffectController(duration: 1),
          ),
          RotateEffect.by(
            angle: 2,
            controller: EffectController(duration: 1),
          ),
        ],
        cleanup: true,
      ),
    );

    scene.update(1);
    expect(node.children, isNotEmpty);

    scene.update(0); // Flush the self-detach.
    expect(node.children, isEmpty);
  });

  test('reset() lets it run and finish again', () {
    final node = TransformNode();
    final scene = node.mount();
    final combined = CombinedEffect(
      effects: [
        MoveEffect.by(
          offset: .new(10, 0),
          controller: EffectController(duration: 1),
        ),
        RotateEffect.by(
          angle: 2,
          controller: EffectController(duration: 1),
        ),
      ],
    );

    var finishes = 0;
    combined.onFinish(() => finishes += 1);
    node.add(combined);

    scene.update(1);
    expect(finishes, 1);
    expect(node.position, Vector2(10, 0));
    expect(node.angle, 2);

    combined.reset();
    scene.update(1);
    expect(finishes, 2);
    expect(node.position, Vector2(20, 0));
    expect(node.angle, 4);
  });
}
