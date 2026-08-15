import 'package:flutter/rendering.dart'
    show Axis, CrossAxisAlignment, MainAxisAlignment, MainAxisSize;
import 'package:ignis/src/layout/layout_constraints.dart';
import 'package:ignis/src/layout/layout_engine.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/layout_node.dart';

/// Lays its children out along [direction], giving each child a share of the
/// leftover space by its [LayoutNode.flex].
///
/// Usable directly when [direction] varies, à la Flutter's `Flex`. `RowNode`
/// and `ColumnNode` are the same thing with the axis fixed.
class FlexNode extends LayoutNode {
  /// The axis children are laid out along.
  final Axis direction;

  /// How children are placed along [direction]. Defaults to `start`.
  MainAxisAlignment mainAxisAlignment;

  /// How children are placed across [direction]. Defaults to `center`.
  /// `stretch` only affects [LayoutNode] children - a fixed-size leaf can't
  /// be resized, so it falls back to `start`. `baseline` isn't supported and
  /// also falls back to `start`.
  CrossAxisAlignment crossAxisAlignment;

  /// How much of [direction]'s available space this node claims. Defaults
  /// to `max`.
  MainAxisSize mainAxisSize;

  /// Extra space inserted between each pair of adjacent children. Defaults
  /// to 0.
  double spacing;

  FlexNode({
    required this.direction,
    MainAxisAlignment? mainAxisAlignment,
    CrossAxisAlignment? crossAxisAlignment,
    MainAxisSize? mainAxisSize,
    double? spacing,
    super.flex,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : assert(spacing == null || spacing >= 0, 'spacing cannot be negative.'),
       mainAxisAlignment = mainAxisAlignment ?? .start,
       crossAxisAlignment = crossAxisAlignment ?? .center,
       mainAxisSize = mainAxisSize ?? .max,
       spacing = spacing ?? 0;

  @override
  Vector2 constrain(LayoutConstraints constraints) {
    return LayoutEngine.flex(
      direction: direction,
      constraints: constraints,
      items: layoutChildren,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      spacing: spacing,
    );
  }
}
