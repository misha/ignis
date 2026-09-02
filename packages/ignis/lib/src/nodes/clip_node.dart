// SPDX-AI-Disclosure: ai-generated

import 'dart:ui';

import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/shape.dart';

/// Clips its subtree to its [shape].
///
/// Hit-testing is not clipped: a child outside the area still answers.
class ClipNode extends SpatialNode {
  Shape? _shape;

  /// The area clipped to.
  ///
  /// If not explicitly set, defaults to the parent's shape.
  @override
  Shape get shape => _shape ?? super.shape;

  /// Sets the area clipped to.
  ///
  /// If null, defaults back to the parent's shape.
  set shape(Shape? value) => _shape = value;

  ClipNode({
    this._shape,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  });

  @override
  void renderChildren(Canvas canvas) {
    shape.clip(canvas);
    super.renderChildren(canvas);
  }
}
