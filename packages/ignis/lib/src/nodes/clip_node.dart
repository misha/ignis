// SPDX-AI-Disclosure: none

import 'dart:ui';

import 'package:ignis/src/nodes/spatial_node.dart';

/// Clips its subtree to its [shape].
///
/// Hit-testing is not clipped: a child outside the area still answers.
class ClipNode extends SpatialNode {
  ClipNode({
    super.shape,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : super(inherit: .parent);

  @override
  void renderChildren(Canvas canvas) {
    // TODO: No-op without an explicit shape. Require one?
    shape.clip(canvas);
    super.renderChildren(canvas);
  }
}
