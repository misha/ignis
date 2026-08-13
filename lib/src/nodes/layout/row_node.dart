import 'package:ignis/src/nodes/layout/flex_node.dart';

/// Lays its children out horizontally, equivalent to Flutter's `Row`.
class RowNode extends FlexNode {
  RowNode({
    super.mainAxisAlignment,
    super.crossAxisAlignment,
    super.mainAxisSize,
    super.reverse,
    super.spacing,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : super(direction: .horizontal);
}
