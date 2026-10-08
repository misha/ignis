import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_sink.dart';

void main() {
  test('defaults to firing once, with count defaulting to 1, without detaching', () {
    final timer = TimerComponent(interval: 1);

    expect(timer.repeat, isFalse);
    expect(timer.count, 1);
    expect(timer.cleanup, isFalse);
  });

  test('passing null for repeat, count, or cleanup falls back to their defaults', () {
    final timer = TimerComponent(interval: 1, repeat: null, count: null, cleanup: null);

    expect(timer.repeat, isFalse);
    expect(timer.count, 1);
    expect(timer.cleanup, isFalse);
  });

  test('emits TimerTrigger once interval seconds elapse', () {
    final timer = TimerComponent(interval: 1);
    final sink = TestSink([timer]);
    Scene(sink);

    timer.post(Update(0.5));
    expect(sink.of<TimerTrigger>().length, 0);

    timer.post(Update(0.5));
    expect(sink.of<TimerTrigger>().length, 1);
  });

  test('detaches itself once it triggers, when cleanup is true', () {
    final a = TestSink();
    final timer = TimerComponent(interval: 1, cleanup: true);
    a.components.add(timer);
    final scene = Scene(a);

    scene.update(0.5);
    expect(a.of<TimerTrigger>().length, 0);
    expect(timer.isFinished, isFalse);
    expect(a.components, [timer]);

    scene.update(0.5);
    expect(a.of<TimerTrigger>().length, 1);
    expect(timer.isFinished, isTrue);
    expect(a.components, [timer]); // Still pending.

    scene.update(0);
    expect(a.components, isEmpty);
  });

  test('triggers count times before finishing, then detaches', () {
    final a = TestSink();
    final timer = TimerComponent(interval: 1, count: 2, cleanup: true);
    a.components.add(timer);
    final scene = Scene(a);

    scene.update(3);
    expect(a.of<TimerTrigger>().length, 2);

    scene.update(0);
    expect(a.components, isEmpty);
  });

  test('repeat overrides count, triggering indefinitely', () {
    final a = TestSink();
    final timer = TimerComponent(interval: 1, repeat: true, count: 1);
    a.components.add(timer);
    final scene = Scene(a);

    scene.update(5.5);
    expect(a.of<TimerTrigger>().length, 5);
    expect(timer.isFinished, isFalse); // Never finishes, so it never detaches.
    expect(a.components, [timer]);
  });

  test('does not detach when finished if cleanup is false', () {
    final a = TestSink();
    final timer = TimerComponent(interval: 1, cleanup: false);
    a.components.add(timer);
    final scene = Scene(a);

    scene.update(1);
    expect(a.of<TimerTrigger>().length, 1);
    expect(timer.isFinished, isTrue);

    scene.update(5);
    expect(a.of<TimerTrigger>().length, 1); // Finished, so further ticks are no-ops.
    expect(a.components, [timer]);
  });

  test('reset restarts a finished timer that was not cleaned up', () {
    final timer = TimerComponent(interval: 1, cleanup: false);
    final sink = TestSink([timer]);
    Scene(sink);

    timer.post(Update(1));
    expect(sink.of<TimerTrigger>().length, 1);

    timer.post(Update(1));
    expect(sink.of<TimerTrigger>().length, 1); // Finished, so this tick is a no-op.

    timer.reset();
    expect(timer.isFinished, isFalse);

    timer.post(Update(1));
    expect(sink.of<TimerTrigger>().length, 2);
  });

  test('reset lets a count-limited timer trigger count more times', () {
    final timer = TimerComponent(interval: 1, count: 2, cleanup: false);
    final sink = TestSink([timer]);
    Scene(sink);

    timer.post(Update(3));
    expect(sink.of<TimerTrigger>().length, 2);

    timer.reset();
    timer.post(Update(3));
    expect(sink.of<TimerTrigger>().length, 4);
  });
}
