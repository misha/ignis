// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:ignis/src/collisions/collision_arena.dart';
import 'package:ignis/src/collisions/collision_set.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/globals.dart';
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

  Node? _owner;

  /// The node this collider stands for. Defaults to its [parent].
  ///
  /// A collider is usually a hitbox for the node above it, but one placed
  /// deeper in a subtree, or shared by a group, says who it belongs to here.
  Node? get owner => _owner ?? parent;

  set owner(Node? value) => _owner = value;

  /// Emitted with the other collider when this collider starts overlapping it.
  final onCollisionStart = Signal1<ColliderNode>();

  /// Emitted with the other collider when this collider stops overlapping it.
  final onCollisionEnd = Signal1<ColliderNode>();

  /// The colliders this node currently overlaps.
  final collisions = CollisionSet();

  /// Whether this node currently overlaps anything.
  bool get isColliding => collisions.isNotEmpty;

  ColliderNode({
    super.shape,
    int? layer,
    int? mask,
    bool? strict,
    this._owner,
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
  void build() {
    super.build();

    final arena = readOrNull<CollisionArena>();

    if (arena == null) {
      if (strict) {
        throw StateError('ColliderNode requires a CollisionArenaNode ancestor.');
      } else {
        return;
      }
    }

    arena.add(this);
    trash(collisions.clear);

    debugDraw((canvas) {
      final debug = Ignis.debug;
      if (!debug.draws(.collision)) return;
      shape.draw(canvas, debug.paint);
    });
  }

  @internal
  void startCollision(ColliderNode other) {
    collisions.add(other);
    onCollisionStart.emit(other);
  }

  @internal
  void endCollision(ColliderNode other) {
    collisions.remove(other);
    onCollisionEnd.emit(other);
  }

  @internal
  void dropCollision(ColliderNode other) => collisions.remove(other);
}
