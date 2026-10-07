// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
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
  void renderChildren(Draw draw) {
    // TODO: No-op without an explicit shape. Require one?
    shape.clip(draw.canvas);
    super.renderChildren(draw);
  }
}
