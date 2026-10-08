// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:ignis/src/collisions/collision_arena.dart';
import 'package:ignis/src/collisions/collision_set.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/message.dart';
import 'package:ignis/src/nodes/spatial_node.dart';

/// A hitbox that reports overlaps against other colliders registered to the
/// same [CollisionArenaNode].
class ColliderNode extends SpatialNode {
  /// Bitmask of physics layers this collider exists on. Defaults to all 1-bits.
  int layer;

  /// Bitmask of physics layers this collider collides with. Defaults to all 1-bits.
  int mask;

  /// Whether building without a [CollisionArenaNode] ancestor throws a
  /// [StateError]. Defaults to true.
  ///
  /// While false, this collider will simply no-op (no collisions, no drawing)
  /// when added to a tree without a [CollisionArenaNode] ancestor.
  bool strict;

  /// The colliders this node currently overlaps.
  final collisions = CollisionSet();

  /// Whether this node currently overlaps anything.
  bool get isColliding => collisions.isNotEmpty;

  CollisionArena? _arena;

  ColliderNode({
    super.shape,
    int? layer,
    int? mask,
    bool? strict,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : layer = layer ?? -1,
       mask = mask ?? -1,
       strict = strict ?? true,
       super(inherit: .parent);

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        final arena = _arena = readOrNull<CollisionArena>();

        if (arena != null) {
          arena.add(this);
        } else if (strict) {
          throw StateError('ColliderNode requires a CollisionArenaNode ancestor.');
        }

      case Destroy():
        collisions.clear();
        _arena?.remove(this);
        _arena = null;
    }

    switch (message) {
      case DebugDraw(:final canvas):
        final debug = Ignis.debug;
        if (!debug.draws(.collision)) break;
        shape.draw(canvas, debug.paint);
    }
  }

  @internal
  void startCollision(ColliderNode other) {
    collisions.add(other);
    parent?.post(CollisionStart(this, other));
  }

  @internal
  void endCollision(ColliderNode other) {
    collisions.remove(other);
    parent?.post(CollisionEnd(this, other));
  }

  @internal
  void dropCollision(ColliderNode other) => collisions.remove(other);
}

/// Emitted with the other collider when [collider] starts overlapping it.
final class CollisionStart extends Message {
  final ColliderNode collider;

  final ColliderNode other;

  const CollisionStart(this.collider, this.other);
}

/// Emitted with the other collider when [collider] stops overlapping it.
final class CollisionEnd extends Message {
  final ColliderNode collider;

  final ColliderNode other;

  const CollisionEnd(this.collider, this.other);
}
