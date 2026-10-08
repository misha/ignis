import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/test_sink.dart';

void main() {
  test('detects overlapping colliders on tick', () {
    final a = ColliderNode(shape: .square(10), position: .zero);
    final b = ColliderNode(shape: .square(10), position: .new(6, 0));
    final aSink = TestSink([a]);

    CollisionArenaNode(children: [aSink, b]).mount().update(0);

    expect(aSink.of<CollisionStart>().map((event) => event.other), [b]);
  });
}
