import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('reports the owner behind each collider, skipping those without one', () {
    final host = Node();
    final owned = ColliderNode(strict: false);
    host.add(owned);

    final group = Node();
    final named = ColliderNode(strict: false, owner: group);
    final orphan = ColliderNode(strict: false);

    final collisions = CollisionSet()
      ..add(owned)
      ..add(named)
      ..add(orphan);

    expect(collisions.owners, [host, group]);
  });

  test('reads owners through rather than holding on to them', () {
    final first = Node();
    final second = Node();
    final collider = ColliderNode(strict: false, owner: first);
    final collisions = CollisionSet()..add(collider);

    expect(collisions.owners, [first]);

    collider.owner = second;
    expect(collisions.owners, [second]);
  });
}
