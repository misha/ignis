import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('closes the gap to a fixed point at a constant speed', () {
    final node = TransformNode(position: .zero());
    final scene = node.mount();

    node.add(FollowEffect(following: .box(.new(30, 40)), speed: 10));

    scene.update(1);
    expect(node.position, Vector2(6, 8));

    scene.update(2);
    expect(node.position, Vector2(18, 24));
  });

  test('lands exactly on the target without overshoot', () {
    final node = TransformNode(position: .zero());
    final scene = node.mount();

    node.add(FollowEffect(following: .box(.new(10, 0)), speed: 10));

    scene.update(2); // Would overshoot by 10 units at this speed.
    expect(node.position, Vector2(10, 0));
  });

  test('tracks a moving goal instead of a fixed prediction', () {
    final node = TransformNode(position: .zero());
    final scene = node.mount();
    final following = PositionOwner.box(.new(100, 0));

    node.add(FollowEffect(following: following, speed: 10));

    scene.update(1); // Closes 10 units toward a goal that's 100 away.
    expect(node.position, Vector2(10, 0));

    following.position.mutate().setValues(5, 0); // The goal jumps within reach.
    scene.update(1);
    expect(node.position, Vector2(5, 0)); // Arrives instead of overshooting.
  });

  test('emits onFinish once it first catches up, and does not re-emit while parked', () {
    final node = TransformNode(position: .zero());
    final scene = node.mount();
    final effect = FollowEffect(following: .box(.new(10, 0)), speed: 10);
    var finishes = 0;
    effect.onFinish(() => finishes += 1);
    node.add(effect);

    scene.update(0.5);
    expect(finishes, 0);

    scene.update(1);
    expect(finishes, 1);

    scene.update(1); // Already caught up; no re-emission while it stays there.
    expect(finishes, 1);
  });

  test('re-emits onFinish if it catches up again later', () {
    final node = TransformNode(position: .zero());
    final scene = node.mount();
    final following = PositionOwner.box(.new(10, 0));
    final effect = FollowEffect(following: following, speed: 10);
    var finishes = 0;
    effect.onFinish(() => finishes += 1);
    node.add(effect);

    scene.update(1);
    expect(finishes, 1); // Caught up immediately.

    following.position.mutate().setValues(50, 0); // The goal moves away again.
    scene.update(1);
    expect(finishes, 1);

    scene.update(3); // Catches up a second time.
    expect(finishes, 2);
  });

  test('detaches itself once it catches up, when cleanup is true', () {
    final node = TransformNode(position: .zero());
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
