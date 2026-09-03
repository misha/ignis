// SPDX-AI-Disclosure: none

import 'dart:ui';

import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/palette.dart';

class ShapeNode extends SpatialNode {
  /// This node's registered paints.
  final Palette palette;

  /// The default paint.
  Paint get paint => palette.paint;

  ShapeNode({
    super.shape,
    Paint? paint,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : palette = Palette(paint: paint),
       super(inherit: .parent);

  @override
  void build() {
    super.build();

    draw((canvas) {
      palette.draw(canvas, shape.draw);
    });
  }
}
