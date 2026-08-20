import 'dart:ui';

import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/palette.dart';
import 'package:ignis/src/shape.dart';

class ShapeNode extends SpatialNode {
  /// Controls the geometry drawn.
  @override
  Shape shape;

  /// This node's registered paints.
  final Palette palette;

  /// The default paint.
  Paint get paint => palette.paint;

  ShapeNode({
    required this.shape,
    Paint? paint,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : palette = Palette(paint: paint);

  @override
  void build() {
    super.build();

    draw((canvas) {
      palette.draw(canvas, shape.draw);
    });
  }
}
