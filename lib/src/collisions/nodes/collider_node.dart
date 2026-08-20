import 'package:flutter/foundation.dart';
import 'package:ignis/src/collisions/nodes/collision_detection_node.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/shape.dart';

/// A hitbox that reports overlaps against other colliders registered to the
/// same [CollisionDetectionNode].
class ColliderNode extends SpatialNode {
  Shape? _shape;

  /// The shape of the collider's hitbox.
  ///
  /// Left unstated, it takes the shape in effect at its parent, so one sitting
  /// under a shape or a sprite covers it without restating anything.
  @override
  Shape get shape => _shape ?? super.shape;

  /// Sets the shape, or hands it back to the chain with null.
  set shape(Shape? value) => _shape = value;

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
    Shape? shape,
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
       strict = strict ?? true {
    _shape = shape;
  }

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
