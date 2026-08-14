import 'package:ignis/src/nodes/layout/flex_node.dart';

/// Lays its children out vertically, equivalent to Flutter's `Column`.
class ColumnNode extends FlexNode {
  ColumnNode({
    super.mainAxisAlignment,
    super.crossAxisAlignment,
    super.mainAxisSize,
    super.spacing,
    super.flex,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : super(direction: .vertical);
}
