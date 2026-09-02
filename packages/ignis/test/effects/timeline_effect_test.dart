import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('emits onStart once it starts progressing', () {
    final effect = TimelineEffect(
      timeline: .sequence([.once(.wait(0.5)), .duration(1)]),
    );
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

  test('onStart is not re-emitted per repeat lap; only once for the whole run', () {
    final effect = TimelineEffect(timeline: .repeat(.duration(1), 2));
    effect.mount();
    var starts = 0;
    effect.onStart(() => starts += 1);

    effect.update(1);
    expect(starts, 1);

    effect.update(1);
    expect(starts, 1);
  });

  test('emits onMax when a tick lands exactly on progress 1', () {
    final effect = TimelineEffect(timeline: .duration(1));
    effect.mount();
    var maxes = 0;
    effect.onMax(() => maxes += 1);

    effect.update(0.5);
    expect(maxes, 0);

    effect.update(0.5);
    expect(maxes, 1);
  });

  test('emits onMin when progress returns exactly to 0', () {
    final effect = TimelineEffect(timeline: .roundtrip(.duration(1)));

    effect.mount();
    var mins = 0;
    effect.onMin(() => mins += 1);

    effect.update(1);
    expect(mins, 0);

    effect.update(1);
    expect(mins, 1);
  });

  test('reversing within a repeat lap never redoes the initial delay', () {
    final effect = TimelineEffect(
      timeline: .sequence([.once(.wait(0.5)), .repeat(.duration(1), 2)]),
    );
    effect.mount();

    effect.update(1.5); // Clears the initial delay, finishes lap 1, into lap 2.

    effect.reverse();
    effect.update(0.5); // Recedes within lap 2, never touching the initial delay.
    expect(effect.isRunning, isTrue);

    effect.forward();
    effect.update(0.1);
    expect(effect.previousProgress, closeTo(0.6, 1e-9));
  });

  test('emits onProgress with its current progress once started', () {
    final effect = TimelineEffect(timeline: .duration(1));
    effect.mount();
    final progresses = <double>[];
    effect.onProgress(progresses.add);

    effect.update(0.25);
    effect.update(0.75);

    expect(progresses, [0.25, 1]);
  });

  test('emits onFinish once isComplete becomes true, and never again', () {
    final effect = TimelineEffect(timeline: .duration(1));
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

  test('resets back to its start', () {
    final effect = TimelineEffect(timeline: .duration(1));
    effect.mount();
    effect.update(1);
    expect(effect.isFinished, isTrue);

    effect.reset();

    expect(effect.isRunning, isFalse);
    expect(effect.isFinished, isFalse);
    expect(effect.previousProgress, 0);
  });

  test('restarts times-1 times before emitting onFinish', () {
    final effect = TimelineEffect(timeline: .repeat(.duration(1), 2));
    effect.mount();
    var finishes = 0;
    effect.onFinish(() => finishes += 1);

    effect.update(1);
    expect(effect.previousProgress, 1); // Lands exactly on lap 1's boundary.
    expect(finishes, 0);
    expect(effect.isFinished, isFalse);

    effect.update(0.5);
    expect(effect.previousProgress, 0.5);

    effect.update(0.5);
    expect(finishes, 1);
    expect(effect.isFinished, isTrue);
  });

  test('repeats forever when times is null', () {
    final effect = TimelineEffect(timeline: .infinite(.duration(1)));
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
    final effect = TimelineEffect(timeline: .repeat(.duration(1), 2));
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
    final effect = TimelineEffect(timeline: .roundtrip(.duration(1)));

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
    final effect = TimelineEffect(timeline: .duration(1));

    expect(effect.isForward, isTrue);
    expect(effect.isReverse, isFalse);
  });

  test('reverse() ticks progress backward', () {
    final effect = TimelineEffect(timeline: .duration(1));
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
    final effect = TimelineEffect(timeline: .duration(1));
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
    final effect = TimelineEffect(timeline: .duration(1));
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
    final effect = TimelineEffect(timeline: .duration(1));
    effect.mount();
    effect.reverse();

    effect.reset();

    expect(effect.isForward, isTrue);
  });

  test('forward() and reverse() implicitly enable the effect', () {
    final effect = TimelineEffect(timeline: .duration(1), enabled: false);
    expect(effect.enabled, isFalse);

    effect.forward();
    expect(effect.enabled, isTrue);

    effect.enabled = false;
    effect.reverse();
    expect(effect.enabled, isTrue);
  });

  test('detaches itself once complete when added as a child, when cleanup is true', () {
    final a = Node();
    final effect = TimelineEffect(timeline: .duration(2), cleanup: true);
    a.add(effect);
    final scene = a.mount();

    scene.update(1);
    expect(effect.isFinished, isFalse);
    expect(a.children, [effect]);

    scene.update(1);
    expect(effect.isFinished, isTrue);
    expect(a.children, [effect]);

    scene.update(0);
    expect(a.children, isEmpty);
  });
}
