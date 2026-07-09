import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('emits onStart once it starts progressing', () {
    final effect = EffectNode(controller: EffectController(duration: 1, startDelay: 0.5));
    effect.mount();
    var starts = 0;
    effect.onStart(() => starts += 1);

    effect.update(0.25);
    expect(starts, 0);

    effect.update(0.5);
    expect(starts, 1);

    effect.update(0.25);
    expect(starts, 1);
  });

  test('emits onProgress with its current progress once started', () {
    final effect = EffectNode(controller: EffectController(duration: 1));
    effect.mount();
    final progresses = <double>[];
    effect.onProgress(progresses.add);

    effect.update(0.25);
    effect.update(0.75);

    expect(progresses, [0.25, 1]);
  });

  test('emits onFinish once isComplete becomes true, and never again', () {
    final effect = EffectNode(controller: EffectController(duration: 1));
    effect.mount();
    var finishes = 0;
    effect.onFinish(() => finishes += 1);

    effect.update(0.5);
    expect(finishes, 0);

    effect.update(0.5);
    expect(finishes, 1);

    effect.update(1);
    expect(finishes, 1);
  });

  test('does not progress while paused', () {
    final effect = EffectNode(controller: EffectController(duration: 1));
    effect.mount();
    effect.pause();

    effect.update(0.5);

    expect(effect.isRunning, isFalse);
    expect(effect.isFinished, isFalse);
  });

  test('resets back to its start', () {
    final effect = EffectNode(controller: EffectController(duration: 1));
    effect.mount();
    effect.update(1);
    expect(effect.isFinished, isTrue);

    effect.reset();

    expect(effect.isRunning, isFalse);
    expect(effect.isFinished, isFalse);
    expect(effect.previousProgress, 0);
  });

  test('detaches itself once complete when added as a child, when cleanup is true', () {
    final a = Node();
    final effect = EffectNode(controller: EffectController(duration: 2, cleanup: true));
    a.add(effect);
    final scene = a.mount();

    scene.update(1);
    expect(effect.isFinished, isFalse);
    expect(a.children, [effect]);

    scene.update(1);
    expect(effect.isFinished, isTrue);
    expect(a.children, [effect]); // detach() enqueued — takes effect next flush.

    scene.update(0);
    expect(a.children, isEmpty);
  });
}
