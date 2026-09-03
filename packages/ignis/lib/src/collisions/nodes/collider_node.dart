// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:ignis/src/collisions/nodes/collision_arena_node.dart';
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

  /// Emitted with the other collider when this collider starts overlapping it.
  final onCollisionStart = Signal1<ColliderNode>();

  /// Emitted with the other collider when this collider stops overlapping it.
  final onCollisionEnd = Signal1<ColliderNode>();

  final Set<ColliderNode> _active = .identity();

  /// Colliders this node currently overlaps.
  Iterable<ColliderNode> get active => _active;

  /// Whether this node currently overlaps anything.
  bool get isColliding => _active.isNotEmpty;

  late final _target = Target<CollisionArenaNode?>(this);

  /// The arena this collider reports to, if there is one above it.
  @internal
  CollisionArenaNode? get arena => _target.value;

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
  void build() {
    super.build();

    final arena = this.arena;

    if (arena == null) {
      if (strict) {
        throw StateError('ColliderNode requires a CollisionArenaNode ancestor.');
      } else {
        return;
      }
    }

    arena.register(this);

    trash(() {
      arena.unregister(this);
      _active.clear();
    });

    debugDraw((canvas) {
      final debug = Ignis.debug;
      if (!debug.draws(.collision)) return;
      shape.draw(canvas, debug.paint);
    });
  }

  @internal
  void startCollision(ColliderNode other) {
    _active.add(other);
    onCollisionStart.emit(other);
  }

  @internal
  void endCollision(ColliderNode other) {
    _active.remove(other);
    onCollisionEnd.emit(other);
  }

  @internal
  void dropCollision(ColliderNode other) => _active.remove(other);
}
