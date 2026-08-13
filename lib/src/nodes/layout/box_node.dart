import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:ignis/src/layout_constraints.dart';
import 'package:ignis/src/layout_engine.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/layout_node.dart';

/// Forces a fixed size on the space this node claims.
///
/// A null [targetWidth]/[targetHeight] leaves that axis to the largest child
/// (or zero, with none), still clamped to this node's own constraints.
///
/// Roughly equivalent to Flutter's `SizedBox`.
class BoxNode extends LayoutNode {
  /// This node's fixed width, or null to size to the largest child on this axis.
  double? targetWidth;

  /// This node's fixed height, or null to size to the largest child on this axis.
  double? targetHeight;

  /// The space reserved around every child, inside this node's own size.
  /// Defaults to `EdgeInsets.zero`.
  EdgeInsets padding;

  BoxNode({
    double? width,
    double? height,
    EdgeInsets? padding,
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
  BoxNode.square(
    double size, {
    EdgeInsets? padding,
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
    // TODO: Cache children by type.
    final items = children.whereType<Measurable>().toList(growable: false);
    final requestedX = targetWidth?.clamp(constraints.min.x, constraints.max.x).toDouble();
    final requestedY = targetHeight?.clamp(constraints.min.y, constraints.max.y).toDouble();
    final boxConstraints = LayoutConstraints(
      min: .new(requestedX ?? constraints.min.x, requestedY ?? constraints.min.y),
      max: .new(requestedX ?? constraints.max.x, requestedY ?? constraints.max.y),
    );

    return LayoutEngine.stack(
      items: items,
      childConstraints: boxConstraints.deflate(padding),
      computeSelfSize: (count, largest) => constraints.satisfy(
        .new(
          requestedX ?? (largest.x + padding.horizontal),
          requestedY ?? (largest.y + padding.vertical),
        ),
      ),
      computeOffset: (selfSize, childSize) => .new(padding.left, padding.top),
    );
  }
}
