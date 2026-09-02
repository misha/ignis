import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('holds progress at 1 while running', () {
    final timeline = WaitTimeline(1);

    expect(timeline.progress, 1);

    timeline.advance(0.5);
    expect(timeline.progress, 1);
    expect(timeline.isFinished, isFalse);

    timeline.advance(0.5);
    expect(timeline.progress, 1);
    expect(timeline.isFinished, isTrue);
  });

  test('is always considered started', () {
    final timeline = WaitTimeline(1);

    expect(timeline.hasStarted, isTrue);
  });

  test('returns overflow once its duration elapses', () {
    final timeline = WaitTimeline(1);

    expect(timeline.advance(1.5), 0.5);
  });

  test('asserts its duration is positive; use TerminalTimeline for zero', () {
    expect(() => WaitTimeline(0), throwsAssertionError);
  });
}
