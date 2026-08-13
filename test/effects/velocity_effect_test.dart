import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('moves its parent at a constant velocity, forever', () {
    final node = TransformNode(position: .new(10, 20));
    final scene = node.mount();

    node.add(VelocityEffect(velocity: .new(4, -2)));

    scene.update(1);
    expect(node.position, Vector2(14, 18));

    scene.update(2);
    expect(node.position, Vector2(22, 14));
  });

  test('re-reads velocity every tick', () {
    final node = TransformNode(position: .zero());
    final scene = node.mount();
    final velocity = Vector2(10, 0);

    node.add(VelocityEffect(velocity: velocity));

    scene.update(1);
    expect(node.position, Vector2(10, 0));

    velocity.mutate().setValues(0, 5);
    scene.update(1);
    expect(node.position, Vector2(10, 5));
  });

  test('never emits onFinish', () {
    final node = TransformNode();
    final scene = node.mount();
    final effect = VelocityEffect(velocity: .new(1, 0));
    var finishes = 0;
    effect.onFinish(() => finishes += 1);
    node.add(effect);

    scene.update(100);
    expect(finishes, 0);
  });

  test('speed reads velocity\'s magnitude', () {
    final effect = VelocityEffect(velocity: .new(3, 4));
    expect(effect.speed, 5);
  });

  test('setting speed rescales velocity, preserving direction', () {
    final effect = VelocityEffect(velocity: .new(3, 4));
    effect.speed = 10;
    expect(effect.velocity.x, closeTo(6, 1e-9));
    expect(effect.velocity.y, closeTo(8, 1e-9));
  });

  test('setting speed on a zero velocity is a no-op', () {
    final effect = VelocityEffect(velocity: .zero());
    effect.speed = 10;
    expect(effect.velocity, Vector2.zero());
  });
}
