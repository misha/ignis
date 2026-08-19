import 'package:flutter/foundation.dart';
import 'package:ignis/src/collisions/nodes/collision_detection_node.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/sized_node.dart';
import 'package:ignis/src/shape.dart';

/// A hitbox that reports overlaps against other colliders registered to the
/// same [CollisionDetectionNode].
class ColliderNode extends SizedNode {
  /// The shape of the collider's hitbox.
  Shape shape;

  @override
  Vector2 get size => shape.size;

  /// Bitmask of physics layers this collider exists on. Defaults to all 1-bits.
  int layer;

  /// Bitmask of physics layers this collider collides with. Defaults to all 1-bits.
  int mask;

  /// Whether building without a [CollisionDetectionNode] ancestor throws a
  /// [StateError]. Defaults to true.
  ///
  /// While false, such a collider builds and reports nothing.
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

  @internal
  CollisionDetectionNode? cd;

  ColliderNode({
    required this.shape,
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
       strict = strict ?? true;

  @override
  void build() {
    super.build();
    cd = ancestors.whereType<CollisionDetectionNode>().firstOrNull;

    if (strict && cd == null) {
      throw StateError('ColliderNode requires a CollisionDetectionNode ancestor.');
    }

    cd?.register(this);

    trash(() {
      cd?.unregister(this);
      cd = null;
      _active.clear();
    });

    debugDraw((canvas) {
      final debug = Ignis.debug;
      if (!debug.draws(.collisions)) return;
      canvas.drawRect(shape.rect(), debug.collisionPaint);
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
