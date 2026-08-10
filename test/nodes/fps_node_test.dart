import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('reports frames per second over a rolling window', () {
    final node = FpsNode(windowSize: 2);
    node.mount();

    node.update(0.5);
    node.update(0.25);
    expect(node.fps, closeTo(2.666, 0.001));

    node.update(0.25);
    expect(node.fps, closeTo(4, 0.001));
  });

  test('emits onUpdate only when the rounded FPS changes', () {
    final node = FpsNode(windowSize: 1);
    node.mount();

    final updates = <int>[];
    node.onUpdate((value) => updates.add(value));

    node.update(0.1); // fps = 10
    node.update(0.1); // fps = 10, unchanged
    node.update(0.05); // fps = 20

    expect(updates, [10, 20]);
  });

  test('ignores invalid frame durations', () {
    final node = FpsNode();
    node.mount();

    node.update(0);
    node.update(-1);
    node.update(double.nan);
    node.update(double.infinity);
    expect(node.fps, closeTo(0, 0.001));

    node.update(0.5);
    expect(node.fps, closeTo(2, 0.001));
  });
}
