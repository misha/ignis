import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('never finishes', () {
    final timeline = InfiniteTimeline(.duration(1));

    expect(timeline.duration, double.infinity);
    expect(timeline.isInfinite, isTrue);

    timeline.advance(100);
    expect(timeline.isFinished, isFalse);
  });

  test('loops its child, wrapping progress around', () {
    final timeline = InfiniteTimeline(.duration(1));

    expect(timeline.advance(2.25), 0);
    expect(timeline.progress, 0.25);
  });

  test('recedes backward, wrapping progress around', () {
    final timeline = InfiniteTimeline(.duration(1));
    timeline.advance(2.25);

    expect(timeline.recede(0.5), 0);
    expect(timeline.progress, closeTo(0.75, 1e-9));
  });
}
