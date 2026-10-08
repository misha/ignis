import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_sink.dart';

void main() {
  test('reports frames per second over a rolling window', () {
    final node = FpsNode(windowSize: 2);
    node.mount();

    node.update(Update(0.5));
    node.update(Update(0.25));
    expect(node.fps, closeTo(2.666, 0.001));

    node.update(Update(0.25));
    expect(node.fps, closeTo(4, 0.001));
  });

  test('emits FpsUpdate only when the rounded FPS changes', () {
    final node = FpsNode(windowSize: 1);
    final sink = TestSink([node])..mount();

    node.update(Update(0.1)); // fps = 10
    node.update(Update(0.1)); // fps = 10, unchanged
    node.update(Update(0.05)); // fps = 20

    expect(sink.of<FpsUpdate>().map((event) => event.fps), [10, 20]);
  });

  test('ignores invalid frame durations', () {
    final node = FpsNode();
    node.mount();

    node.update(Update(0));
    node.update(Update(-1));
    node.update(Update(double.nan));
    node.update(Update(double.infinity));
    expect(node.fps, closeTo(0, 0.001));

    node.update(Update(0.5));
    expect(node.fps, closeTo(2, 0.001));
  });
}
