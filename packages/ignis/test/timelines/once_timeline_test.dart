import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('is not started until its child finishes', () {
    final timeline = OnceTimeline(WaitTimeline(0.5));

    expect(timeline.hasStarted, isFalse);

    timeline.advance(0.25);
    expect(timeline.hasStarted, isFalse);

    expect(timeline.advance(0.75), 0.5);
    expect(timeline.hasStarted, isTrue);
  });

  test('advancing past its child finishing still returns the leftover time', () {
    final timeline = OnceTimeline(WaitTimeline(0.5));

    expect(timeline.advance(0.5), 0);
    expect(timeline.advance(0.5), 0.5);
  });

  test('ignores recede once finished, leaving its child untouched', () {
    final timeline = OnceTimeline(WaitTimeline(0.5));
    timeline.advance(0.5);

    expect(timeline.recede(0.5), 0.5);
    expect(timeline.isFinished, isTrue);
    expect(timeline.child.isFinished, isTrue);
  });

  test('ignores setToStart() once finished, so a repeat never redoes it', () {
    final timeline = OnceTimeline(WaitTimeline(0.5));
    timeline.advance(0.5);

    timeline.setToStart();

    expect(timeline.isFinished, isTrue);
    expect(timeline.progress, 1);
  });

  test('setToStart() before finishing resets its child normally', () {
    final timeline = OnceTimeline(DurationTimeline(1));
    timeline.advance(0.5);

    timeline.setToStart();

    expect(timeline.progress, 0);
    expect(timeline.isFinished, isFalse);
  });

  test('setToEnd() delegates to its child and finishes', () {
    final timeline = OnceTimeline(DurationTimeline(1));

    timeline.setToEnd();

    expect(timeline.progress, 1);
    expect(timeline.isFinished, isTrue);
  });

  test('delegates duration and progress to its child', () {
    final timeline = OnceTimeline(WaitTimeline(0.5));

    expect(timeline.duration, 0.5);
    expect(timeline.progress, 1);
  });
}
