import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/layout_constraints.dart';
import 'package:ignis/src/layout_engine.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/layout_node.dart';

/// Claims a region, optionally at a fixed size, and places every child inside
/// it under a shared [padding] and [alignment].
///
/// A null [targetWidth]/[targetHeight] leaves that axis to the largest child
/// plus [padding], still clamped to this node's own constraints, so it fills
/// under tight constraints and shrink-wraps under unbounded ones.
///
/// Roughly equivalent to Flutter's `Container`.
class BoxNode extends LayoutNode {
  /// This node's fixed width, or null to size to the largest child on this axis.
  double? targetWidth;

  /// This node's fixed height, or null to size to the largest child on this axis.
  double? targetHeight;

  /// The space reserved around every child, inside this node's own size.
  /// Defaults to `EdgeInsets.zero`.
  EdgeInsets padding;

  /// Where each child sits in the room left over inside [padding], as a
  /// fraction of that room on each axis.
  Anchor? alignment;

  BoxNode({
    double? width,
    double? height,
    EdgeInsets? padding,
    this.alignment,
    super.flex,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : targetWidth = width,
       targetHeight = height,
       padding = padding ?? .zero;

  /// A [BoxNode] with [targetWidth] and [targetHeight] both set to [size].
  BoxNode.square({
    required double size,
    EdgeInsets? padding,
    this.alignment,
    super.flex,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : targetWidth = size,
       targetHeight = size,
       padding = padding ?? .zero;

  @override
  Vector2 constrain(LayoutConstraints constraints) {
    return LayoutEngine.box(
      items: layoutChildren,
      constraints: constraints,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      padding: padding,
      alignment: alignment,
    );
  }
}
