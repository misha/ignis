import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('detects overlapping colliders on tick', () {
    final cd = CollisionDetectionNode();
    final a = ColliderNode(shape: .square(10), position: .zero());
    final b = ColliderNode(shape: .square(10), position: .new(6, 0));
    final aStarted = <ColliderNode>[];
    a.onCollisionStart(aStarted.add);

    cd
      ..register(a)
      ..register(b)
      ..tick(0);

    expect(aStarted, [b]);
  });
}
