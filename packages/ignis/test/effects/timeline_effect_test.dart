import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_sink.dart';

void main() {
  test('emits TimelineStart once it starts progressing', () {
    final effect = TimelineEffect(
      timeline: .sequence([.once(.wait(0.5)), .duration(1)]),
    );
    final sink = TestSink([effect])..mount();

    effect.update(Update(0.25));
    expect(sink.of<TimelineStart>().length, 0);

    effect.update(Update(0.5));
    expect(sink.of<TimelineStart>().length, 1);

    effect.update(Update(0.25));
    expect(sink.of<TimelineStart>().length, 1);
  });

  test('TimelineStart is not re-emitted per repeat lap; only once for the whole run', () {
    final effect = TimelineEffect(timeline: .repeat(.duration(1), 2));
    final sink = TestSink([effect])..mount();

    effect.update(Update(1));
    expect(sink.of<TimelineStart>().length, 1);

    effect.update(Update(1));
    expect(sink.of<TimelineStart>().length, 1);
  });

  test('emits TimelineMax when a tick lands exactly on progress 1', () {
    final effect = TimelineEffect(timeline: .duration(1));
    final sink = TestSink([effect])..mount();

    effect.update(Update(0.5));
    expect(sink.of<TimelineMax>().length, 0);

    effect.update(Update(0.5));
    expect(sink.of<TimelineMax>().length, 1);
  });

  test('emits TimelineMin when progress returns exactly to 0', () {
    final effect = TimelineEffect(timeline: .roundtrip(.duration(1)));

    final sink = TestSink([effect])..mount();

    effect.update(Update(1));
    expect(sink.of<TimelineMin>().length, 0);

    effect.update(Update(1));
    expect(sink.of<TimelineMin>().length, 1);
  });

  test('reversing within a repeat lap never redoes the initial delay', () {
    final effect = TimelineEffect(
      timeline: .sequence([.once(.wait(0.5)), .repeat(.duration(1), 2)]),
    );
    effect.mount();

    effect.update(
      Update(1.5),
    ); // Clears the initial delay, finishes lap 1, into lap 2.

    effect.reverse();
    effect.update(
      Update(0.5),
    ); // Recedes within lap 2, never touching the initial delay.
    expect(effect.isRunning, isTrue);

    effect.forward();
    effect.update(Update(0.1));
    expect(effect.progress, closeTo(0.6, 1e-9));
  });

  test('emits TimelineProgress with its current progress once started', () {
    final effect = TimelineEffect(timeline: .duration(1));
    final sink = TestSink([effect])..mount();

    effect.update(Update(0.25));
    effect.update(Update(0.75));

    expect(sink.of<TimelineProgress>().map((event) => event.progress), [0.25, 1]);
  });

  test('emits EffectFinish once isComplete becomes true, and never again', () {
    final effect = TimelineEffect(timeline: .duration(1));
    final sink = TestSink([effect])..mount();

    effect.update(Update(0.5));
    expect(sink.of<EffectFinish>().length, 0);

    effect.update(Update(0.5));
    expect(sink.of<EffectFinish>().length, 1);

    effect.update(Update(1));
    expect(sink.of<EffectFinish>().length, 1);
  });

  test('resets back to its start', () {
    final effect = TimelineEffect(timeline: .duration(1));
    effect.mount();
    effect.update(Update(1));
    expect(effect.isFinished, isTrue);

    effect.reset();

    expect(effect.isRunning, isFalse);
    expect(effect.isFinished, isFalse);
    expect(effect.previousProgress, 0);
  });

  test('restarts times-1 times before emitting EffectFinish', () {
    final effect = TimelineEffect(timeline: .repeat(.duration(1), 2));
    final sink = TestSink([effect])..mount();

    effect.update(Update(1));
    expect(effect.progress, 1); // Lands exactly on lap 1's boundary.
    expect(sink.of<EffectFinish>().length, 0);
    expect(effect.isFinished, isFalse);

    effect.update(Update(0.5));
    expect(effect.progress, 0.5);

    effect.update(Update(0.5));
    expect(sink.of<EffectFinish>().length, 1);
    expect(effect.isFinished, isTrue);
  });

  test('repeats forever when times is null', () {
    final effect = TimelineEffect(timeline: .infinite(.duration(1)));
    final sink = TestSink([effect])..mount();

    for (var i = 0; i < 10; i += 1) {
      effect.update(Update(1));
      expect(effect.isFinished, isFalse);
    }

    expect(sink.of<EffectFinish>().length, 0);
  });

  test('reset() restarts the repeat count from the beginning', () {
    final effect = TimelineEffect(timeline: .repeat(.duration(1), 2));
    final sink = TestSink([effect])..mount();

    effect.update(Update(1));
    effect.update(Update(1));
    expect(sink.of<EffectFinish>().length, 1);

    effect.reset();
    effect.update(Update(1));
    effect.update(Update(1));
    expect(sink.of<EffectFinish>().length, 2);
  });

  test('only emits EffectFinish once a reverse phase completes', () {
    final effect = TimelineEffect(timeline: .roundtrip(.duration(1)));

    final sink = TestSink([effect])..mount();

    effect.update(Update(1));
    expect(effect.progress, 1); // The forward phase is done.
    expect(sink.of<EffectFinish>().length, 0);

    effect.update(Update(1));
    expect(effect.progress, 0); // Back at the start.
    expect(sink.of<EffectFinish>().length, 1);
  });

  test('defaults to running forward', () {
    final effect = TimelineEffect(timeline: .duration(1));

    expect(effect.isForward, isTrue);
    expect(effect.isReverse, isFalse);
  });

  test('reverse() ticks progress backward', () {
    final effect = TimelineEffect(timeline: .duration(1));
    effect.mount();

    effect.update(Update(0.75));
    expect(effect.progress, 0.75);

    effect.reverse();
    expect(effect.isForward, isFalse);
    expect(effect.isReverse, isTrue);

    effect.update(Update(0.5));
    expect(effect.progress, 0.25);
  });

  test('forward() resumes progress forward after reverse()', () {
    final effect = TimelineEffect(timeline: .duration(1));
    effect.mount();

    effect.update(Update(0.5));
    effect.reverse();
    effect.update(Update(0.25));
    expect(effect.progress, 0.25);

    effect.forward();
    effect.update(Update(0.25));
    expect(effect.progress, 0.5);
  });

  test('reversing off the end un-finishes the effect', () {
    final effect = TimelineEffect(timeline: .duration(1));
    final sink = TestSink([effect])..mount();

    effect.update(Update(1));
    expect(effect.isFinished, isTrue);

    effect.reverse();
    effect.update(Update(0.5));
    expect(effect.isFinished, isFalse);
    expect(effect.progress, 0.5);
    expect(sink.of<EffectFinish>().length, 1);
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
