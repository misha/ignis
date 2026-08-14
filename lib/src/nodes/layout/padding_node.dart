import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:ignis/src/layout_constraints.dart';
import 'package:ignis/src/layout_engine.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/layout_node.dart';

/// Insets every child by [padding].
///
/// Roughly equivalent to Flutter's `Padding`.
class PaddingNode extends LayoutNode {
  /// The space reserved around every child. Defaults to `EdgeInsets.zero`.
  EdgeInsets padding;

  PaddingNode({
    EdgeInsets? padding,
    super.flex,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : padding = padding ?? .zero;

  @override
  Vector2 constrain(LayoutConstraints constraints) {
    return LayoutEngine.stack(
      items: layoutChildren,
      childConstraints: constraints.deflate(padding),
      computeSelfSize: (count, largest) => constraints.satisfy(
        .new(
          largest.x + padding.horizontal,
          largest.y + padding.vertical,
        ),
      ),
      computeOffset: (selfSize, childSize) => .new(padding.left, padding.top),
    );
  }
}
