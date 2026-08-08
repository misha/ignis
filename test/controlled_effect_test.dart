import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('emits onStart once it starts progressing', () {
    final effect = ControlledEffect(controller: EffectController(duration: 1, startDelay: 0.5));
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
    final effect = ControlledEffect(controller: EffectController(duration: 1));
    effect.mount();
    final progresses = <double>[];
    effect.onProgress(progresses.add);

    effect.update(0.25);
    effect.update(0.75);

    expect(progresses, [0.25, 1]);
  });

  test('emits onFinish once isComplete becomes true, and never again', () {
    final effect = ControlledEffect(controller: EffectController(duration: 1));
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
    final effect = ControlledEffect(controller: EffectController(duration: 1));
    effect.mount();
    effect.pause();

    effect.update(0.5);

    expect(effect.isRunning, isFalse);
    expect(effect.isFinished, isFalse);
  });

  test('resets back to its start', () {
    final effect = ControlledEffect(controller: EffectController(duration: 1));
    effect.mount();
    effect.update(1);
    expect(effect.isFinished, isTrue);

    effect.reset();

    expect(effect.isRunning, isFalse);
    expect(effect.isFinished, isFalse);
    expect(effect.previousProgress, 0);
  });

  test('restarts times-1 times before emitting onFinish', () {
    final effect = ControlledEffect(controller: EffectController(duration: 1, times: 2));
    effect.mount();
    var starts = 0;
    var finishes = 0;
    effect.onStart(() => starts += 1);
    effect.onFinish(() => finishes += 1);

    effect.update(1);
    expect(starts, 1);
    expect(finishes, 0);
    expect(effect.isFinished, isFalse);

    effect.update(0.5);
    expect(starts, 2); // Restarted for its second run.
    expect(effect.previousProgress, 0.5);

    effect.update(0.5);
    expect(starts, 2);
    expect(finishes, 1);
    expect(effect.isFinished, isTrue);
  });

  test('repeats forever when times is null', () {
    final effect = ControlledEffect(controller: EffectController(duration: 1, times: null));
    effect.mount();
    var starts = 0;
    var finishes = 0;
    effect.onStart(() => starts += 1);
    effect.onFinish(() => finishes += 1);

    for (var i = 0; i < 10; i += 1) {
      effect.update(1);
    }

    expect(starts, 10);
    expect(finishes, 0);
  });

  test('reset() restarts the repeat count from the beginning', () {
    final effect = ControlledEffect(controller: EffectController(duration: 1, times: 2));
    effect.mount();
    var finishes = 0;
    effect.onFinish(() => finishes += 1);

    effect.update(1);
    effect.update(1);
    expect(finishes, 1);

    effect.reset();
    effect.update(1);
    effect.update(1);
    expect(finishes, 2);
  });

  test('only emits onFinish once a reverse phase completes', () {
    final effect = ControlledEffect(controller: EffectController(duration: 1, reverse: true));
    effect.mount();
    var finishes = 0;
    effect.onFinish(() => finishes += 1);

    effect.update(1);
    expect(effect.previousProgress, 1); // The forward phase is done.
    expect(finishes, 0);

    effect.update(1);
    expect(effect.previousProgress, 0); // Back at the start.
    expect(finishes, 1);
  });

  test('play(to: 0) plays it backward from wherever it currently is', () {
    final effect = ControlledEffect(controller: ManualEffectController(duration: 1));
    effect.mount();

    effect.play(to: 1);
    effect.update(0.75);
    expect(effect.previousProgress, 0.75);

    effect.play(to: 0);
    effect.update(0.25);
    expect(effect.previousProgress, 0.5);
  });

  test('play(from: ...) applies the jump immediately, not on the next tick', () {
    final effect = ControlledEffect(controller: ManualEffectController(duration: 1));
    effect.mount();

    var value = 0.0;
    var previous = 0.0;

    effect.onProgress((progress) {
      value += progress - previous;
      previous = progress;
    });

    effect.play(to: 1);
    effect.update(0.2);
    expect(value, closeTo(0.2, 1e-9));

    effect.play(from: 0.8, to: 1);
    expect(value, closeTo(0.8, 1e-9)); // Applied right away, before update().
  });

  test('redirecting mid-flight resumes from the current point, with no jump', () {
    final effect = ControlledEffect(controller: ManualEffectController(duration: 1));
    effect.mount();

    effect.play(to: 1);
    effect.update(0.4);
    final before = effect.previousProgress;

    effect.play(to: 0);
    effect.update(0);
    expect(effect.previousProgress, before);
  });

  test('reaches a non-round target exactly, surviving the position/elapsed round trip', () {
    final effect = ControlledEffect(controller: ManualEffectController(duration: 1));
    effect.mount();
    var finishes = 0;
    effect.onFinish(() => finishes += 1);

    effect.play(to: 1 / 3);
    effect.update(1 / 3);

    expect(finishes, 1);
    expect(effect.previousProgress, closeTo(1 / 3, 1e-9));
  });

  test('play() supports any sub-range, e.g. two-thirds of the way back from the end', () {
    final effect = ControlledEffect(controller: ManualEffectController(duration: 1));
    effect.mount();

    effect.play(from: 1, to: 1 / 3);
    effect.update(1 / 3);

    expect(effect.previousProgress, closeTo(2 / 3, 1e-9));
  });

  test('emits onFinish upon reaching the target', () {
    final effect = ControlledEffect(controller: ManualEffectController(duration: 1));
    effect.mount();
    var finishes = 0;
    effect.onFinish(() => finishes += 1);

    effect.play(to: 1);
    effect.update(1);
    expect(finishes, 1); // Finished playing to the end.

    effect.play(to: 0);
    effect.update(0.5);
    expect(finishes, 1);

    effect.update(0.5);
    expect(finishes, 2); // And again, reaching the start going backward.
    expect(effect.previousProgress, 0);
  });

  test('onStart fires again after a full there-and-back round trip', () {
    final effect = ControlledEffect(controller: ManualEffectController(duration: 1));
    effect.mount();
    var starts = 0;
    effect.onStart(() => starts += 1);

    effect.play(to: 1);
    effect.update(1);
    expect(starts, 1);

    effect.play(to: 0);
    effect.update(1);
    expect(starts, 1); // Still the same run, just played back to its start.

    effect.play(to: 1);
    effect.update(0.5);
    expect(starts, 2);
  });

  test('reset() also stops using the target set by play()', () {
    final effect = ControlledEffect(controller: ManualEffectController(duration: 1));
    effect.mount();
    effect.play(to: 0);

    effect.reset();
    effect.update(1);

    expect(effect.previousProgress, 0); // Back at rest, nothing to play toward.
  });

  test('detaches itself once play() reaches its target, when cleanup is true', () {
    final a = Node();
    final effect = ControlledEffect(
      controller: ManualEffectController(duration: 1),
      cleanup: true,
    );
    a.add(effect);
    final scene = a.mount();
    effect.play(from: 1, to: 0);

    scene.update(1);
    expect(a.children, [effect]); // detach() enqueued.

    scene.update(0);
    expect(a.children, isEmpty);
  });

  test('detaches itself once complete when added as a child, when cleanup is true', () {
    final a = Node();
    final effect = ControlledEffect(controller: EffectController(duration: 2), cleanup: true);
    a.add(effect);
    final scene = a.mount();

    scene.update(1);
    expect(effect.isFinished, isFalse);
    expect(a.children, [effect]);

    scene.update(1);
    expect(effect.isFinished, isTrue);
    expect(a.children, [effect]); // detach() enqueued.

    scene.update(0);
    expect(a.children, isEmpty);
  });
}
