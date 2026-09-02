import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('advances through children in order, cascading overflow', () {
    final timeline = SequenceTimeline([
      .duration(1),
      .duration(1),
    ]);

    expect(timeline.advance(1.5), 0);
    expect(timeline.progress, 0.5);
    expect(timeline.isFinished, isFalse);

    expect(timeline.advance(0.5), 0);
    expect(timeline.progress, 1);
    expect(timeline.isFinished, isTrue);
  });

  test('delegates progress and hasStarted to the current child', () {
    final timeline = SequenceTimeline([
      .once(.wait(0.5)),
      .duration(1),
    ]);

    expect(timeline.hasStarted, isFalse);
    expect(timeline.progress, 1);

    timeline.advance(0.5);
    expect(timeline.hasStarted, isTrue);

    timeline.advance(0.25);
    expect(timeline.progress, 0.25);
  });

  test('recedes back through children in reverse order', () {
    final timeline = SequenceTimeline([
      .duration(1),
      .duration(1),
    ]);

    timeline.advance(1.5);

    expect(timeline.recede(1), 0);
    expect(timeline.progress, 0.5);

    expect(timeline.recede(0.5), 0);
    expect(timeline.progress, 0);
  });

  test('setToStart() and setToEnd() reset every child', () {
    final timeline = SequenceTimeline([
      .duration(1),
      .duration(1),
    ]);

    timeline.setToEnd();
    expect(timeline.isFinished, isTrue);
    expect(timeline.progress, 1);

    timeline.setToStart();
    expect(timeline.isFinished, isFalse);
    expect(timeline.progress, 0);

    timeline.advance(1.5);
    timeline.setToStart();
    expect(timeline.progress, 0);
  });

  test('asserts at least 1 child is given', () {
    expect(() => SequenceTimeline([]), throwsAssertionError);
  });
}
