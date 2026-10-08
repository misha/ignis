import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_sink.dart';

void main() {
  test('emits EffectFinish once it first catches up, and does not re-emit while parked', () {
    final node = SpatialNode(position: .zero);
    final scene = node.mount();
    final effect = FollowEffect(following: .box(.new(10, 0)), speed: 10);
    final sink = TestSink([effect]);
    node.add(sink);

    scene.update(0.5);
    expect(sink.of<EffectFinish>().length, 0);

    scene.update(1);
    expect(sink.of<EffectFinish>().length, 1);

    scene.update(1); // Already caught up; no re-emission while it stays there.
    expect(sink.of<EffectFinish>().length, 1);
  });

  test('re-emits EffectFinish if it catches up again later', () {
    final node = SpatialNode(position: .zero);
    final scene = node.mount();
    final following = PositionOwner.box(.new(10, 0));
    final effect = FollowEffect(following: following, speed: 10);
    final sink = TestSink([effect]);
    node.add(sink);

    scene.update(1);
    expect(sink.of<EffectFinish>().length, 1); // Caught up immediately.

    following.position.setValues(50, 0); // The goal moves away again.
    scene.update(1);
    expect(sink.of<EffectFinish>().length, 1);

    scene.update(3); // Catches up a second time.
    expect(sink.of<EffectFinish>().length, 2);
  });

  test('detaches itself once it catches up, when cleanup is true', () {
    final node = SpatialNode(position: .zero);
    final scene = node.mount();

    node.add(
      FollowEffect(
        following: .box(.new(10, 0)),
        speed: 10,
        cleanup: true,
      ),
    );

    scene.update(1); // Catches up and detaches.
    scene.update(0); // Flush the self-detach.
    expect(node.children, isEmpty);
  });
}
