import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_sink.dart';

void main() {
  test('reports frames per second over a rolling window', () {
    final counter = FpsComponent(windowSize: 2);
    Scene(Entity(components: [counter]));

    counter.post(Update(0.5));
    counter.post(Update(0.25));
    expect(counter.fps, closeTo(2.666, 0.001));

    counter.post(Update(0.25));
    expect(counter.fps, closeTo(4, 0.001));
  });

  test('posts a change only when the rounded FPS changes', () {
    final counter = FpsComponent(windowSize: 1);
    final sink = TestSink([counter]);
    Scene(sink);

    counter.post(Update(0.1)); // fps = 10
    counter.post(Update(0.1)); // fps = 10, unchanged
    counter.post(Update(0.05)); // fps = 20

    expect(sink.of<FpsChange>().map((event) => event.fps), [10, 20]);
  });

  test('ignores invalid frame durations', () {
    final counter = FpsComponent();
    Scene(Entity(components: [counter]));

    counter.post(Update(0));
    counter.post(Update(-1));
    counter.post(Update(double.nan));
    counter.post(Update(double.infinity));
    expect(counter.fps, closeTo(0, 0.001));

    counter.post(Update(0.5));
    expect(counter.fps, closeTo(2, 0.001));
  });
}
