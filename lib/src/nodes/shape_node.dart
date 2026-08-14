import 'dart:ui';

import 'package:ignis/src/debug.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/painted_node.dart';
import 'package:ignis/src/shape.dart';

class ShapeNode extends PaintedNode {
  /// Controls the geometry drawn.
  Shape shape;

  @override
  Vector2 get size => shape.size;

  ShapeNode({
    required this.shape,
    super.paint,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  });

  late Rect _dest;

  @override
  void render(Canvas canvas) {
    _dest = shape.rect();
    super.render(canvas);
  }

  @override
  void renderPainted(Canvas canvas, Paint paint) {
    switch (shape) {
      case Circle():
        canvas.drawOval(_dest, paint);

      case Rectangle():
        canvas.drawRect(_dest, paint);
    }
  }

  @override
  void debugRenderAnchored(Canvas canvas) {
    canvas.drawRect(shape.rect(), DEBUG_TRANSFORM_PAINT);
  }
}
