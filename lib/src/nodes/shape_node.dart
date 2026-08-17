import 'dart:ui';

import 'package:ignis/src/debug.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/sized_node.dart';
import 'package:ignis/src/palette.dart';
import 'package:ignis/src/shape.dart';

class ShapeNode extends SizedNode {
  /// Controls the geometry drawn.
  Shape shape;

  /// This node's registered paints.
  final Palette palette;

  /// The default paint.
  Paint get paint => palette.paint;

  @override
  Vector2 get size => shape.size;

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

    void painter(Canvas canvas, Paint paint) {
      final dest = shape.rect();

      switch (shape) {
        case Circle():
          canvas.drawOval(dest, paint);

        case Rectangle():
          canvas.drawRect(dest, paint);
      }
    }

    draw((canvas) {
      palette.draw(canvas, painter);
    });

    debugDraw((canvas) {
      canvas.drawRect(shape.rect(), DEBUG_TRANSFORM_PAINT);
    });
  }
}
