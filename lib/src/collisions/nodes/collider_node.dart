import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/collisions/nodes/collision_detection_node.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/debug.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/sized_node.dart';
import 'package:ignis/src/shape.dart';

/// A hitbox that reports overlaps against other colliders registered to the
/// same [CollisionDetectionNode].
///
/// Does nothing if no [CollisionDetectionNode] ancestor is found.
class ColliderNode extends SizedNode {
  /// The shape of the collider's hitbox.
  Shape shape;

  @override
  Vector2 get size => shape.size;

  /// Bitmask of physics layers this collider exists on. Defaults to all 1-bits.
  int layer;

  /// Bitmask of physics layers this collider collides with. Defaults to all 1-bits.
  int mask;

  /// Emitted with the other collider when this collider starts overlapping it.
  final onCollisionStart = Signal1<ColliderNode>();

  /// Emitted with the other collider when this collider stops overlapping it.
  final onCollisionEnd = Signal1<ColliderNode>();

  final Set<ColliderNode> _active = .identity();

  /// Colliders this node currently overlaps.
  Iterable<ColliderNode> get active => _active;

  /// Whether this node currently overlaps anything.
  bool get isColliding => _active.isNotEmpty;

  @internal
  CollisionDetectionNode? cd;

  ColliderNode({
    required this.shape,
    int? layer,
    int? mask,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : layer = layer ?? -1,
       mask = mask ?? -1;

  @override
  void build() {
    super.build();
    cd = ancestors.whereType<CollisionDetectionNode>().firstOrNull;
    cd?.register(this);

    void unregister() {
      cd?.unregister(this);
      cd = null;
      _active.clear();
    }

    trash << unregister;
    onCollisionStart(_active.add);
    onCollisionEnd(_active.remove);
  }

  /// Removes [other] from [active] without emitting [onCollisionEnd], for when
  /// a collision is dropped because a member left the arena, not because it
  /// stopped overlapping.
  @internal
  void dropCollision(ColliderNode other) => _active.remove(other);

  @override
  void debugRenderAnchored(Canvas canvas) {
    canvas.drawRect(shape.rect(), DEBUG_COLLIDER_PAINT);
  }
}
