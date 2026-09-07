import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/collisions/nodes/collider_node.dart';
import 'package:ignis/src/core.dart';

/// The colliders a [ColliderNode] currently overlaps.
final class CollisionSet extends IterableBase<ColliderNode> {
  final Set<ColliderNode> _colliders = .identity();

  @override
  Iterator<ColliderNode> get iterator => _colliders.iterator;

  /// The owners behind these colliders.
  Iterable<Node> get owners => map((collider) => collider.owner).nonNulls;

  @internal
  void add(ColliderNode other) => _colliders.add(other);

  @internal
  void remove(ColliderNode other) => _colliders.remove(other);

  @internal
  void clear() => _colliders.clear();
}
