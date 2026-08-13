import 'package:ignis/src/nodes/layout/flexible_node.dart';

/// A [FlexibleNode] that forces its main-axis extent to fill the space a
/// `FlexNode` allocates it, equivalent to Flutter's `Expanded`.
class ExpandedNode extends FlexibleNode {
  ExpandedNode({
    super.flex,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : super(fit: .tight);
}
