import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/layout_engine.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/transform_node.dart';
import 'package:ignis/src/owners/anchor_owner.dart';
import 'package:ignis/src/shape.dart';

/// A [TransformNode] with a [size], defining an area for shapes,
/// hit-testing, rendering, and other systems to work against.
abstract class SizedNode extends TransformNode with Measurable implements AnchorOwner {
  /// This node's size, as a [Vector2].
  @override
  Vector2 get size;

  /// Where this node's area sits relative to [position]. Defaults to `topLeft`.
  @override
  Anchor anchor;

  SizedNode({
    Anchor? anchor,
    super.position,
    super.scale,
    super.angle,
    super.enabled,
    super.priority,
    super.children,
  }) : anchor = anchor ?? .topLeft();

  static final _CENTER_SCRATCH = Vector2.zero();
  static final _HALF_EXTENTS_SCRATCH = Vector2.zero();

  final Aabb2 _lastWorldBounds = Aabb2();

  /// This node's world-space AABB for [shape], given its already-computed
  /// [transform] (see [absoluteTransform]).
  ///
  /// The returned AABB is owned by this node and should not be retained.
  ///
  /// TODO: Reconsider this name - it no longer computes a transform itself,
  /// just applies one the caller already has.
  Aabb2 worldBounds(Shape shape, Matrix3 transform) {
    final bounds = _lastWorldBounds;
    final width = shape.width;
    final height = shape.height;

    // Compute the shape's center, adjusted for the anchor and absolute transform.
    _CENTER_SCRATCH.mutate()
      ..setValues(width * (0.5 - anchor.x), height * (0.5 - anchor.y))
      ..transformWith(transform);

    // Compute the shape's half-extents, adjusted for absolute rotation (*not* transform).
    _HALF_EXTENTS_SCRATCH.mutate()
      ..setValues(width / 2, height / 2)
      ..absoluteRotate2With(transform);

    bounds.mutate().setCenterAndHalfExtents(_CENTER_SCRATCH, _HALF_EXTENTS_SCRATCH);
    return bounds;
  }

  @override
  void renderTransformed(Canvas canvas) {
    final offsetX = -anchor.x * width;
    final offsetY = -anchor.y * height;
    canvas.translate(offsetX, offsetY);
    renderAnchored(canvas);
    canvas.translate(-offsetX, -offsetY);
  }

  /// Draws this node's visuals, in a coordinate space where (0, 0) is
  /// [width]/[height]'s [anchor]-adjusted top-left corner.
  @visibleForOverriding
  void renderAnchored(Canvas canvas) {
    // Nothing to do.
  }

  @override
  void debugRenderTransformed(Canvas canvas) {
    super.debugRenderTransformed(canvas);
    final offsetX = -anchor.x * width;
    final offsetY = -anchor.y * height;
    canvas.translate(offsetX, offsetY);
    debugRenderAnchored(canvas);
    canvas.translate(-offsetX, -offsetY);
  }

  /// Draws this node's debug visuals, in the same coordinate space as
  /// [renderAnchored].
  @visibleForOverriding
  void debugRenderAnchored(Canvas canvas) {
    // Nothing to do.
  }
}
