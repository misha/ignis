import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('applies its curve', () {
    final timeline = DurationTimeline(1, Curves.easeIn);

    timeline.advance(0.5);

    expect(timeline.progress, Curves.easeIn.transform(0.5));
  });

  test('asserts its duration is positive', () {
    expect(() => DurationTimeline(0), throwsAssertionError);
  });
}
