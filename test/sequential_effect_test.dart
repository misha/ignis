import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('only starts the next effect once the previous one finishes', () {
    final node = TransformNode();
    final scene = node.mount();

    node.add(
      SequentialEffect(
        effects: [
          MoveEffect.by(offset: .new(10, 0), controller: EffectController(duration: 1)),
          MoveEffect.by(offset: .new(0, 10), controller: EffectController(duration: 1)),
        ],
      ),
    );

    scene.update(0.5);
    expect(node.position, Vector2(5, 0)); // Only the first effect is running.

    scene.update(0.5);
    expect(node.position, Vector2(10, 0)); // The first effect just finished.

    scene.update(0.5);
    expect(node.position, Vector2(10, 5)); // The second effect is now running.

    scene.update(0.5);
    expect(node.position, Vector2(10, 10));
  });

  test('detaches each effect once it finishes', () {
    final node = TransformNode();
    final scene = node.mount();
    final first = MoveEffect.by(
      offset: .new(10, 0),
      controller: EffectController(duration: 1),
    );

    final second = MoveEffect.by(
      offset: .new(0, 10),
      controller: EffectController(duration: 1),
    );

    final sequence = SequentialEffect(effects: [first, second]);
    node.add(sequence);

    expect(sequence.children, [first]);

    scene.update(1);
    expect(sequence.children, [first]); // detach() enqueued — takes effect next flush.

    scene.update(0); // Flush the detach and the add of the next effect.
    expect(sequence.children, [second]);
  });

  test('emits onFinish once the last effect finishes', () {
    final node = TransformNode();
    final scene = node.mount();
    final sequence = SequentialEffect(
      effects: [
        MoveEffect.by(offset: .new(10, 0), controller: EffectController(duration: 1)),
        MoveEffect.by(offset: .new(0, 10), controller: EffectController(duration: 1)),
      ],
    );

    var finishes = 0;
    sequence.onFinish(() => finishes += 1);
    node.add(sequence);

    scene.update(1);
    expect(finishes, 0);

    scene.update(1);
    expect(finishes, 1);
  });

  test('detaches itself once the last effect finishes, when cleanup is true', () {
    final node = TransformNode();
    final scene = node.mount();

    node.add(
      SequentialEffect(
        cleanup: true,
        effects: [
          MoveEffect.by(
            offset: .new(10, 0),
            controller: EffectController(duration: 1),
          ),
        ],
      ),
    );

    scene.update(1);
    expect(node.children, isNotEmpty);

    scene.update(0); // Flush the self-detach.
    expect(node.children, isEmpty);
  });

  test('reset() restarts the current effect from its own start', () {
    final node = TransformNode();
    final scene = node.mount();
    final sequence = SequentialEffect(
      effects: [
        MoveEffect.by(
          offset: .new(10, 0),
          controller: EffectController(duration: 1),
        ),
        MoveEffect.by(
          offset: .new(0, 10),
          controller: EffectController(duration: 1),
        ),
      ],
    );

    node.add(sequence);
    scene.update(0.5);
    expect(node.position, Vector2(5, 0));

    sequence.reset();
    scene.update(0.5);
    expect(node.position, Vector2(10, 0)); // First effect's progress restarted from 0.

    scene.update(0.5);
    expect(node.position, Vector2(15, 0)); // First effect finishes (again).

    scene.update(0.5);
    expect(node.position, Vector2(15, 5)); // Second effect now runs.
  });

  test('reset() after finishing replays the whole sequence', () {
    final node = TransformNode();
    final scene = node.mount();
    var finishes = 0;

    final sequence = SequentialEffect(
      effects: [
        MoveEffect.by(
          offset: .new(10, 0),
          controller: EffectController(duration: 1),
        ),
        MoveEffect.by(
          offset: .new(0, 10),
          controller: EffectController(duration: 1),
        ),
      ],
    );

    sequence.onFinish(() => finishes += 1);
    node.add(sequence);

    scene.update(1);
    scene.update(1);
    expect(finishes, 1);
    expect(node.position, Vector2(10, 10));

    sequence.reset();
    scene.update(1);
    scene.update(1);
    expect(finishes, 2);
    expect(node.position, Vector2(20, 20));
  });
}
