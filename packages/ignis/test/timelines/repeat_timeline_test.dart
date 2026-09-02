import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('repeats its child, carrying overflow into the next lap', () {
    final timeline = RepeatTimeline(.duration(1), 2);

    expect(timeline.advance(1.25), 0);
    expect(timeline.progress, 0.25);
    expect(timeline.isFinished, isFalse);

    expect(timeline.advance(0.75), 0);
    expect(timeline.progress, 1);
    expect(timeline.isFinished, isTrue);
  });

  test(
    'the lap transition needs a following nonzero advance once landed exactly on the boundary',
    () {
      final timeline = RepeatTimeline(.duration(1), 2);

      expect(timeline.advance(1), 0);
      expect(timeline.progress, 1);
      expect(timeline.isFinished, isFalse);

      expect(timeline.advance(0.5), 0);
      expect(timeline.progress, 0.5);
    },
  );

  test('finishes exactly once the last lap lands on the boundary', () {
    final timeline = RepeatTimeline(.duration(1), 2);

    timeline.advance(1.5);
    expect(timeline.advance(0.5), 0);

    expect(timeline.isFinished, isTrue);
    expect(timeline.progress, 1);
  });

  test('recedes back into a previous lap', () {
    final timeline = RepeatTimeline(.duration(1), 2);
    timeline.advance(1.5);

    expect(timeline.recede(1), 0);
    expect(timeline.progress, 0.5);
  });

  test('setToStart() and setToEnd() reset the repeat count', () {
    final timeline = RepeatTimeline(.duration(1), 2);

    timeline.setToEnd();
    expect(timeline.isFinished, isTrue);

    timeline.setToStart();
    expect(timeline.isFinished, isFalse);
    expect(timeline.progress, 0);
  });

  test('asserts times is positive and its child is not infinite', () {
    expect(() => RepeatTimeline(.duration(1), 0), throwsAssertionError);
    expect(
      () => RepeatTimeline(InfiniteTimeline(.duration(1)), 2),
      throwsAssertionError,
    );
  });
}
