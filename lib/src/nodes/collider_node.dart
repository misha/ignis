import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/debug.dart';
import 'package:ignis/src/nodes/collision_detection_node.dart';
import 'package:ignis/src/nodes/sized_node.dart';
import 'package:ignis/src/shape.dart';
import 'package:ignis/src/signal.dart';

/// A hitbox that reports overlaps against other colliders registered to the
/// same [CollisionDetectionNode].
///
/// Does nothing if no [CollisionDetectionNode] ancestor is found.
class ColliderNode extends SizedNode {
  /// The shape of the collider's hitbox.
  Shape shape;

  /// Bitmask of physics layers this collider exists on. Defaults to all 1-bits.
  int layer;

  /// Bitmask of physics layers this collider collides with. Defaults to all 1-bits.
  int mask;

  /// Emitted with the other collider when this collider starts overlapping it.
  final onCollisionStart = Signal1<ColliderNode>();

  /// Emitted with the other collider when this collider stops overlapping it.
  final onCollisionEnd = Signal1<ColliderNode>();

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
       mask = mask ?? -1 {
    onMount(() {
      cd = ancestors.whereType<CollisionDetectionNode>().firstOrNull;
      cd?.register(this);
    });

    onUnmount(() {
      cd?.unregister(this);
      cd = null;
    });
  }

  @override
  double get width => shape.width;

  @override
  double get height => shape.height;

  @override
  void debugRenderAnchored(Canvas canvas) {
    canvas.drawRect(shape.rect(), DEBUG_COLLIDER_PAINT);
  }
}
