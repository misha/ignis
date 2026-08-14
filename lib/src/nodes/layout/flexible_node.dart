import 'package:flutter/rendering.dart' show FlexFit;
import 'package:ignis/src/layout_constraints.dart';
import 'package:ignis/src/layout_engine.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/layout_node.dart';

/// Marks a single child as flexible when a direct child of a `FlexNode`, à
/// la Flutter's `Flexible`. Used standalone or nested deeper, [flex]/[fit]
/// are inert - this just forwards whatever constraints it receives to its
/// own child.
class FlexibleNode extends LayoutNode {
  /// The flex factor an ancestor `FlexNode` gives this child. Defaults to 1.
  @override
  int flex;

  /// How an ancestor `FlexNode` fits this child into its allocated space.
  /// Defaults to `loose`.
  @override
  FlexFit fit;

  FlexibleNode({
    int? flex,
    FlexFit? fit,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : flex = flex ?? 1,
       fit = fit ?? .loose;

  @override
  Vector2 constrain(LayoutConstraints constraints) {
    // TODO: Shouldn't be limited to this, I think?
    assert(
      children.whereType<Measurable>().length <= 1,
      'FlexibleNode supports at most one SizedNode child.',
    );

    final child = children.whereType<Measurable>().firstOrNull;
    if (child == null) return constraints.min;

    final size = child.measure(constraints);
    LayoutEngine.place(child, .zero);
    return size;
  }
}
