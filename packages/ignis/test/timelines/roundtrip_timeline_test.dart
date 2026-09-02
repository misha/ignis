import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('advances forward, then back down to the start', () {
    final timeline = RoundtripTimeline(DurationTimeline(1));

    expect(timeline.duration, 2);

    expect(timeline.advance(0.5), 0);
    expect(timeline.progress, 0.5);
    expect(timeline.isFinished, isFalse);

    expect(timeline.advance(0.5), 0);
    expect(timeline.progress, 1);
    expect(timeline.isFinished, isFalse);

    expect(timeline.advance(0.5), 0);
    expect(timeline.progress, 0.5);
    expect(timeline.isFinished, isFalse);

    expect(timeline.advance(0.5), 0);
    expect(timeline.progress, 0);
    expect(timeline.isFinished, isTrue);
  });

  test('cascades overflow across the leg boundary and past the very end', () {
    final timeline = RoundtripTimeline(DurationTimeline(1));

    expect(timeline.advance(1.5), 0);
    expect(timeline.progress, 0.5);
    expect(timeline.isFinished, isFalse);

    expect(timeline.advance(1.5), 1);
    expect(timeline.progress, 0);
    expect(timeline.isFinished, isTrue);
  });

  test('recedes back through both legs symmetrically', () {
    final timeline = RoundtripTimeline(DurationTimeline(1));
    timeline.advance(2);
    expect(timeline.isFinished, isTrue);

    expect(timeline.recede(0.5), 0);
    expect(timeline.progress, 0.5);
    expect(timeline.isFinished, isFalse);

    expect(timeline.recede(1), 0);
    expect(timeline.progress, 0.5);

    expect(timeline.recede(0.5), 0);
    expect(timeline.progress, 0);
  });

  test('setToStart() and setToEnd() reset the child and both legs', () {
    final timeline = RoundtripTimeline(DurationTimeline(1));

    timeline.setToEnd();
    expect(timeline.isFinished, isTrue);
    expect(timeline.progress, 0);

    timeline.setToStart();
    expect(timeline.isFinished, isFalse);
    expect(timeline.progress, 0);
  });
}
