// SPDX-AI-Disclosure: none

import 'package:ignis/src/layout/nodes/flex_node.dart';

/// Lays its children out horizontally, equivalent to Flutter's `Row`.
class RowNode extends FlexNode {
  RowNode({
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
  }) : super(direction: .horizontal);
}
