import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('emits onStart once it starts progressing', () {
    final effect = ControlledEffect(controller: .new(duration: 1, initialDelay: 0.5));
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

  test('emits onStart again on each repeat', () {
    final effect = ControlledEffect(controller: .new(duration: 1, times: 2));
    effect.mount();
    var starts = 0;
    effect.onStart(() => starts += 1);

    effect.update(1);
    expect(starts, 1);

    effect.update(0.5);
    expect(starts, 2);
  });

  test('reversing back past the start does not redo the initial delay', () {
    final effect = ControlledEffect(controller: .new(duration: 1, initialDelay: 0.5));
    effect.mount();
    var starts = 0;
    effect.onStart(() => starts += 1);

    effect.update(0.75);
    expect(starts, 1);

    effect.reverse();
    effect.update(1);
    expect(effect.isRunning, isTrue);
    expect(effect.previousProgress, 0);

    effect.forward();
    effect.update(0.1);
    expect(starts, 1);
  });

  test('emits onStart again after reversing past a nonzero bottomDelay', () {
    final effect = ControlledEffect(controller: .new(duration: 1, initialDelay: 0.5, bottomDelay: 0.2));
    effect.mount();
    var starts = 0;
    effect.onStart(() => starts += 1);

    effect.update(0.75);
    expect(starts, 1);

    effect.reverse();
    effect.update(0.3);
    expect(effect.isRunning, isFalse);

    effect.forward();
    effect.update(0.3);
    expect(starts, 2);
  });

  test('emits onProgress with its current progress once started', () {
    final effect = ControlledEffect(controller: .new(duration: 1));
    effect.mount();
    final progresses = <double>[];
    effect.onProgress(progresses.add);

    effect.update(0.25);
    effect.update(0.75);

    expect(progresses, [0.25, 1]);
  });

  test('emits onFinish once isComplete becomes true, and never again', () {
    final effect = ControlledEffect(controller: .new(duration: 1));
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
    final effect = ControlledEffect(controller: .new(duration: 1));
    effect.mount();
    effect.pause();

    effect.update(0.5);

    expect(effect.isRunning, isFalse);
    expect(effect.isFinished, isFalse);
  });

  test('resets back to its start', () {
    final effect = ControlledEffect(controller: .new(duration: 1));
    effect.mount();
    effect.update(1);
    expect(effect.isFinished, isTrue);

    effect.reset();

    expect(effect.isRunning, isFalse);
    expect(effect.isFinished, isFalse);
    expect(effect.previousProgress, 0);
  });

  test('restarts times-1 times before emitting onFinish', () {
    final effect = ControlledEffect(controller: .new(duration: 1, times: 2));
    effect.mount();
    var finishes = 0;
    effect.onFinish(() => finishes += 1);

    effect.update(1);
    expect(effect.previousProgress, 0);
    expect(finishes, 0);
    expect(effect.isFinished, isFalse);

    effect.update(0.5);
    expect(effect.previousProgress, 0.5);

    effect.update(0.5);
    expect(finishes, 1);
    expect(effect.isFinished, isTrue);
  });

  test('repeats forever when times is null', () {
    final effect = ControlledEffect(controller: .new(duration: 1, times: null));
    effect.mount();
    var finishes = 0;
    effect.onFinish(() => finishes += 1);

    for (var i = 0; i < 10; i += 1) {
      effect.update(1);
      expect(effect.isFinished, isFalse);
    }

    expect(finishes, 0);
  });

  test('reset() restarts the repeat count from the beginning', () {
    final effect = ControlledEffect(controller: .new(duration: 1, times: 2));
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
    final effect = ControlledEffect(controller: .new(duration: 1, reverse: true));
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

  test('defaults to running forward', () {
    final effect = ControlledEffect(controller: .new(duration: 1));

    expect(effect.isForward, isTrue);
    expect(effect.isReverse, isFalse);
  });

  test('reverse() ticks progress backward', () {
    final effect = ControlledEffect(controller: .new(duration: 1));
    effect.mount();

    effect.update(0.75);
    expect(effect.previousProgress, 0.75);

    effect.reverse();
    expect(effect.isForward, isFalse);
    expect(effect.isReverse, isTrue);

    effect.update(0.5);
    expect(effect.previousProgress, 0.25);
  });

  test('forward() resumes progress forward after reverse()', () {
    final effect = ControlledEffect(controller: .new(duration: 1));
    effect.mount();

    effect.update(0.5);
    effect.reverse();
    effect.update(0.25);
    expect(effect.previousProgress, 0.25);

    effect.forward();
    effect.update(0.25);
    expect(effect.previousProgress, 0.5);
  });

  test('reversing off the end un-finishes the effect', () {
    final effect = ControlledEffect(controller: .new(duration: 1));
    effect.mount();
    var finishes = 0;
    effect.onFinish(() => finishes += 1);

    effect.update(1);
    expect(effect.isFinished, isTrue);

    effect.reverse();
    effect.update(0.5);
    expect(effect.isFinished, isFalse);
    expect(effect.previousProgress, 0.5);
    expect(finishes, 1);
  });

  test('reset() resets direction back to forward', () {
    final effect = ControlledEffect(controller: .new(duration: 1));
    effect.mount();
    effect.reverse();

    effect.reset();

    expect(effect.isForward, isTrue);
  });

  test('detaches itself once complete when added as a child, when cleanup is true', () {
    final a = Node();
    final effect = ControlledEffect(controller: .new(duration: 2), cleanup: true);
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
